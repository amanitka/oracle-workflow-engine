CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_application_privilege IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 15.3.2018
  -- purpose: Application privilege
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_PERSONAL_PRIVILEGE
  -- purpose:        Store personal priv to temp table
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_personal_privilege;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_START_PROCESS
  -- purpose:       Check privilege to Manual start of process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_start_process(p_name_process IN VARCHAR2,
                             p_text_message OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_CANCEL_PROCESS
  -- purpose:       Check privilege to Cancel specified process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_cancel_process(p_id_process_instance IN INTEGER,
                              p_text_message        OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_SUSPEND_PROCESS
  -- purpose:       Check privilege to Suspend specified process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_suspend_process(p_id_process_instance IN INTEGER,
                               p_text_message        OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_RESUME_PROCESS
  -- purpose:       Check privilege to Resume specified process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_resume_process(p_id_process_instance IN INTEGER,
                              p_text_message        OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_RESTART_PROCESS
  -- purpose:       Check privilege to Restart specified process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_restart_process(p_id_process_instance IN INTEGER,
                               p_text_message        OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_SKIP_ACTIVITY
  -- purpose:       Check privilege to Skip activity for specified process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_skip_activity(p_id_process_instance IN INTEGER,
                             p_text_message        OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_KILL_ACTIVITY
  -- purpose:       Check privilege to Kill activity for specified process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_kill_activity(p_id_process_instance IN INTEGER,
                             p_text_message        OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_UNSTUCK_ACTIVITY
  -- purpose:       Check privilege to Unstuck activity for specified process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_unstuck_activity(p_id_process_instance IN INTEGER,
                                p_text_message        OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_ACTIVATE_START_GROUP
  -- purpose:       Check privilege to Activate process start group
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION can_activate_start_group(p_code_start_group IN VARCHAR2,
                                    p_text_message     OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_ACTIVATE_START_GROUP_ALL
  -- purpose:       Check privilege to Activate all process start groups for given category
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION can_activate_start_group_all(p_code_start_group_category IN VARCHAR2,
                                        p_text_message              OUT VARCHAR2) RETURN BOOLEAN;
                                        
  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_DEACTIVATE_START_GROUP
  -- purpose:       Check privilege to Deactivate all process start groups for given category
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION can_deactivate_start_group_all(p_code_start_group_category IN VARCHAR2,
                                          p_text_message              OUT VARCHAR2) RETURN BOOLEAN;
                                          
  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_DEACTIVATE_START_GROUP
  -- purpose:       Check privilege to Deactivate process start group
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION can_deactivate_start_group(p_code_start_group IN VARCHAR2,
                                      p_text_message     OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_CREATE_BG_PROCESS
  -- purpose:       Check privilege to Start background process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_create_bg_process(p_name_process_owner IN VARCHAR2,
                                 p_name_process       IN VARCHAR2,
                                 p_text_message       OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_DROP_BG_PROCESS
  -- purpose:       Check privilege to Drop background process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_drop_bg_process(p_name_process_owner IN VARCHAR2,
                               p_name_process       IN VARCHAR2,
                               p_text_message       OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_CREATE_BG_PROCESS_ALL
  -- purpose:       Check privilege to Create all background processes for given process category
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_create_bg_process_all(p_code_process_category IN VARCHAR2,
                                     p_text_message          OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_DROP_BG_PROCESS_ALL
  -- purpose:       Check privilege to Drop all background processes for given process category
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_drop_bg_process_all(p_code_process_category IN VARCHAR2,
                                   p_text_message          OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_START_REPORT_ROBOT
  -- purpose:       Check privilege to start of report robot
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_start_report_robot(p_name_report  IN VARCHAR2,
                                  p_text_message OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_RESTART_REPORT_ROBOT
  -- purpose:       Check privilege to restart of report robot
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_restart_report_robot(p_name_report  IN VARCHAR2,
                                    p_text_message OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_KILL_REPORT_ROBOT
  -- purpose:       Check privilege to kill of report robot
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_kill_report_robot(p_name_report  IN VARCHAR2,
                                 p_text_message OUT VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_MANUAL_CONFIRM_LOG
  -- purpose:       Check privilege to Manual confirmation of record in monitoring log -> set status = 'COMPLETE', flag_confirmed = 'Y'
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION can_manual_confirm_log(p_id           IN NUMBER,
                                  p_text_message OUT VARCHAR2) RETURN BOOLEAN;

END lib_etl_application_privilege;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_application_privilege IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_flag_Y                    CONSTANT VARCHAR2(1)  := 'Y';
  c_flag_N                    CONSTANT VARCHAR2(1)  := 'N';
  c_start_process_priv        CONSTANT VARCHAR2(30) := 'START_PROCESS';  
  c_cancel_process_priv       CONSTANT VARCHAR2(30) := 'CANCEL_PROCESS';  
  c_restart_process_priv      CONSTANT VARCHAR2(30) := 'RESTART_PROCESS';  
  c_suspend_process_priv      CONSTANT VARCHAR2(30) := 'SUSPEND_PROCESS';  
  c_resume_process_priv       CONSTANT VARCHAR2(30) := 'RESUME_PROCESS';  
  c_skip_activity_priv        CONSTANT VARCHAR2(30) := 'SKIP_ACTIVITY';
  c_kill_activity_priv        CONSTANT VARCHAR2(30) := 'KILL_ACTIVITY';
  c_unstuck_activity_priv     CONSTANT VARCHAR2(30) := 'UNSTUCK_ACTIVITY';
  c_create_bg_process_priv    CONSTANT VARCHAR2(30) := 'CREATE_BG_PROCESS';    
  c_drop_bg_process_priv      CONSTANT VARCHAR2(30) := 'DROP_BG_PROCESS';
  c_start_report_robot_priv   CONSTANT VARCHAR2(30) := 'START_REPORT_ROBOT';
  c_restart_report_robot_priv CONSTANT VARCHAR2(30) := 'RESTART_REPORT_ROBOT';
  c_kill_report_robot_priv    CONSTANT VARCHAR2(30) := 'KILL_REPORT_ROBOT';    
  c_confirm_err_log_priv      CONSTANT VARCHAR2(30) := 'CONFIRM_ERR_LOG';    
    
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_PERSONAL_PRIVILEGE
  -- purpose:        Store personal priv to temp table
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_personal_privilege
  IS
  
    v_cnt  INTEGER;
    
    CURSOR c_app_name_privilege IS
      WITH user_roles AS (SELECT 
                            DISTINCT
                             granted_role AS name_db_role
                          FROM (SELECT granted_role
                                FROM dba_role_privs
                                START WITH grantee = USER
                                CONNECT BY PRIOR granted_role = grantee)
                                )
      SELECT
         ap.code_responsible_group, 
         MAX(CASE WHEN ap.name_privilege = c_start_process_priv        THEN c_flag_Y ELSE c_flag_N END) AS flag_start_process,
         MAX(CASE WHEN ap.name_privilege = c_cancel_process_priv       THEN c_flag_Y ELSE c_flag_N END) AS flag_cancel_process,
         MAX(CASE WHEN ap.name_privilege = c_restart_process_priv      THEN c_flag_Y ELSE c_flag_N END) AS flag_restart_process,
         MAX(CASE WHEN ap.name_privilege = c_suspend_process_priv      THEN c_flag_Y ELSE c_flag_N END) AS flag_suspend_process,
         MAX(CASE WHEN ap.name_privilege = c_resume_process_priv       THEN c_flag_Y ELSE c_flag_N END) AS flag_resume_process,
         MAX(CASE WHEN ap.name_privilege = c_skip_activity_priv        THEN c_flag_Y ELSE c_flag_N END) AS flag_skip_activity,
         MAX(CASE WHEN ap.name_privilege = c_kill_activity_priv        THEN c_flag_Y ELSE c_flag_N END) AS flag_kill_activity,
         MAX(CASE WHEN ap.name_privilege = c_unstuck_activity_priv     THEN c_flag_Y ELSE c_flag_N END) AS flag_unstuck_activity,         
         MAX(CASE WHEN ap.name_privilege = c_create_bg_process_priv    THEN c_flag_Y ELSE c_flag_N END) AS flag_create_bg_process,
         MAX(CASE WHEN ap.name_privilege = c_drop_bg_process_priv      THEN c_flag_Y ELSE c_flag_N END) AS flag_drop_bg_process,
         MAX(CASE WHEN ap.name_privilege = c_start_report_robot_priv   THEN c_flag_Y ELSE c_flag_N END) AS flag_start_report_robot,
         MAX(CASE WHEN ap.name_privilege = c_restart_report_robot_priv THEN c_flag_Y ELSE c_flag_N END) AS flag_restart_report_robot,
         MAX(CASE WHEN ap.name_privilege = c_kill_report_robot_priv    THEN c_flag_Y ELSE c_flag_N END) AS flag_kill_report_robot,
         MAX(CASE WHEN ap.name_privilege = c_confirm_err_log_priv      THEN c_flag_Y ELSE c_flag_N END) AS flag_confirm_err_log
      FROM user_roles ur
      JOIN owner_wfm.etl_application_privilege ap ON ur.name_db_role = ap.name_db_role
      WHERE ap.flag_deleted = c_flag_N
      GROUP BY ap.code_responsible_group;
  
  BEGIN
  
    -- Check if table is empty 
    BEGIN
    
      SELECT 
         1
        INTO
         v_cnt
      FROM dual
      WHERE EXISTS (SELECT 1
                    FROM owner_wfm.tmp_personal_privilege);
    
    EXCEPTION
      WHEN no_data_found THEN
      
        -- Fill privilege into table
        FOR i IN c_app_name_privilege
        LOOP
        
          INSERT INTO owner_wfm.tmp_personal_privilege
            (code_responsible_group,
             flag_start_process,
             flag_cancel_process,
             flag_restart_process,
             flag_suspend_process,
             flag_resume_process,
             flag_skip_activity,
             flag_kill_activity,
             flag_unstuck_activity,
             flag_create_bg_process,
             flag_drop_bg_process,
             flag_start_report_robot,
             flag_restart_report_robot,
             flag_kill_report_robot,
             flag_confirm_err_log)
          VALUES
            (i.code_responsible_group,
             i.flag_start_process,
             i.flag_cancel_process,
             i.flag_restart_process,
             i.flag_suspend_process,
             i.flag_resume_process,
             i.flag_skip_activity,
             i.flag_kill_activity,
             i.flag_unstuck_activity,
             i.flag_create_bg_process,
             i.flag_drop_bg_process,
             i.flag_start_report_robot,
             i.flag_restart_report_robot,
             i.flag_kill_report_robot,
             i.flag_confirm_err_log);
        
        END LOOP;
      
        -- Commit;
        COMMIT;
      
    END;
  
  END set_personal_privilege;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_ACCESS_PROCESS
  -- purpose:       Common function for checking privileges for processes
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_access_process(p_name_privilege      IN VARCHAR2,
                              p_name_process        IN VARCHAR2 DEFAULT NULL,
                              p_id_process_instance IN INTEGER,
                              p_text_message        OUT VARCHAR2) RETURN BOOLEAN IS
                              
    v_name_process               VARCHAR2(30);
    v_flag_start_process_priv    VARCHAR2(1);
    v_flag_cancel_process_priv   VARCHAR2(1);
    v_flag_restart_process_priv  VARCHAR2(1);
    v_flag_suspend_process_priv  VARCHAR2(1);
    v_flag_resume_process_priv   VARCHAR2(1);
    v_flag_skip_activity_priv    VARCHAR2(1);
    v_flag_kill_activity_priv    VARCHAR2(1);
    v_flag_unstuck_activity_priv VARCHAR2(1);
        
  BEGIN
    
    -- Get access rights
    IF p_name_process IS NOT NULL THEN
      
      SELECT 
         MIN(name_process),
         MIN(flag_start_process_priv),
         MIN(flag_cancel_process_priv),
         MIN(flag_restart_process_priv),
         MIN(flag_suspend_process_priv),
         MIN(flag_resume_process_priv),
         MIN(flag_skip_activity_priv),
         MIN(flag_kill_activity_priv),
         MIN(flag_unstuck_activity_priv)
        INTO 
         v_name_process,
         v_flag_start_process_priv,
         v_flag_cancel_process_priv,
         v_flag_restart_process_priv,
         v_flag_suspend_process_priv,
         v_flag_resume_process_priv,
         v_flag_skip_activity_priv,
         v_flag_kill_activity_priv,
         v_flag_unstuck_activity_priv
      FROM owner_wfm.v_etl_process_status
      WHERE name_process = p_name_process;
      
    ELSE

      SELECT 
         MIN(name_process),
         MIN(flag_start_process_priv),
         MIN(flag_cancel_process_priv),
         MIN(flag_restart_process_priv),
         MIN(flag_suspend_process_priv),
         MIN(flag_resume_process_priv),
         MIN(flag_skip_activity_priv),
         MIN(flag_kill_activity_priv),
         MIN(flag_unstuck_activity_priv)
        INTO 
         v_name_process,
         v_flag_start_process_priv,
         v_flag_cancel_process_priv,
         v_flag_restart_process_priv,
         v_flag_suspend_process_priv,
         v_flag_resume_process_priv,
         v_flag_skip_activity_priv,
         v_flag_kill_activity_priv,
         v_flag_unstuck_activity_priv
      FROM owner_wfm.v_etl_process_status
      WHERE id_process_instance = p_id_process_instance;
    
    END IF;
    
    -- If user has access rights set empty message and return true 
    IF (v_flag_start_process_priv        = c_flag_y AND p_name_privilege = c_start_process_priv)
        OR (v_flag_cancel_process_priv   = c_flag_y AND p_name_privilege = c_cancel_process_priv)
        OR (v_flag_restart_process_priv  = c_flag_y AND p_name_privilege = c_restart_process_priv)
        OR (v_flag_suspend_process_priv  = c_flag_y AND p_name_privilege = c_suspend_process_priv)
        OR (v_flag_resume_process_priv   = c_flag_y AND p_name_privilege = c_resume_process_priv)
        OR (v_flag_skip_activity_priv    = c_flag_y AND p_name_privilege = c_skip_activity_priv)
        OR (v_flag_kill_activity_priv    = c_flag_y AND p_name_privilege = c_kill_activity_priv)
        OR (v_flag_unstuck_activity_priv = c_flag_y AND p_name_privilege = c_unstuck_activity_priv) THEN
        
      -- Set output message and result
      p_text_message := NULL;
      RETURN TRUE;

    -- Otherwise set result message and return false
    ELSE

      -- Set output message and result
      p_text_message := 'You don''t have privilege to '|| 
                          CASE WHEN p_name_privilege = c_start_process_priv    THEN 'start process'
                               WHEN p_name_privilege = c_cancel_process_priv   THEN 'cancel process'
                               WHEN p_name_privilege = c_restart_process_priv  THEN 'restart process'
                               WHEN p_name_privilege = c_suspend_process_priv  THEN 'suspend process'
                               WHEN p_name_privilege = c_resume_process_priv   THEN 'resume process'
                               WHEN p_name_privilege = c_skip_activity_priv    THEN 'skip activity of the process'
                               WHEN p_name_privilege = c_kill_activity_priv    THEN 'kill activity of the process'
                               WHEN p_name_privilege = c_unstuck_activity_priv THEN 'unstuck activity of the process'
                          END||' '||v_name_process;
      RETURN FALSE;

    END IF;
    
  END can_access_process;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_START_PROCESS
  -- purpose:       Check privilege to Manual start of process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_start_process(p_name_process IN VARCHAR2,
                             p_text_message OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_process(p_name_privilege      => c_start_process_priv,
                              p_name_process        => p_name_process,
                              p_id_process_instance => NULL,
                              p_text_message        => p_text_message); 
                                                 
  END can_start_process;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_CANCEL_PROCESS
  -- purpose:       Check privilege to Cancel specified process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_cancel_process(p_id_process_instance IN INTEGER,
                              p_text_message        OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_process(p_name_privilege      => c_cancel_process_priv,
                              p_id_process_instance => p_id_process_instance,
                              p_text_message        => p_text_message);
                              
  END can_cancel_process;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_SUSPEND_PROCESS
  -- purpose:        Check privilege to Suspend specified process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_suspend_process(p_id_process_instance IN INTEGER,
                               p_text_message        OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_process(p_name_privilege      => c_suspend_process_priv,
                              p_id_process_instance => p_id_process_instance,
                              p_text_message        => p_text_message);
                              
  END can_suspend_process;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_RESUME_PROCESS
  -- purpose:        Check privilege to Resume specified process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_resume_process(p_id_process_instance IN INTEGER,
                              p_text_message        OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_process(p_name_privilege      => c_resume_process_priv,
                              p_id_process_instance => p_id_process_instance,
                              p_text_message        => p_text_message);
                              
  END can_resume_process;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_RESTART_PROCESS
  -- purpose:       Check privilege to Restart specified process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_restart_process(p_id_process_instance IN INTEGER,
                               p_text_message        OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_process(p_name_privilege      => c_restart_process_priv,
                              p_id_process_instance => p_id_process_instance,
                              p_text_message        => p_text_message);
                              
  END can_restart_process;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_SKIP_ACTIVITY
  -- purpose:       Check privilege to Skip activity for specified process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_skip_activity(p_id_process_instance IN INTEGER,
                             p_text_message        OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_process(p_name_privilege      => c_skip_activity_priv,
                              p_id_process_instance => p_id_process_instance,
                              p_text_message        => p_text_message);
                              
  END can_skip_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_KILL_ACTIVITY
  -- purpose:       Check privilege to Kill activity for specified process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_kill_activity(p_id_process_instance IN INTEGER,
                             p_text_message        OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_process(p_name_privilege      => c_kill_activity_priv,
                              p_id_process_instance => p_id_process_instance,
                              p_text_message        => p_text_message);
                              
  END can_kill_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_UNSTUCK_ACTIVITY
  -- purpose:       Check privilege to Unstuck activity for specified process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_unstuck_activity(p_id_process_instance IN INTEGER,
                                p_text_message        OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_process(p_name_privilege      => c_unstuck_activity_priv,
                              p_id_process_instance => p_id_process_instance,
                              p_text_message        => p_text_message);
                              
  END can_unstuck_activity;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_ACCESS_START_GROUP
  -- purpose:       Common function for checking privileges for process start group
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION can_access_start_group(p_code_start_group_category IN VARCHAR2 DEFAULT NULL,
                                  p_code_start_group          IN VARCHAR2 DEFAULT NULL,
                                  p_text_message              OUT VARCHAR2) RETURN BOOLEAN IS
                                  
    v_flag_start_process_priv VARCHAR2(1);
    
  BEGIN
    
    -- Get access rights
    IF p_code_start_group_category IS NOT NULL THEN
     
      SELECT 
         MIN(flag_start_process_priv)
        INTO 
         v_flag_start_process_priv
      FROM owner_wfm.v_etl_process_start_group
      WHERE code_start_group_category = p_code_start_group_category;

    ELSE  
      
      SELECT 
         MIN(flag_start_process_priv)
        INTO 
         v_flag_start_process_priv
      FROM owner_wfm.v_etl_process_start_group
      WHERE code_start_group = p_code_start_group;        
    
    END IF;
    
    -- If user has access rights set empty message and return true   
    IF v_flag_start_process_priv = c_flag_y THEN
      
      -- Set output message and result
      p_text_message := NULL;
      RETURN TRUE;

    -- Otherwise set result message and return false
    ELSE

      -- Set output message and result
      p_text_message := 'You don''t have privilege to control start group '||
                            CASE WHEN p_code_start_group_category IS NOT NULL THEN 'category ' || p_code_start_group_category
                                 ELSE p_code_start_group
                            END;
 
      RETURN FALSE;

    END IF;
    
  END can_access_start_group;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_ACTIVATE_START_GROUP
  -- purpose:       Check privilege to Activate process start group
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION can_activate_start_group(p_code_start_group IN VARCHAR2,
                                    p_text_message     OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_start_group(p_code_start_group => p_code_start_group,
                                  p_text_message     => p_text_message);
                                  
  END can_activate_start_group;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_DEACTIVATE_START_GROUP
  -- purpose:       Check privilege to Deactivate process start group
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION can_deactivate_start_group(p_code_start_group IN VARCHAR2,
                                      p_text_message     OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_start_group(p_code_start_group => p_code_start_group,
                                  p_text_message     => p_text_message);
                                  
  END can_deactivate_start_group;
  
  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_ACTIVATE_START_GROUP_ALL
  -- purpose:       Check privilege to Activate all process start groups for given category
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION can_activate_start_group_all(p_code_start_group_category IN VARCHAR2,
                                        p_text_message              OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_start_group(p_code_start_group_category => p_code_start_group_category,
                                  p_text_message              => p_text_message);
                                  
  END can_activate_start_group_all;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_DEACTIVATE_START_GROUP
  -- purpose:       Check privilege to Deactivate all process start groups for given category
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION can_deactivate_start_group_all(p_code_start_group_category IN VARCHAR2,
                                          p_text_message              OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_start_group(p_code_start_group_category => p_code_start_group_category,
                                  p_text_message              => p_text_message);
                                  
  END can_deactivate_start_group_all;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_ACCESS_BG_PROCESS
  -- purpose:       Common function for checking privileges for background processes
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_access_bg_process(p_name_privilege        VARCHAR2,
                                 p_code_process_category IN VARCHAR2 DEFAULT NULL,
                                 p_name_process_owner    IN VARCHAR2 DEFAULT NULL,
                                 p_name_process          IN VARCHAR2 DEFAULT NULL,
                                 p_text_message          OUT VARCHAR2) RETURN BOOLEAN IS
                                 
    v_flag_create_bg_process_priv VARCHAR2(1);
    v_flag_drop_bg_process_priv   VARCHAR2(1);
    
  BEGIN

    -- Get access rights    
    IF p_code_process_category IS NOT NULL THEN
      
      SELECT 
         MIN(flag_create_bg_process_priv),
         MIN(flag_drop_bg_process_priv)
        INTO 
         v_flag_create_bg_process_priv,
         v_flag_drop_bg_process_priv
      FROM owner_wfm.v_etl_background_process
      WHERE code_process_category = p_code_process_category;
      
    ELSE
      
      SELECT 
         MIN(flag_create_bg_process_priv),
         MIN(flag_drop_bg_process_priv)
        INTO 
         v_flag_create_bg_process_priv,
         v_flag_drop_bg_process_priv
      FROM owner_wfm.v_etl_background_process
      WHERE name_process_owner = p_name_process_owner
        AND name_process = p_name_process;
      
    END IF;
       
    -- If user has access rights set empty message and return true   
    IF (v_flag_create_bg_process_priv = c_flag_y AND p_name_privilege = c_create_bg_process_priv)
       OR (v_flag_drop_bg_process_priv = c_flag_y AND p_name_privilege = c_drop_bg_process_priv) THEN
      
      -- Set output message and result
      p_text_message := NULL;
      RETURN TRUE;
    
    -- Otherwise set result message and return false  
    ELSE
      
      -- Set output message and result
      p_text_message := 'You don''t have privilege to '||
                          CASE WHEN p_name_privilege = c_create_bg_process_priv THEN 'create'
                               ELSE 'drop'
                          END||' background process '||
                            CASE WHEN p_code_process_category IS NOT NULL THEN 'category ' || p_code_process_category
                                 ELSE p_name_process
                            END;
      RETURN FALSE;

    END IF;
    
  END can_access_bg_process;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_CREATE_BG_PROCESS
  -- purpose:       Check privilege to Start background process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_create_bg_process(p_name_process_owner IN VARCHAR2,
                                 p_name_process       IN VARCHAR2,
                                 p_text_message       OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_bg_process(p_name_privilege     => c_create_bg_process_priv,
                                 p_name_process_owner => p_name_process_owner,
                                 p_name_process       => p_name_process,
                                 p_text_message       => p_text_message);
                                 
  END can_create_bg_process;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_DROP_BG_PROCESS
  -- purpose:       Check privilege to Drop background process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_drop_bg_process(p_name_process_owner IN VARCHAR2,
                               p_name_process       IN VARCHAR2,
                               p_text_message       OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_bg_process(p_name_privilege     => c_drop_bg_process_priv,
                                 p_name_process_owner => p_name_process_owner,
                                 p_name_process       => p_name_process,
                                 p_text_message       => p_text_message);
                                 
  END can_drop_bg_process;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_CREATE_BG_PROCESS_ALL
  -- purpose:       Check privilege to Create all background processes for given process category
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_create_bg_process_all(p_code_process_category IN VARCHAR2,
                                     p_text_message          OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_bg_process(p_name_privilege        => c_create_bg_process_priv,
                                 p_code_process_category => p_code_process_category,
                                 p_text_message          => p_text_message);
                                 
  END can_create_bg_process_all;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_DROP_BG_PROCESS_ALL
  -- purpose:       Check privilege to Drop all background processes for given process category
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_drop_bg_process_all(p_code_process_category IN VARCHAR2,
                                   p_text_message          OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_bg_process(p_name_privilege        => c_drop_bg_process_priv,
                                 p_code_process_category => p_code_process_category,
                                 p_text_message          => p_text_message);
                                 
  END can_drop_bg_process_all;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_ACCESS_REPORT_ROBOT
  -- purpose:       Common function for checking privileges for report robots
  ---------------------------------------------------------------------------------------------------------
  FUNCTION can_access_report_robot(p_name_privilege IN VARCHAR2,
                                   p_name_report    IN VARCHAR2,
                                   p_text_message   OUT VARCHAR2) RETURN BOOLEAN IS
                              
    v_flag_start_rr_priv   VARCHAR2(1);
    v_flag_restart_rr_priv VARCHAR2(1);
    v_flag_kill_rr_priv    VARCHAR2(1);

  BEGIN
    
    -- Get access rights
    SELECT 
       MIN(flag_start_report_robot_priv),
       MIN(flag_restart_report_robot_priv),
       MIN(flag_kill_report_robot_priv)
      INTO 
       v_flag_start_rr_priv,
       v_flag_restart_rr_priv,
       v_flag_kill_rr_priv
    FROM owner_wfm.v_etl_report_robot_status
    WHERE name_report = p_name_report;
    
    -- If user has access rights set empty message and return true 
    IF (v_flag_restart_rr_priv     = c_flag_y AND p_name_privilege = c_start_report_robot_priv)
        OR (v_flag_restart_rr_priv = c_flag_y AND p_name_privilege = c_restart_report_robot_priv)
        OR (v_flag_kill_rr_priv    = c_flag_y AND p_name_privilege = c_kill_report_robot_priv) THEN
        
      -- Set output message and result
      p_text_message := NULL;
      RETURN TRUE;

    -- Otherwise set result message and return false
    ELSE

      -- Set output message and result
      p_text_message := 'You don''t have privilege to '|| 
                          CASE WHEN p_name_privilege = c_start_report_robot_priv   THEN 'start report robot'
                               WHEN p_name_privilege = c_restart_report_robot_priv THEN 'restart report robot'
                               WHEN p_name_privilege = c_kill_report_robot_priv    THEN 'kill report robot'
                          END||' '||p_name_report;
      RETURN FALSE;

    END IF;
    
  END can_access_report_robot;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_START_REPORT_ROBOT
  -- purpose:       Check privilege to start of report robot
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_start_report_robot(p_name_report  IN VARCHAR2,
                                  p_text_message OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_report_robot(p_name_privilege => c_start_report_robot_priv,
                                   p_name_report    => p_name_report,
                                   p_text_message   => p_text_message);
                                                 
  END can_start_report_robot;
  
  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_RESTART_REPORT_ROBOT
  -- purpose:       Check privilege to restart of report robot
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_restart_report_robot(p_name_report  IN VARCHAR2,
                                    p_text_message OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_report_robot(p_name_privilege => c_restart_report_robot_priv,
                                   p_name_report    => p_name_report,
                                   p_text_message   => p_text_message);
                                                 
  END can_restart_report_robot;
  
  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_KILL_REPORT_ROBOT
  -- purpose:       Check privilege to kill of report robot
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION can_kill_report_robot(p_name_report  IN VARCHAR2,
                                 p_text_message OUT VARCHAR2) RETURN BOOLEAN IS
  
  BEGIN
    
    RETURN can_access_report_robot(p_name_privilege => c_kill_report_robot_priv,
                                   p_name_report    => p_name_report,
                                   p_text_message   => p_text_message);
                                                 
  END can_kill_report_robot;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CAN_MANUAL_CONFIRM_LOG
  -- purpose:       Check privilege to Manual confirmation of record in monitoring log -> set status = 'COMPLETE', flag_confirmed = 'Y'
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION can_manual_confirm_log(p_id           IN NUMBER,
                                  p_text_message OUT VARCHAR2) RETURN BOOLEAN IS
                                  
    v_flag_confirm_err_log_priv VARCHAR2(1);
    
  BEGIN

    -- Get access rights      
    SELECT 
       MIN(flag_confirm_err_log_priv)
      INTO 
       v_flag_confirm_err_log_priv
    FROM owner_wfm.v_etl_monitoring_log
    WHERE id = p_id;

    -- If user has access rights set empty message and return true     
    IF v_flag_confirm_err_log_priv = c_flag_y THEN
      
      -- Set output message and result
      p_text_message := NULL;
      RETURN TRUE;

    -- Otherwise set result message and return false        
    ELSE
        
      -- Set output message and result
      p_text_message := 'You don''t have privilege to confirm record with ID = ' || p_id;
      RETURN FALSE;

    END IF;
    
  END can_manual_confirm_log;

BEGIN
  
  -- Set personal privilege during initialization
  set_personal_privilege;
  
END lib_etl_application_privilege;
/
