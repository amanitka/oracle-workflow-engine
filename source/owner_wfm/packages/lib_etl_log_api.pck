CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_log_api is

  ---------------------------------------------------------------------------------------------------------
  -- author:  Workflow Team
  -- created: 23.3.2018
  -- purpose: API for logging of different kind of logs
  --          Logging of activities - results of process run checks, etc... 
  --          Logging of processes
  --          Logging of mappings
  
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------   
  c_xap CONSTANT VARCHAR2(3)  := 'XAP';
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_ACTIVITY
  -- purpose:        log activity his type, name and message
  --
  -- p_name_activity_type - recommended values are WARNING - warning, MESSAGE - message, ERROR - error
  --                      - in spite of recommended values can still contain any other values
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE log_activity(p_name_activity_type IN VARCHAR2, 
                         p_name_activity      IN VARCHAR2,                         
                         p_text_message       IN VARCHAR2);
                         
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_PROCESS_ACTIVITY
  -- purpose:        log process activity
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE log_process_activity(p_date_effective       IN DATE,
                                 p_id_process_instance  IN INTEGER,
                                 p_id_workflow_activity IN VARCHAR2 DEFAULT c_xap,
                                 p_name_module          IN VARCHAR2 DEFAULT c_xap,
                                 p_name_activity        IN VARCHAR2,                         
                                 p_text_message         IN VARCHAR2);
                           
END lib_etl_log_api;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_log_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_restart_process  CONSTANT VARCHAR2(30) := 'RESTART_PROCESS';
  c_cancel_process   CONSTANT VARCHAR2(30) := 'CANCEL_PROCESS';
  c_skip_activity    CONSTANT VARCHAR2(30) := 'SKIP_ACTIVITY';
  c_stuck_activity   CONSTANT VARCHAR2(30) := 'STUCK_ACTIVITY';
  c_unstuck_activity CONSTANT VARCHAR2(30) := 'UNSTUCK_ACTIVITY';
  c_restart_activity CONSTANT VARCHAR2(30) := 'RESTART_ACTIVITY';
  c_error_activity   CONSTANT VARCHAR2(30) := 'ERROR_ACTIVITY';
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_ACTIVITY
  -- purpose:        log activity type, name and message
  --
  -- p_name_activity_type - recommended values are WARNING - warning, MESSAGE - message, ERROR - error
  --                      - in spite of recommended values can still contain any other values
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE log_activity(p_name_activity_type IN VARCHAR2, 
                         p_name_activity      IN VARCHAR2,                         
                         p_text_message       IN VARCHAR2)
  IS

    v_user VARCHAR2(70);
    PRAGMA AUTONOMOUS_TRANSACTION;

  BEGIN

    -- Get user name
    v_user := CASE WHEN SYS_CONTEXT('USERENV', 'PROXY_USER') IS NULL THEN SYS_CONTEXT('USERENV', 'SESSION_USER')
                   ELSE SYS_CONTEXT('USERENV', 'PROXY_USER') ||'['|| SYS_CONTEXT('USERENV', 'SESSION_USER')||']'
              END;

    -- Put new record into logging table
    INSERT INTO owner_wfm.etl_activity_log
      (name_activity_type, 
       name_activity, 
       text_message, 
       dtime_inserted, 
       user_inserted)
    VALUES
      (p_name_activity_type,
       p_name_activity,
       p_text_message,
       SYSDATE,
       v_user);
    COMMIT;

  EXCEPTION 
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
   
  END log_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_PROCESS_ACTIVITY
  -- purpose:        log process activity
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE log_process_activity(p_date_effective       IN DATE,
                                 p_id_process_instance  IN INTEGER,
                                 p_id_workflow_activity IN VARCHAR2 DEFAULT c_xap,
                                 p_name_module          IN VARCHAR2 DEFAULT c_xap,
                                 p_name_activity        IN VARCHAR2,                         
                                 p_text_message         IN VARCHAR2)
  IS

    v_user VARCHAR2(70);
    PRAGMA AUTONOMOUS_TRANSACTION;

  BEGIN
  
    -- Get user name
    v_user := CASE WHEN SYS_CONTEXT('USERENV', 'PROXY_USER') IS NULL THEN SYS_CONTEXT('USERENV', 'SESSION_USER')
                   ELSE SYS_CONTEXT('USERENV', 'PROXY_USER') ||'['|| SYS_CONTEXT('USERENV', 'SESSION_USER')||']'
              END;

    -- Put new record into logging table
    INSERT INTO owner_wfm.etl_process_instance_activity
      (date_effective, 
       id_process_instance, 
       id_workflow_activity, 
       name_module, 
       name_activity, 
       text_message, 
       dtime_inserted, 
       user_inserted)
    VALUES
      (p_date_effective,
       p_id_process_instance,
       p_id_workflow_activity,
       p_name_module,
       p_name_activity,
       p_text_message,
       SYSDATE,
       v_user);
    COMMIT;

    -- Process monitoring log
    IF p_name_activity IN (c_error_activity, c_stuck_activity) THEN
       
       owner_wfm.lib_etl_monitoring_log_api.log_process_activity_error(p_date_effective       => p_date_effective,
                                                                       p_id_process_instance  => p_id_process_instance,
                                                                       p_id_workflow_activity => p_id_workflow_activity,
                                                                       p_name_module          => p_name_module,
                                                                       p_text_error_message   => p_text_message);  

    ELSIF p_name_activity IN (c_skip_activity, c_unstuck_activity, c_restart_activity) THEN

       owner_wfm.lib_etl_monitoring_log_api.confirm_process_activity_error(p_date_effective       => p_date_effective,
                                                                           p_id_process_instance  => p_id_process_instance,
                                                                           p_id_workflow_activity => p_id_workflow_activity);       

    ELSIF p_name_activity IN (c_cancel_process, c_restart_process) THEN

       owner_wfm.lib_etl_monitoring_log_api.confirm_process_activity_error(p_date_effective       => p_date_effective,
                                                                           p_id_process_instance  => p_id_process_instance);       

    END IF;  
    
  EXCEPTION 
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
        
  END log_process_activity;
  
END lib_etl_log_api;
/
