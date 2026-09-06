CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_bg_process_run IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_JOB_NAME
  -- purpose:       Return job name for std jobs
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_job_name(p_name_process_owner IN VARCHAR2,
                        p_name_process       IN VARCHAR2) RETURN VARCHAR2;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_BG_PROCESS_GROUP
  -- purpose:       Return background process_group
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_bg_process_group(p_name_process_owner IN VARCHAR2,
                                p_name_process       IN VARCHAR2) RETURN VARCHAR2;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: activate_bg_process
  -- purpose:        Activate background process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE activate_bg_process(p_name_process_owner IN VARCHAR2,
                                p_name_process       IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: deactivate_bg_process
  -- purpose:        Activate background process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE deactivate_bg_process(p_name_process_owner IN VARCHAR2,
                                  p_name_process       IN VARCHAR2);
                               
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CREATE_BG_PROCESS
  -- purpose:        Create background process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE create_bg_process;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DROP_BG_PROCESS
  -- purpose:        Drop background process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE drop_bg_process(p_name_process_owner IN VARCHAR2,
                            p_name_process       IN VARCHAR2,
                            p_text_message       OUT VARCHAR2);

END lib_etl_bg_process_run;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_bg_process_run IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_flag_Y              CONSTANT VARCHAR2(1)  := 'Y';
  c_flag_N              CONSTANT VARCHAR2(1)  := 'N';
  c_def_job_class       CONSTANT VARCHAR2(20) := 'DEFAULT_JOB_CLASS';
  c_job_prefix          CONSTANT VARCHAR2(50) := 'JOB_';

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_JOB_NAME
  -- purpose:       Return job name for std jobs 
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_job_name(p_name_process_owner IN VARCHAR2,
                        p_name_process       IN VARCHAR2) RETURN VARCHAR2 IS
    
    v_name_job VARCHAR2(255);
    
  BEGIN
    
    -- Set job name
    v_name_job := p_name_process_owner||'.'||c_job_prefix||p_name_process;

    -- Return result
    RETURN v_name_job;
    
  END get_job_name;
  
  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_BG_PROCESS_GROUP
  -- purpose:       Return background process_group
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_bg_process_group(p_name_process_owner IN VARCHAR2,
                                p_name_process       IN VARCHAR2) RETURN VARCHAR2 IS
    
    v_code_process_group VARCHAR2(30);
    
  BEGIN
    
    -- Get background process group
    SELECT
       code_process_group
      INTO
       v_code_process_group 
    FROM owner_wfm.etl_background_process
    WHERE name_process_owner = p_name_process_owner 
      AND name_process = p_name_process;

    -- Return result
    RETURN v_code_process_group;
    
  END get_bg_process_group;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CHECK_JOB_STATUS
  -- purpose:       Check job status
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_job_status(p_name_job     IN VARCHAR2,
                             p_flag_active  OUT VARCHAR2,
                             p_flag_running OUT VARCHAR2)
  IS
  
  BEGIN
    
    -- Check job status
    SELECT 
       c_flag_Y                                                    AS flag_active,
       CASE WHEN state = 'RUNNING' THEN c_flag_Y ELSE c_flag_N END AS flag_running 
      INTO
       p_flag_active,
       p_flag_running
    FROM dba_scheduler_jobs
    WHERE owner||'.'||job_name = p_name_job;
    
  EXCEPTION 
    WHEN no_data_found THEN
      -- Set default result whewn no data found
      p_flag_active  := c_flag_N;
      p_flag_running := c_flag_N;
    
  END check_job_status;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DROP_JOB
  -- purpose:        Drop job
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE drop_job(p_name_job IN VARCHAR2)
  IS

  BEGIN
    
    -- Drop job
    sys.dbms_scheduler.drop_job(job_name => p_name_job);    
 
  END drop_job;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CREATE_JOB
  -- purpose:        Create job
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE create_job(p_name_job             IN VARCHAR2,                         
                       p_text_action          IN VARCHAR2,
                       p_text_repeat_interval IN VARCHAR2, 
                       p_name_job_class       IN VARCHAR2)
  IS

  BEGIN

     -- Create job
     dbms_scheduler.create_job(job_name             => p_name_job,
                               job_type             => 'PLSQL_BLOCK',
                               job_action           => p_text_action,
                               start_date           => SYSTIMESTAMP + INTERVAL '10' SECOND,
                               repeat_interval      => p_text_repeat_interval,
                               end_date             => NULL,
                               enabled              => TRUE,
                               job_class            => p_name_job_class,
                               comments             => NULL);

  END create_job;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: activate_bg_process
  -- purpose:        Activate background process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE activate_bg_process(p_name_process_owner IN VARCHAR2,
                                p_name_process       IN VARCHAR2)
  IS

  BEGIN
    
    -- Mark background process as active
    UPDATE owner_wfm.etl_background_process 
       SET flag_active = c_flag_Y 
    WHERE name_process_owner = p_name_process_owner 
      AND name_process = p_name_process;
    COMMIT;  
      
  END activate_bg_process; 
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: deactivate_bg_process
  -- purpose:        Activate background process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE deactivate_bg_process(p_name_process_owner IN VARCHAR2,
                                  p_name_process       IN VARCHAR2)
  IS

  BEGIN
    
    -- Mark background process as inactive
    UPDATE owner_wfm.etl_background_process 
       SET flag_active = c_flag_N 
    WHERE name_process_owner = p_name_process_owner 
      AND name_process = p_name_process;
    COMMIT;  
      
  END deactivate_bg_process; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CREATE_BG_PROCESS
  -- purpose:        Create background process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE create_bg_process
  IS
  
    v_name_job      VARCHAR2(70);
    v_text_action   VARCHAR2(500);
    v_flag_active   VARCHAR2(1);
    v_flag_running  VARCHAR2(1);
              
    CURSOR c_background_process IS
      SELECT
         bp.name_process_owner                    AS name_process_owner,
         bp.name_process                          AS name_process,
         bpg.text_action                          AS text_action,
         bp.text_parameter_value                  AS text_parameter_value,
         bp.text_repeat_interval                  AS text_repeat_interval,
         NVL(bpg.name_job_class, c_def_job_class) AS name_job_class
      FROM owner_wfm.etl_background_process bp
      JOIN owner_wfm.etl_background_process_group bpg ON bp.code_process_group = bpg.code_process_group
      LEFT JOIN dba_scheduler_jobs schj ON schj.owner = bp.name_process_owner
                                       AND schj.job_name = 'JOB_'||bp.name_process 
      WHERE bp.flag_active = c_flag_Y
        AND schj.job_name IS NULL;

  BEGIN
    
    FOR i IN c_background_process
    LOOP 
      
      -- Get job name
      v_name_job := get_job_name(p_name_process_owner => i.name_process_owner,
                                 p_name_process       => i.name_process);

      -- Prepare text action
      v_text_action := 'BEGIN'||CHR(10)||'  '||REPLACE(i.text_action, '#PARAMETER_VALUE#', i.text_parameter_value)||';'||CHR(10)||'END;';

      -- Check job status
      check_job_status(p_name_job     => v_name_job,
                       p_flag_active  => v_flag_active,
                       p_flag_running => v_flag_running);
                       
      -- If job doesnt exists then create it
      IF v_flag_active = c_flag_n THEN
      
        -- Create job
        create_job(p_name_job             => v_name_job,                         
                   p_text_action          => v_text_action,
                   p_text_repeat_interval => i.text_repeat_interval, 
                   p_name_job_class       => i.name_job_class);
 
      END IF;

    END LOOP;
      
  END create_bg_process;
    
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DROP_BG_PROCESS
  -- purpose:        Drop background process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE drop_bg_process(p_name_process_owner IN VARCHAR2,
                            p_name_process       IN VARCHAR2,
                            p_text_message       OUT VARCHAR2)
  IS
  
    v_name_job     VARCHAR2(70);
    v_flag_active  VARCHAR2(1);
    v_flag_running VARCHAR2(1);
          
    CURSOR c_background_process IS
      SELECT
         bp.rowid                                 AS id_rec,    
         bp.flag_active                           AS flag_active
      FROM owner_wfm.etl_background_process bp
      WHERE bp.name_process_owner = p_name_process_owner 
        AND bp.name_process = p_name_process;

  BEGIN
    
    FOR i IN c_background_process
    LOOP 
      
      -- Get job name
      v_name_job := get_job_name(p_name_process_owner => p_name_process_owner,
                                 p_name_process       => p_name_process);

      -- Check job status
      check_job_status(p_name_job     => v_name_job,
                       p_flag_active  => v_flag_active,
                       p_flag_running => v_flag_running);
                       
      -- If job exists and its not running then drop it
      IF v_flag_active = c_flag_y AND v_flag_running = c_flag_N THEN
      
        -- Drop job
        drop_job(p_name_job => v_name_job);      
        
        -- Mark job as inactive
        deactivate_bg_process(p_name_process_owner => p_name_process_owner,
                              p_name_process       => p_name_process);
        
        -- Set result
        p_text_message := 'Background process is now inactive.';
 
      ELSE
        
        -- Set result
        IF v_flag_running = c_flag_Y THEN
          p_text_message := 'Background process is still running and cannot be deactivated!';
        ELSE
          p_text_message := 'Background process is not active, there is nothing to do!';
        END IF;

      END IF;     

    END LOOP;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Set result
      p_text_message := 'Deactivation of background process failed! Error message: '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
      
  END drop_bg_process;
     
END lib_etl_bg_process_run;
/
