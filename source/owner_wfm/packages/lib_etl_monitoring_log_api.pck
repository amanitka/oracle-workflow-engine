CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_monitoring_log_api IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Workflow Team
  -- created: 15.11.2018
  -- purpose: Package for monitoring purpose
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_ERROR
  -- purpose:        Insert new record into error log
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE log_error(p_date_effective            IN DATE,
                      p_code_entity               IN VARCHAR2, 
                      p_id_entity                 IN VARCHAR2,
                      p_id_entity_instance        IN VARCHAR2 DEFAULT NULL, 
                      p_id_entity_activity        IN VARCHAR2 DEFAULT NULL,
                      p_code_error_type           IN VARCHAR2,
                      p_text_message              IN VARCHAR2,
                      p_text_error_message        IN VARCHAR2 DEFAULT NULL,
                      p_num_severity              IN INTEGER, 
                      p_code_responsibility_group IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CONFIRM_ERROR
  -- purpose:        Confirm record in error log based on entity information
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE confirm_error(p_date_effective     IN DATE,
                          p_code_entity        IN VARCHAR2, 
                          p_id_entity          IN VARCHAR2,
                          p_id_entity_instance IN VARCHAR2, 
                          p_id_entity_activity IN VARCHAR2 DEFAULT NULL,
                          p_code_error_type    IN VARCHAR2);
                          
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CONFIRM_ERROR
  -- purpose:        Confirm record in error log based on log id
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE confirm_error(p_date_effective IN DATE,
                          p_id             IN INTEGER);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_ERROR_SENT
  -- purpose:        Set record in error log as sent - On call has been activated or info mail has been sent to ServiceDesk
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE set_error_sent(p_date_effective IN DATE,
                           p_id             IN INTEGER);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_PROCESS_ACTIVITY_ERROR
  -- purpose:        Log process activity error
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE log_process_activity_error(p_date_effective          IN DATE,
                                       p_id_process_instance     IN INTEGER,
                                       p_id_workflow_activity    IN VARCHAR2,
                                       p_name_module             IN VARCHAR2,
                                       p_text_error_message      IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CONFIRM_PROCESS_ACTIVITY_ERROR
  -- purpose:        Confirm process activity error
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE confirm_process_activity_error(p_date_effective          IN DATE,
                                           p_id_process_instance     IN INTEGER,
                                           p_id_workflow_activity    IN VARCHAR2 DEFAULT NULL);

END lib_etl_monitoring_log_api;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_monitoring_log_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name                  CONSTANT VARCHAR2(30) := 'LIB_ETL_MONITORING_LOG_API'; 
  c_code_error_status         CONSTANT VARCHAR2(30) := 'ERROR';  
  c_code_complete_status      CONSTANT VARCHAR2(30) := 'COMPLETE';  
  c_flag_N                    CONSTANT VARCHAR2(1) := 'N';
  c_flag_Y                    CONSTANT VARCHAR2(1) := 'Y';
  c_XAP                       CONSTANT VARCHAR2(3) := 'XAP';
  c_responsible_group_default CONSTANT VARCHAR2(10) := 'HCI';
  c_log_type_error            CONSTANT VARCHAR2(10) := 'ERROR';
  c_process_entity            CONSTANT VARCHAR2(20) := 'PROCESS';
  c_activity_error_type       CONSTANT VARCHAR2(20) := 'ACTIVITY';
  v_text_message              VARCHAR2(4000 CHAR);   
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_ERROR
  -- purpose:        Insert new record into error log
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE log_error(p_date_effective            IN DATE,
                      p_code_entity               IN VARCHAR2, 
                      p_id_entity                 IN VARCHAR2,
                      p_id_entity_instance        IN VARCHAR2 DEFAULT NULL, 
                      p_id_entity_activity        IN VARCHAR2 DEFAULT NULL,
                      p_code_error_type           IN VARCHAR2,
                      p_text_message              IN VARCHAR2,
                      p_text_error_message        IN VARCHAR2 DEFAULT NULL,
                      p_num_severity              IN INTEGER, 
                      p_code_responsibility_group IN VARCHAR2)
  IS  

  BEGIN

    -- Put new record into logging table
    INSERT INTO owner_wfm.etl_monitoring_log
      (id, 
       code_entity, 
       id_entity, 
       id_entity_instance, 
       id_entity_activity, 
       date_effective, 
       code_error_type, 
       text_message, 
       text_error_message, 
       code_status, 
       num_severity, 
       code_responsible_group, 
       flag_confirmed, 
       flag_sent)
    VALUES
      (owner_wfm.s_etl_monitoring_log.nextval,
       p_code_entity, 
       p_id_entity,
       NVL(p_id_entity_instance, c_XAP), 
       NVL(p_id_entity_activity, c_XAP),
       p_date_effective, 
       p_code_error_type,
       p_text_message,
       p_text_error_message, 
       c_code_error_status, 
       p_num_severity, 
       NVL(p_code_responsibility_group, c_responsible_group_default), 
       c_flag_N, 
       c_flag_N);
       
    -- Commit
    COMMIT;  

  END log_error;
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CONFIRM_ERROR
  -- purpose:        Confirm record in error log based on entity information
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE confirm_error(p_date_effective     IN DATE,
                          p_code_entity        IN VARCHAR2, 
                          p_id_entity          IN VARCHAR2,
                          p_id_entity_instance IN VARCHAR2, 
                          p_id_entity_activity IN VARCHAR2 DEFAULT NULL,
                          p_code_error_type    IN VARCHAR2)
  IS  

  BEGIN

    -- Confirmation of error record
    IF p_id_entity IS NULL 
        AND p_id_entity_instance IS NOT NULL THEN
        
      IF p_id_entity_activity IS NOT NULL THEN
      
        UPDATE owner_wfm.etl_monitoring_log
        SET flag_confirmed = c_flag_Y,
            code_status    = c_code_complete_status
        WHERE date_effective = p_date_effective
          AND code_entity = p_code_entity
          AND id_entity_instance = p_id_entity_instance
          AND id_entity_activity = p_id_entity_activity
          AND code_error_type = p_code_error_type;
          
      ELSE
         
        UPDATE owner_wfm.etl_monitoring_log
        SET flag_confirmed = c_flag_Y,
            code_status    = c_code_complete_status
        WHERE date_effective = p_date_effective
          AND code_entity = p_code_entity
          AND id_entity_instance = p_id_entity_instance
          AND code_error_type = p_code_error_type;   
          
      END IF;  
        
    ELSE 
      
      UPDATE owner_wfm.etl_monitoring_log
      SET flag_confirmed = c_flag_Y,
          code_status    = c_code_complete_status
      WHERE date_effective = p_date_effective
        AND code_entity = p_code_entity
        AND id_entity = p_id_entity
        AND id_entity_instance = NVL(p_id_entity_instance, c_XAP)
        AND id_entity_activity = NVL(p_id_entity_activity, c_XAP)
        AND code_error_type = p_code_error_type;     
        
    END IF;
       
    -- Commit
    COMMIT;

  END confirm_error;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CONFIRM_ERROR
  -- purpose:        Confirm record in error log based on log id
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE confirm_error(p_date_effective IN DATE,
                          p_id             IN INTEGER)
  IS  

  BEGIN

    -- Confirmation of error record
    UPDATE owner_wfm.etl_monitoring_log
    SET flag_confirmed = c_flag_Y,
        code_status    = c_code_complete_status
    WHERE date_effective = p_date_effective
      AND id = p_id;      
       
    -- Commit
    COMMIT;

  END confirm_error;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_ERROR_SENT
  -- purpose:        Set record in error log as sent - On call has been activated or info mail has been sent to ServiceDesk
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE set_error_sent(p_date_effective IN DATE,
                           p_id             IN INTEGER)
  IS  

  BEGIN

    -- Confirmation of error record
    UPDATE owner_wfm.etl_monitoring_log
    SET flag_sent    = c_flag_Y,
        code_status  = c_code_complete_status
    WHERE date_effective = p_date_effective
      AND id = p_id;      
       
    -- Commit
    COMMIT;

  END set_error_sent;  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: LOG_PROCESS_ACTIVITY_ERROR
  -- purpose:        Log process activity error
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE log_process_activity_error(p_date_effective          IN DATE,
                                       p_id_process_instance     IN INTEGER,
                                       p_id_workflow_activity    IN VARCHAR2,
                                       p_name_module             IN VARCHAR2,
                                       p_text_error_message      IN VARCHAR2)
  IS  
  
    c_proc_name              CONSTANT VARCHAR2(60 CHAR) := 'LOG_PROCESS_ACTIVITY_ERROR';
    v_id_process             VARCHAR2(30 CHAR);
    v_name_process           VARCHAR2(30 CHAR);
    v_num_process_severity   INTEGER;
    v_code_responsible_group VARCHAR2(10 CHAR);
    
  BEGIN

    -- Get information about current process
    BEGIN   

       SELECT 
          TO_CHAR(p.id_process),
          p.name_process,
          p.num_process_severity,
          p.code_responsible_group
         INTO 
          v_id_process,
          v_name_process,
          v_num_process_severity,
          v_code_responsible_group
       FROM owner_wfm.etl_process_status i
       JOIN owner_wfm.etl_process p ON p.id_process = i.id_process
       WHERE i.id_process_instance = p_id_process_instance;
    
    EXCEPTION
      WHEN no_data_found THEN 
        v_id_process             := c_XAP;
        v_name_process           := c_XAP;
        v_num_process_severity   := 1;
        v_code_responsible_group := c_responsible_group_default;
            
    END;

    -- Set message
    IF p_name_module IS NOT NULL THEN
      v_text_message := 'Module '||p_name_module||' in process '||v_name_process||' has failed!';
    ELSE
      v_text_message := 'Process '||v_name_process||' has failed!';
    END IF;  

    -- Log error
    log_error(p_code_entity               => c_process_entity, 
              p_id_entity                 => v_id_process,
              p_id_entity_instance        => TO_CHAR(p_id_process_instance), 
              p_id_entity_activity        => p_id_workflow_activity,
              p_date_effective            => p_date_effective, 
              p_code_error_type           => c_activity_error_type,
              p_text_message              => v_text_message,
              p_text_error_message        => p_text_error_message,
              p_num_severity              => v_num_process_severity, 
              p_code_responsibility_group => v_code_responsible_group);

  EXCEPTION
    WHEN OTHERS THEN 
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);  
      ROLLBACK;      

  END log_process_activity_error;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CONFIRM_PROCESS_ACTIVITY_ERROR
  -- purpose:        Confirm process activity error
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE confirm_process_activity_error(p_date_effective          IN DATE,
                                           p_id_process_instance     IN INTEGER,
                                           p_id_workflow_activity    IN VARCHAR2 DEFAULT NULL)
  IS  
    
    c_proc_name VARCHAR2(60 CHAR) := 'CONFIRM_PROCESS_ACTIVITY_ERROR';

  BEGIN
   
    -- Confirm error
    confirm_error(p_date_effective     => p_date_effective,
                  p_code_entity        => c_process_entity, 
                  p_id_entity          => NULL,
                  p_id_entity_instance => TO_CHAR(p_id_process_instance), 
                  p_id_entity_activity => p_id_workflow_activity,
                  p_code_error_type    => c_activity_error_type);
     
  EXCEPTION
    WHEN OTHERS THEN 
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);  
      ROLLBACK;  

  END confirm_process_activity_error;
 
END lib_etl_monitoring_log_api;
/
