CREATE OR REPLACE PACKAGE owner_wfm.lib_report_robot_run_api
AS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek Pokorny
  -- created: 05.07.2019
  -- purpose: Package to operate robot report
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- purpose: Get sql text and plan for running report robot
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE get_running_report_sql(p_name_report   IN VARCHAR2,
                                   p_text_sql      OUT CLOB,
                                   p_text_sql_plan OUT CLOB,
                                   p_text_message  OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_RUNNING_REPORT_SQL_AI
  -- purpose:        Get sql additional information for running report
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE get_running_report_sql_ai(p_name_report  IN VARCHAR2,
                                      p_id_instance  OUT NUMBER,
                                      p_id_sql       OUT VARCHAR2,
                                      p_text_message OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- purpose: Set report robot parameters
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_report_parameter(p_name_report         IN VARCHAR2,
                                 p_name_object_owner   IN VARCHAR2 DEFAULT NULL,
                                 p_name_object         IN VARCHAR2 DEFAULT NULL,
                                 p_num_severity        IN NUMBER DEFAULT NULL,
                                 p_num_runtime_sla     IN INTEGER DEFAULT NULL,
                                 p_dtime_start_sla     IN DATE DEFAULT NULL,
                                 p_flag_multiple_run   IN VARCHAR2 DEFAULT NULL,
                                 p_text_business_owner IN VARCHAR2 DEFAULT NULL,
                                 p_flag_monitoring     IN VARCHAR2 DEFAULT NULL,
                                 p_flag_deleted        IN VARCHAR2 DEFAULT NULL,
                                 p_text_message        OUT VARCHAR2);
                                    
  ---------------------------------------------------------------------------------------------------------
  -- purpose: Set report robot condition
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_condition(p_name_report     IN VARCHAR2,
                          p_num_order       IN INTEGER DEFAULT NULL,
                          p_text_condition  IN VARCHAR2 DEFAULT NULL,
                          p_code_check_type IN VARCHAR2 DEFAULT NULL,
                          p_flag_deleted    IN VARCHAR2 DEFAULT NULL,
                          p_text_message    OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- purpose: Start report robot
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_report(p_name_report  IN VARCHAR2,
                         p_text_message OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- purpose: Restart report robot
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE restart_report(p_name_report  IN VARCHAR2,
                           p_text_message OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- purpose: Kill report robot
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE kill_report(p_name_report  IN VARCHAR2,
                        p_text_message OUT VARCHAR2);

END lib_report_robot_run_api;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_report_robot_run_api
AS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name         CONSTANT VARCHAR2(30) := 'LIB_REPORT_ROBOT_RUN_API'; 
  c_status_error     CONSTANT VARCHAR2(10) := 'ERROR';
  c_log_type_message CONSTANT VARCHAR2(10) := 'MESSAGE';  
  c_log_type_warning CONSTANT VARCHAR2(10) := 'WARNING';  

      
  ---------------------------------------------------------------------------------------------------------
  -- purpose: Get information aabout running report robot
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_running_report_info(p_name_report IN VARCHAR2,
                                    p_id_instance OUT NUMBER,
                                    p_id_session  OUT NUMBER,
                                    p_id_serial   OUT NUMBER)
  IS
  
    v_name_report_job  VARCHAR2(70);
                            
  BEGIN
    
    -- Get report robot job name
    v_name_report_job := owner_core.lib_report_robot_run.get_report_job_name(p_name_report => p_name_report);
    
    -- Get information from running report robot job
    BEGIN
      
      SELECT
         ses.inst_id AS id_instance,
         ses.sid     AS id_session,
         ses.serial# AS id_serial
        INTO
         p_id_instance,
         p_id_session,
         p_id_serial
      FROM sys.dba_scheduler_running_jobs rj
      JOIN sys.gv_$session ses ON ses.inst_id = rj.running_instance
                              AND ses.sid = rj.session_id
      WHERE rj.owner = SUBSTR(v_name_report_job, 1, INSTR(v_name_report_job, '.', 1) - 1)
        AND rj.job_name = SUBSTR(v_name_report_job, INSTR(v_name_report_job, '.', 1) + 1);
        
    EXCEPTION 
      WHEN no_data_found THEN
        -- Set result to NULL
        p_id_instance          := NULL;
        p_id_session           := NULL;
        p_id_serial            := NULL;
        
    END;
  
  END get_running_report_info; 

  ---------------------------------------------------------------------------------------------------------
  -- purpose: Get sql text and plan for running report robot
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE get_running_report_sql(p_name_report   IN VARCHAR2,
                                   p_text_sql      OUT CLOB,
                                   p_text_sql_plan OUT CLOB,
                                   p_text_message  OUT VARCHAR2)
  IS
  
    c_proc_name            VARCHAR2(30) := 'GET_RUNNING_REPORT_SQL';
    v_step                 VARCHAR2(500); 
    v_id_instance          NUMBER;
    v_id_session           NUMBER;
    v_id_serial            NUMBER;
    
  BEGIN
      
    -- Get session information about running report robot
    v_step := 'Get session information about running report';
    get_running_report_info(p_name_report => p_name_report,
                            p_id_instance => v_id_instance,
                            p_id_session  => v_id_session,
                            p_id_serial   => v_id_serial);
    
   
    -- If session information was successfully retrieved
    IF v_id_instance IS NOT NULL 
        AND v_id_session IS NOT NULL 
        AND v_id_serial IS NOT NULL THEN
      
      -- Get sql information for running report robot
      v_step := 'Get sql information for running report robot';
      owner_wfm.lib_etl_support_util.get_sql_info(p_id_instance   => v_id_instance,
                                                  p_id_session    => v_id_session,
                                                  p_id_serial     => v_id_serial,
                                                  p_text_sql      => p_text_sql,
                                                  p_text_sql_plan => p_text_sql_plan);
    
    -- Otherwise ...                     
    ELSE
    
      -- Set message
      p_text_message := 'Requested data cannot be provided, because it was not possible to retrieve session information!';
    
    END IF;   
    
  EXCEPTION
    WHEN OTHERS THEN  
      -- Rollback
      ROLLBACK;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(SQLERRM, 1, 1000);
                                                    
  END get_running_report_sql; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_RUNNING_REPORT_SQL_AI
  -- purpose:        Get sql additional information for running report
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE get_running_report_sql_ai(p_name_report  IN VARCHAR2,
                                      p_id_instance  OUT NUMBER,
                                      p_id_sql       OUT VARCHAR2,
                                      p_text_message OUT VARCHAR2)
  IS
  
    c_proc_name            VARCHAR2(30) := 'GET_RUNNING_REPORT_SQL_AI';
    v_step                 VARCHAR2(500); 
    v_id_instance          NUMBER;
    v_id_session           NUMBER;
    v_id_serial            NUMBER;
    
  BEGIN
      
    -- Get session information about running report robot
    v_step := 'Get session information about running report';
    get_running_report_info(p_name_report => p_name_report,
                            p_id_instance => v_id_instance,
                            p_id_session  => v_id_session,
                            p_id_serial   => v_id_serial);
    
   
    -- If session information was successfully retrieved
    IF v_id_instance IS NOT NULL 
        AND v_id_session IS NOT NULL 
        AND v_id_serial IS NOT NULL THEN
        
      -- Set instance id
      p_id_instance := v_id_instance;
      
      -- Get sql id
      BEGIN
        
        SELECT
           sql_id
          INTO
           p_id_sql     
        FROM sys.gv_$session
        WHERE inst_id = v_id_instance
          AND sid = v_id_session
          AND serial# = v_id_serial
          AND rownum = 1;
      
      EXCEPTION 
        WHEN OTHERS THEN
          -- Set additional result to NULL
          p_id_sql      := NULL;
          p_id_instance := NULL;
      
      END;
    
    -- Otherwise ...                     
    ELSE
    
      -- Set message
      p_text_message := 'Requested data cannot be provided, because it was not possible to retrieve session information!';
    
    END IF;   
    
  EXCEPTION
    WHEN OTHERS THEN  
      -- Rollback
      ROLLBACK;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
                                                    
  END get_running_report_sql_ai; 
 
  ---------------------------------------------------------------------------------------------------------
  -- purpose: Set report robot parameters
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_report_parameter(p_name_report         IN VARCHAR2,
                                 p_name_object_owner   IN VARCHAR2 DEFAULT NULL,
                                 p_name_object         IN VARCHAR2 DEFAULT NULL,
                                 p_num_severity        IN NUMBER DEFAULT NULL,
                                 p_num_runtime_sla     IN INTEGER DEFAULT NULL,
                                 p_dtime_start_sla     IN DATE DEFAULT NULL,
                                 p_flag_multiple_run   IN VARCHAR2 DEFAULT NULL,
                                 p_text_business_owner IN VARCHAR2 DEFAULT NULL,
                                 p_flag_monitoring     IN VARCHAR2 DEFAULT NULL,
                                 p_flag_deleted        IN VARCHAR2 DEFAULT NULL,
                                 p_text_message        OUT VARCHAR2)
  IS

  BEGIN

    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_start_report_robot(p_name_report, p_text_message) THEN
      p_text_message := 'You don''t have privilege to set parameter for report robot '||p_name_report;
      RETURN;
    END IF;
    
    -- Set report robot parameters
    owner_core.lib_report_robot.set_report_parameter(p_name_report         => p_name_report,
                                                     p_name_object_owner   => p_name_object_owner,
                                                     p_name_object         => p_name_object,
                                                     p_num_severity        => p_num_severity,
                                                     p_num_runtime_sla     => p_num_runtime_sla,
                                                     p_dtime_start_sla     => p_dtime_start_sla,
                                                     p_flag_multiple_run   => p_flag_multiple_run,
                                                     p_text_business_owner => p_text_business_owner,
                                                     p_flag_monitoring     => p_flag_monitoring,
                                                     p_flag_deleted        => p_flag_deleted);
           
  END set_report_parameter;
                                    
  ---------------------------------------------------------------------------------------------------------
  -- purpose: Set report robot condition
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_condition(p_name_report     IN VARCHAR2,
                          p_num_order       IN INTEGER DEFAULT NULL,
                          p_text_condition  IN VARCHAR2 DEFAULT NULL,
                          p_code_check_type IN VARCHAR2 DEFAULT NULL,
                          p_flag_deleted    IN VARCHAR2 DEFAULT NULL,
                          p_text_message    OUT VARCHAR2)
  IS

  BEGIN

    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_start_report_robot(p_name_report, p_text_message) THEN
      p_text_message := 'You don''t have privilege to set condition for report robot '||p_name_report;
      RETURN;
    END IF;
    
    -- Set report robot condition
    owner_core.lib_report_robot.set_condition(p_name_report     => p_name_report,
                                              p_num_order       => p_num_order,
                                              p_text_condition  => p_text_condition,
                                              p_code_check_type => p_code_check_type,
                                              p_flag_deleted    => p_flag_deleted);
           
  END set_condition;

  ---------------------------------------------------------------------------------------------------------
  -- purpose: Start report robot
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_report(p_name_report  IN VARCHAR2,
                         p_text_message OUT VARCHAR2)
  IS

    c_proc_name VARCHAR2(30) := 'START_REPORT';
           
  BEGIN

    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_start_report_robot(p_name_report, p_text_message) THEN
      RETURN;
    END IF;
    
    -- Start report robot
    owner_core.lib_report_robot_run.start_report(p_name_report  => p_name_report,
                                                 p_text_message => p_text_message);

  EXCEPTION
    WHEN OTHERS THEN  
      -- Rollback
      ROLLBACK;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||': '||SUBSTR(SQLERRM, 1, 1000);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_warning, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => p_text_message);
           
  END start_report;

  ---------------------------------------------------------------------------------------------------------
  -- purpose: Restart report robot
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE restart_report(p_name_report  IN VARCHAR2,
                           p_text_message OUT VARCHAR2)
  IS

    c_proc_name VARCHAR2(30) := 'RESTART_REPORT';
           
  BEGIN
 
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_restart_report_robot(p_name_report, p_text_message) THEN
      RETURN;
    END IF;
   
    -- Restart report robot
    owner_core.lib_report_robot_run.restart_report(p_name_report  => p_name_report,
                                                   p_text_message => p_text_message);
           
  EXCEPTION
    WHEN OTHERS THEN  
      -- Rollback
      ROLLBACK;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||': '||SUBSTR(SQLERRM, 1, 1000);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_warning, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => p_text_message);

  END restart_report;

  ---------------------------------------------------------------------------------------------------------
  -- purpose: Kill report robot
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE kill_report(p_name_report  IN VARCHAR2,
                        p_text_message OUT VARCHAR2)
  IS
  
    c_proc_name            VARCHAR2(30) := 'KILL_REPORT';
    v_step                 VARCHAR2(500); 
    v_id_instance          NUMBER;
    v_id_session           NUMBER;
    v_id_serial            NUMBER;
    
  BEGIN

    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_kill_report_robot(p_name_report, p_text_message) THEN
      RETURN;
    END IF;
      
    -- Get session information about running report robot
    v_step := 'Get session information about running report robot';
    get_running_report_info(p_name_report => p_name_report,
                            p_id_instance => v_id_instance,
                            p_id_session  => v_id_session,
                            p_id_serial   => v_id_serial);
                                  
    -- If session information was successfully retrieved
    IF v_id_instance IS NOT NULL 
        AND v_id_session IS NOT NULL 
        AND v_id_serial IS NOT NULL THEN
     
      -- Kill session
      v_step := 'Kill session'; 
      dbadmin.kill_session(in_sid     => v_id_session,
                           in_serial# => v_id_serial,
                           in_reason  => 'Request for kill from DWH console',
                           in_inst_id => v_id_instance);
      
      -- Log message for report robot
      v_step := 'Log message for report robot';
      -- Set message
      p_text_message := 'Report robot has been killed!';      
      -- Log message
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => p_text_message); 
      -- Set report robot status
      owner_core.lib_report_robot.set_report_status(p_name_report  => p_name_report,
                                                    p_code_status  => c_status_error,
                                                    p_text_message => p_text_message);     
    
    -- Otherwise ...                     
    ELSE
      
      -- Set message
      p_text_message := 'Report robot cannot be killed, because it was not possible to retrieve session information!';
    
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN  
      -- Rollback
      ROLLBACK;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(SQLERRM, 1, 1000);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_warning, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => p_text_message);
                                                    
  END kill_report; 
    
END lib_report_robot_run_api;
/
