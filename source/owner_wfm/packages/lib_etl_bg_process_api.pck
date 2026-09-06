CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_bg_process_api IS

  ---------------------------------------------------------------------------------------------------------
  -- author: Ludek
  ---------------------------------------------------------------------------------------------------------
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_BG_PROCESS
  -- purpose:        Start background process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE create_bg_process(p_name_process_owner IN VARCHAR2,
                              p_name_process       IN VARCHAR2,
                              p_text_message       OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CREATE_BG_PROCESS_ALL
  -- purpose:        Create all background processes for given process category
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE create_bg_process_all(p_code_process_category IN VARCHAR2,
                                  p_text_message          OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DROP_BG_PROCESS
  -- purpose:        Drop background process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE drop_bg_process(p_name_process_owner IN VARCHAR2,
                            p_name_process       IN VARCHAR2,
                            p_text_message       OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DROP_BG_PROCESS_ALL
  -- purpose:        Drop all background processes for given process category
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE drop_bg_process_all(p_code_process_category IN VARCHAR2,
                                p_text_message          OUT VARCHAR2);

END lib_etl_bg_process_api;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_bg_process_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name               CONSTANT VARCHAR2(30) := 'LIB_ETL_BG_PROCESS_API';
  c_bg_process_creator     CONSTANT VARCHAR2(60) := 'OWNER_WFM.JOB_BG_PROCESS_CREATOR';
  c_flag_Y                 CONSTANT VARCHAR2(1)  := 'Y';
  c_flag_N                 CONSTANT VARCHAR2(1)  := 'N';
    
  ---------------------------------------------------------------------------------------------------------
  -- function name: CHECK_BG_PROCESS_STATUS
  -- purpose:       Find out status of background process   
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_bg_process_status(p_name_process_owner IN VARCHAR2,
                                    p_name_process       IN VARCHAR2,
                                    p_flag_active        OUT VARCHAR2)
  IS
    
  BEGIN
    
    -- Find out status of background process
    SELECT
       CASE WHEN schj.job_name IS NOT NULL THEN c_flag_Y ELSE c_flag_N END
      INTO
       p_flag_active 
    FROM owner_wfm.etl_background_process bp
    LEFT JOIN dba_scheduler_jobs schj ON schj.owner = bp.name_process_owner
                                     AND schj.job_name = 'JOB_'||bp.name_process 
    WHERE bp.name_process_owner = p_name_process_owner
      AND bp.name_process = p_name_process;
    
  END check_bg_process_status;
  
  ---------------------------------------------------------------------------------------------------------
  -- function name: CHECK_BG_PROCESS_CAT_STATUS
  -- purpose:          
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_bg_process_cat_status(p_code_process_category IN VARCHAR2,
                                        p_cnt_total             OUT INTEGER,
                                        p_cnt_active            OUT INTEGER)
  IS

  BEGIN
    
    -- Find out status of background process category
    SELECT
       COUNT(1)                                                   AS cnt_total,
       SUM(CASE WHEN schj.job_name IS NOT NULL THEN 1 ELSE 0 END) AS cnt_active
      INTO
       p_cnt_total,
       p_cnt_active 
    FROM owner_wfm.etl_background_process bp
    LEFT JOIN dba_scheduler_jobs schj ON schj.owner = bp.name_process_owner
                                     AND schj.job_name = 'JOB_'||bp.name_process 
    WHERE bp.code_process_category = p_code_process_category;
    
  END check_bg_process_cat_status;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CREATE_BG_PROCESS
  -- purpose:        Create background process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE create_bg_process(p_name_process_owner IN VARCHAR2,
                              p_name_process       IN VARCHAR2,
                              p_text_message       OUT VARCHAR2) IS
  
    v_flag_active VARCHAR2(1);
  
  BEGIN
      
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_create_bg_process(p_name_process_owner, p_name_process, p_text_message)
    THEN
      RETURN;
    END IF;
    
    -- Active background process
    owner_wfm.lib_etl_bg_process_run.activate_bg_process(p_name_process_owner => p_name_process_owner,
                                                         p_name_process       => p_name_process);
                                                         
    -- Run background job creator
    dbms_scheduler.run_job(job_name            => c_bg_process_creator,
                           use_current_session => FALSE);
  
    -- Wait for 6 sec
    sys.dbms_lock.sleep(6);
  
    -- Check background process status
    check_bg_process_status(p_name_process_owner => p_name_process_owner,
                            p_name_process       => p_name_process,
                            p_flag_active        => v_flag_active);
  
    -- Set result
    IF v_flag_active = c_flag_y
    THEN
      p_text_message := 'Background process is now active.';
    ELSE
      p_text_message := 'Background process could not be activated!!!';
    END IF;
  
  END create_bg_process;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CREATE_BG_PROCESS_ALL
  -- purpose:        Create all background processes for given process category
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE create_bg_process_all(p_code_process_category IN VARCHAR2,
                                  p_text_message          OUT VARCHAR2) IS
  
    CURSOR c_background_process IS
      SELECT 
         name_process_owner,
         name_process
      FROM owner_wfm.etl_background_process
      WHERE code_process_category = p_code_process_category;
  
    v_cnt_total   INTEGER;
    v_cnt_active  INTEGER;
  
  BEGIN
    
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_create_bg_process_all(p_code_process_category, p_text_message)
    THEN
      RETURN;
    END IF;
  
    FOR i IN c_background_process
    LOOP
    
      -- Active background process
      owner_wfm.lib_etl_bg_process_run.activate_bg_process(p_name_process_owner => i.name_process_owner,
                                                           p_name_process       => i.name_process);
    
    END LOOP;
    
    -- Run background job creator
    dbms_scheduler.run_job(job_name            => c_bg_process_creator,
                           use_current_session => FALSE);
  
    -- Wait for 10 sec
    sys.dbms_lock.sleep(10);
  
    -- Check background process category status
    check_bg_process_cat_status(p_code_process_category => p_code_process_category,
                                p_cnt_total             => v_cnt_total,
                                p_cnt_active            => v_cnt_active);
  
    -- Set result
    p_text_message := v_cnt_active || ' out of ' || v_cnt_total || ' background processes are now active.';
  
  END create_bg_process_all;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DROP_BG_PROCESS
  -- purpose:        Drop background process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE drop_bg_process(p_name_process_owner IN VARCHAR2,
                            p_name_process       IN VARCHAR2,
                            p_text_message       OUT VARCHAR2) IS
    
  BEGIN
    
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_drop_bg_process(p_name_process_owner, p_name_process, p_text_message)
    THEN
      RETURN;
    END IF;
  
    -- Drop background process
    owner_wfm.lib_etl_bg_process_run.drop_bg_process(p_name_process_owner => p_name_process_owner,
                                                     p_name_process       => p_name_process,
                                                     p_text_message       => p_text_message);
  
  END drop_bg_process;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DROP_BG_PROCESS_ALL
  -- purpose:        Drop all background processes for given process category
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE drop_bg_process_all(p_code_process_category IN VARCHAR2,
                                p_text_message          OUT VARCHAR2) IS
  
    v_cnt_total    INTEGER;
    v_cnt_active   INTEGER;
  
    CURSOR c_background_process IS
      SELECT 
         name_process_owner,
         name_process
      FROM owner_wfm.etl_background_process
      WHERE code_process_category = p_code_process_category;
  
  BEGIN
    
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_drop_bg_process_all(p_code_process_category, p_text_message)
    THEN
      RETURN;
    END IF;
  
    FOR i IN c_background_process
    LOOP
    
      -- Drop background process
      owner_wfm.lib_etl_bg_process_run.drop_bg_process(p_name_process_owner => i.name_process_owner,
                                                       p_name_process       => i.name_process,
                                                       p_text_message       => p_text_message);
    
    END LOOP;
  
    -- Check background process category status
    check_bg_process_cat_status(p_code_process_category => p_code_process_category,
                                p_cnt_total             => v_cnt_total,
                                p_cnt_active            => v_cnt_active);
  
    -- Set result
    p_text_message := v_cnt_total - v_cnt_active || ' out of ' || v_cnt_total || ' background processes are now inactive.';
  
  END drop_bg_process_all;
  
END lib_etl_bg_process_api;
/
