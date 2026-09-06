CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_workflow_queue IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_ACTIVITY_RESULT
  -- purpose:        Set activity result to queue for execution in workflow engine
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE set_activity_result(p_id_workflow_activity IN VARCHAR2,
                                p_id_process_instance  IN INTEGER,
                                p_date_effective       IN DATE,                    
                                p_code_status          IN VARCHAR2,
                                p_name_parameter       IN VARCHAR2 DEFAULT NULL,
                                p_text_parameter_value IN VARCHAR2 DEFAULT NULL,
                                p_text_additional_info IN VARCHAR2 DEFAULT NULL);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PROCESS_INBOUND_QUEUE
  -- purpose:        Process inbound queue
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE process_inbound_queue;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_UNPROC_ACTIVITY
  -- purpose:        Check unprocessed activity
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION check_unproc_activity(p_id_process_instance  IN INTEGER,
                                 p_id_workflow_instance IN VARCHAR2) RETURN BOOLEAN;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_RUNNING_ACTIVITY
  -- purpose:        Check if jobs processing activity are still alive
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_running_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_STUCK_ACTIVITY
  -- purpose:        Check and if necessary restart stuck activity in outbound queue
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_stuck_activity;
                  
END lib_etl_workflow_queue;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_workflow_queue IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_workflow_queue             CONSTANT VARCHAR2(30) := 'WORKFLOW_QUEUE';
  c_minus_one                  CONSTANT INTEGER      := -1;
  c_flag_y                     CONSTANT VARCHAR2(1)  := 'Y';
  c_xap                        CONSTANT VARCHAR2(3)  := 'XAP';
  c_log_type_error             CONSTANT VARCHAR2(10) := 'ERROR';
  c_status_complete            CONSTANT VARCHAR2(10) := 'COMPLETE';
  c_status_error               CONSTANT VARCHAR2(10) := 'ERROR';
  c_status_skip                CONSTANT VARCHAR2(10) := 'SKIP';
  c_autorestart_activity       CONSTANT VARCHAR2(30) := 'AUTORESTART_ACTIVITY';
  c_run_activity               CONSTANT VARCHAR2(30) := 'RUN_ACTIVITY';
  c_complete_activity          CONSTANT VARCHAR2(30) := 'COMPLETE_ACTIVITY';
  c_skip_activity              CONSTANT VARCHAR2(30) := 'SKIP_ACTIVITY';
  c_stuck_activity             CONSTANT VARCHAR2(30) := 'STUCK_ACTIVITY';
  c_unstuck_activity           CONSTANT VARCHAR2(30) := 'UNSTUCK_ACTIVITY';
  c_error_activity             CONSTANT VARCHAR2(30) := 'ERROR_ACTIVITY';
  c_plsql_procedure            CONSTANT VARCHAR2(30) := 'PROCEDURE';
  c_plsql_function_template    CONSTANT VARCHAR2(1024) := 'BEGIN :res := #NAME_OBJECT#(p_process_key => #PROCESS_KEY#, p_effective_date => #DATE_EFFECTIVE#, p_data_type => #DATA_TYPE#); END;';
  c_plsql_procedure_template   CONSTANT VARCHAR2(1024) := 'BEGIN #NAME_OBJECT#(p_process_key => #PROCESS_KEY#, p_effective_date => #DATE_EFFECTIVE#, p_data_type => #DATA_TYPE#); END;';
  v_text_message               VARCHAR2(2000); 
  v_text_error_message         VARCHAR2(4000); 
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_ACTIVITY_RESULT
  -- purpose:        Set activity result to queue for execution in workflow engine
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE set_activity_result(p_id_workflow_activity IN VARCHAR2,
                                p_id_process_instance  IN INTEGER,
                                p_date_effective       IN DATE,                    
                                p_code_status          IN VARCHAR2,
                                p_name_parameter       IN VARCHAR2 DEFAULT NULL,
                                p_text_parameter_value IN VARCHAR2 DEFAULT NULL,
                                p_text_additional_info IN VARCHAR2 DEFAULT NULL)
  IS
    
  BEGIN
   
    owner_wfe.lib_wf_queue_api.set_wf_activity_instance_res(p_id_workflow_activity_inst => TO_NUMBER(p_id_workflow_activity),
                                                            p_id_process_instance       => p_id_process_instance,
                                                            p_date_effective            => p_date_effective,                    
                                                            p_code_status               => p_code_status,
                                                            p_name_parameter            => p_name_parameter,
                                                            p_text_parameter_value      => p_text_parameter_value,
                                                            p_text_message              => p_text_additional_info);

    COMMIT;
    
  END set_activity_result;
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PREPARE_PLSQL_BLOCK
  -- purpose:        Prepare anonymous PL/SQL block for execution
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE prepare_plsql_block(p_name_module           IN VARCHAR2,
                                p_id_process_instance   IN INTEGER,
                                p_date_effective        IN DATE,
                                p_text_data             IN VARCHAR2,
                                p_plsql_object_type     OUT VARCHAR2,
                                p_plsql_block           OUT VARCHAR2,
                                p_name_output_parameter OUT VARCHAR2,
                                p_flag_skip             OUT VARCHAR2) IS
  
    v_name_object_type      VARCHAR2(30);         
    v_name_object           VARCHAR2(130);
    v_name_output_parameter VARCHAR2(30); 
    v_flag_skip             VARCHAR2(1);

  BEGIN
    
    -- Get procedure name from etl modules
    SELECT 
       m.name_object_type                      AS name_object_type,
       m.name_object_owner||'.'||m.name_object AS name_object,
       m.name_output_parameter                 AS name_output_parameter,
       m.flag_skip                             AS flag_skip
      INTO
       v_name_object_type,
       v_name_object,
       v_name_output_parameter,
       v_flag_skip
    FROM owner_wfm.etl_module m
    WHERE m.name_module = p_name_module
      AND m.flag_deleted != c_flag_y;
    
    -- Prepare anonymous PL/SQL block for execution
    p_plsql_object_type := v_name_object_type;
    IF v_name_object_type = c_plsql_procedure THEN
      p_plsql_block := c_plsql_procedure_template;
    ELSE
      p_plsql_block := c_plsql_function_template;
    END IF;
    p_plsql_block := REPLACE(p_plsql_block, '#NAME_OBJECT#', v_name_object);
    p_plsql_block := REPLACE(p_plsql_block, '#PROCESS_KEY#', p_id_process_instance);
    p_plsql_block := REPLACE(p_plsql_block, '#DATE_EFFECTIVE#', 'DATE'''||TO_CHAR(p_date_effective,'YYYY-MM-DD')||'''');
    IF p_text_data IS NULL THEN
      p_plsql_block := REPLACE(p_plsql_block, '#DATA_TYPE#', 'NULL');
    ELSE
      p_plsql_block := REPLACE(p_plsql_block, '#DATA_TYPE#', ''''||p_text_data||'''');
    END IF;
    p_name_output_parameter := v_name_output_parameter;
    p_flag_skip := v_flag_skip;

  END prepare_plsql_block;
  
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PROCESS_INBOUND_QUEUE
  -- purpose:        Process inbound queue
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE process_inbound_queue IS
    
    c_proc_name               CONSTANT VARCHAR2(30) := 'PROCESS_INBOUND_QUEUE';        
    v_id_process_instance     INTEGER;
    v_id_instance             NUMBER := SYS_CONTEXT('USERENV', 'INSTANCE');
    v_id_session              NUMBER := SYS_CONTEXT('USERENV', 'SID');
    v_id_audit_session        NUMBER := SYS_CONTEXT('USERENV', 'SESSIONID');
    v_date_effective          DATE;
    v_id_workflow_activity    VARCHAR2(100);
    v_name_module             VARCHAR2(80);
    v_text_data               VARCHAR2(4000);
    v_plsql_object_type       VARCHAR2(30);            
    v_plsql_block             VARCHAR2(32000);
    v_name_output_parameter   VARCHAR2(30); 
    v_text_parameter_value    VARCHAR2(100);
    v_flag_skip               VARCHAR2(1); 
    
    -- autorestrat
    v_cnt_main_loop           NUMBER     := 0;
    v_cnt_loop                NUMBER;
    v_num_wait_sec            NUMBER;
            
    ex_no_data_found          EXCEPTION;
    ex_to_many_rows           EXCEPTION;
    ex_unexpected_error       EXCEPTION;
    --ex_nonexistent_process    EXCEPTION;
    ex_empty_output_parameter EXCEPTION;

  BEGIN
    
    -- Is something in queue?
    IF NOT owner_wfe.lib_wf_queue_api.is_wf_activity_inst_out_empty THEN
      
      -- Something is there, lets take it
      owner_wfe.lib_wf_queue_api.get_wf_activity_instance(p_id_workflow_activity_inst => v_id_workflow_activity,
                                                          p_id_process_instance       => v_id_process_instance,
                                                          p_date_effective            => v_date_effective,
                                                          p_name_module               => v_name_module,
                                                          p_text_data                 => v_text_data);

      -- If module name is not empty then process it
      IF v_name_module IS NOT NULL THEN
              
        BEGIN               

          -- Prepare PLSQL block
          prepare_plsql_block(p_name_module           => v_name_module,
                              p_id_process_instance   => v_id_process_instance,
                              p_date_effective        => v_date_effective,
                              p_text_data             => v_text_data,
                              p_plsql_object_type     => v_plsql_object_type,
                              p_plsql_block           => v_plsql_block,
                              p_name_output_parameter => v_name_output_parameter,
                              p_flag_skip             => v_flag_skip);       
                              
          -- If module should be processed
          IF v_flag_skip != c_flag_y THEN

            -- Put it into wf running activity table
            INSERT INTO owner_wfm.etl_wf_running_activity
              (id_instance,
               id_session,
               id_audit_session, 
               date_effective, 
               id_process_instance, 
               id_workflow_activity, 
               name_module,
               text_data,
               name_output_parameter,
               dtime_inserted)
            VALUES
              (v_id_instance,
               v_id_session,
               v_id_audit_session,
               v_date_effective,
               v_id_process_instance,
               v_id_workflow_activity,
               v_name_module,
               v_text_data,
               v_name_output_parameter,
               SYSDATE);
            
            -- Commit
            COMMIT;
            
            -- Set session settings
            owner_core.lib_session_settings.set_session(p_name_module => c_workflow_queue,
                                                        p_process_key => c_minus_one);

            -- Autorestart GOTO
            <<autorestart>>
            v_cnt_main_loop := v_cnt_main_loop + 1;
            
            -- Set message
            v_text_message := CASE WHEN v_text_data IS NOT NULL THEN 'Data type ('||v_text_data||')' ELSE NULL END;
  
            -- Log process activity
            owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => v_date_effective,
                                                           p_id_process_instance  => v_id_process_instance,
                                                           p_id_workflow_activity => v_id_workflow_activity,
                                                           p_name_module          => v_name_module,
                                                           p_name_activity        => c_run_activity,                         
                                                           p_text_message         => v_text_message);
            
            -- Execute it 
            BEGIN
              
              -- Set module name into session
              sys.dbms_application_info.set_action(action_name => v_name_module);
              
              -- If it is procedure
              IF v_plsql_object_type = c_plsql_procedure THEN
              
                -- Execute PL/SQL procedure
                EXECUTE IMMEDIATE v_plsql_block;
                
                -- Send message that it is OK
                set_activity_result(p_id_workflow_activity => v_id_workflow_activity,
                                    p_id_process_instance  => v_id_process_instance,
                                    p_date_effective       => v_date_effective,  
                                    p_code_status          => c_status_complete);
              
              -- Otherwise it is function
              ELSE
                
                -- Execute PL/SQL function
                EXECUTE IMMEDIATE v_plsql_block USING OUT v_text_parameter_value;
                
                -- Check if parameter name and its value are filled
                IF v_text_parameter_value IS NOT NULL THEN
                
                  -- Send OK message
                  set_activity_result(p_id_workflow_activity => v_id_workflow_activity,
                                      p_id_process_instance  => v_id_process_instance,
                                      p_date_effective       => v_date_effective,
                                      p_name_parameter       => v_name_output_parameter,
                                      p_text_parameter_value => v_text_parameter_value,
                                      p_code_status          => c_status_complete); 
                  
                -- Otherwise raise an exception
                ELSE 
                  RAISE ex_empty_output_parameter;
                END IF;
                                        
              END IF;  
              
              -- Log process activity
              owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => v_date_effective,
                                                             p_id_process_instance  => v_id_process_instance,
                                                             p_id_workflow_activity => v_id_workflow_activity,
                                                             p_name_module          => v_name_module,
                                                             p_name_activity        => c_complete_activity,                         
                                                             p_text_message         => v_text_message);                                                                                

            EXCEPTION
              WHEN ex_empty_output_parameter THEN
                -- Rollback
                ROLLBACK;
                
                -- Set error message
                v_text_message := 'Module (function) returned empty output parameter value. Parameter name is "'||v_name_output_parameter||'" and value is "'||v_text_parameter_value||'"!';
                
                -- Send error message
                set_activity_result(p_id_workflow_activity => v_id_workflow_activity,
                                    p_id_process_instance  => v_id_process_instance,
                                    p_date_effective       => v_date_effective,
                                    p_name_parameter       => v_name_output_parameter,
                                    p_code_status          => c_status_error,
                                    p_text_additional_info => v_text_message);                                      
                
                -- Set process status to error
                owner_wfm.lib_etl_process_run.error_process(p_id_process_instance => v_id_process_instance);
                
                -- Log process activity error
                owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => v_date_effective,
                                                               p_id_process_instance  => v_id_process_instance,
                                                               p_id_workflow_activity => v_id_workflow_activity,
                                                               p_name_module          => v_name_module,
                                                               p_name_activity        => c_error_activity,                         
                                                               p_text_message         => v_text_message);
            
              WHEN OTHERS THEN
                -- Rollback
                ROLLBACK;
                
                -- Get error message
                v_text_error_message := dbms_utility.format_error_stack;
                
                -- Get autorestart parameters
                owner_wfm.lib_etl_global_config_param.get_autorestart_parameters(p_text_sqlerror => v_text_error_message,
                                                                                 p_cnt_loop      => v_cnt_loop,
                                                                                 p_num_wait_sec  => v_num_wait_sec);
                
                -- Decide if the process should be autorestarted
                IF v_cnt_loop IS NOT NULL AND v_cnt_loop > v_cnt_main_loop THEN
                  
                  -- Set message 
                  v_text_message := 'Autorestart settings - loop: '||TO_CHAR(v_cnt_main_loop)||', wait: '||TO_CHAR(v_num_wait_sec)||'. Message: '||SUBSTR(v_text_error_message, 1 , 1500);        
                                  
                  -- Log process activity autorestart
                  owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => v_date_effective,
                                                                 p_id_process_instance  => v_id_process_instance,
                                                                 p_id_workflow_activity => v_id_workflow_activity,
                                                                 p_name_module          => v_name_module,
                                                                 p_name_activity        => c_autorestart_activity,                         
                                                                 p_text_message         => v_text_message);  
                  
                  -- Set application info, wait specified time and restart it
                  sys.dbms_application_info.set_client_info(client_info => c_autorestart_activity || ' loop: ' || TO_CHAR(v_cnt_main_loop));
                  dbms_lock.sleep(seconds => v_num_wait_sec);
                  GOTO autorestart;
                  
                END IF;
              
                -- Set error message
                v_text_message := SUBSTR(v_text_error_message, 1 , 1500);
                
                -- Send error message
                set_activity_result(p_id_workflow_activity => v_id_workflow_activity,
                                    p_id_process_instance  => v_id_process_instance,
                                    p_date_effective       => v_date_effective,
                                    p_name_parameter       => v_name_output_parameter,
                                    p_code_status          => c_status_error,
                                    p_text_additional_info => v_text_message);                                
                
                -- Set process status to error
                owner_wfm.lib_etl_process_run.error_process(p_id_process_instance => v_id_process_instance);
                
                -- Log process activity error
                owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => v_date_effective,
                                                               p_id_process_instance  => v_id_process_instance,
                                                               p_id_workflow_activity => v_id_workflow_activity,
                                                               p_name_module          => v_name_module,
                                                               p_name_activity        => c_error_activity,                         
                                                               p_text_message         => v_text_message);

            END;
            
            -- Cleanup
            DELETE owner_wfm.etl_wf_running_activity 
            WHERE id_workflow_activity = v_id_workflow_activity
              AND id_instance = v_id_instance
              AND id_session = v_id_session
              AND id_audit_session = v_id_audit_session;

            -- Commit
            COMMIT;  
            
          -- Otherwise skip it
          ELSE
               
            -- Set message
            v_text_message := 'Auto skip';
                                                         
            -- Send OK message
            set_activity_result(p_id_workflow_activity => v_id_workflow_activity,
                                p_id_process_instance  => v_id_process_instance,
                                p_date_effective       => v_date_effective,
                                p_name_parameter       => v_name_output_parameter,
                                p_code_status          => c_status_skip,
                                p_text_additional_info => v_text_message);
                                
                                
                                                                 
            -- Commit
            COMMIT;  
            
            -- Set message
            v_text_message := 'Module was skiped.';

            -- Log process activity
            owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => v_date_effective,
                                                           p_id_process_instance  => v_id_process_instance,
                                                           p_id_workflow_activity => v_id_workflow_activity,
                                                           p_name_module          => v_name_module,
                                                           p_name_activity        => c_skip_activity,                         
                                                           p_text_message         => v_text_message);
          
          END IF;
          
        -- Oops it failed ....
        EXCEPTION
          WHEN no_data_found THEN
            -- Set error message and raise exception
            v_text_message := 'Module is not defined in ETL Modules!';
            RAISE ex_no_data_found;
          
          WHEN too_many_rows THEN
            -- Set error message and raise exception
            v_text_message := 'Module has failed on too many rows!';
            RAISE ex_to_many_rows;
          
          WHEN OTHERS THEN
            -- Get error message
            v_text_error_message := dbms_utility.format_error_stack;
            
            -- Set error message and raise exception
            v_text_message := 'Module has failed on unexpected error! Error message - ' || SUBSTR(v_text_error_message, 1 , 1500);
            RAISE ex_unexpected_error;
            
        END;
        
      END IF;  
      
      -- Commit
      COMMIT;
        
    END IF;
    
  EXCEPTION
    WHEN ex_no_data_found OR ex_to_many_rows OR ex_unexpected_error THEN
      -- Commit
      COMMIT; 
      
      -- Send error message
      set_activity_result(p_id_workflow_activity => v_id_workflow_activity,
                          p_id_process_instance  => v_id_process_instance,
                          p_date_effective       => v_date_effective, 
                          p_name_parameter       => v_name_output_parameter,       
                          p_code_status          => c_status_error,
                          p_text_additional_info => v_text_message);
                                              
      -- Set process status to error
      owner_wfm.lib_etl_process_run.error_process(p_id_process_instance => v_id_process_instance);

      -- Log process activity error
      owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => v_date_effective,
                                                     p_id_process_instance  => v_id_process_instance,
                                                     p_id_workflow_activity => v_id_workflow_activity,
                                                     p_name_module          => v_name_module,
                                                     p_name_activity        => c_error_activity,                         
                                                     p_text_message         => v_text_message);        

    WHEN OTHERS THEN 
      -- Rollback
      ROLLBACK;
      -- Get error message
      v_text_error_message := dbms_utility.format_error_stack;
      
      -- Set error message
      v_text_message := 'Error message - ' || SUBSTR(v_text_error_message, 1 , 1500);
      
      -- Log activity error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error,
                                             p_name_activity      => c_proc_name,
                                             p_text_message       => v_text_message);        
  
  END process_inbound_queue;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_UNPROC_ACTIVITY
  -- purpose:        Check unprocessed activity
  --------------------------------------------------------------------------------------------------------- 
  FUNCTION check_unproc_activity(p_id_process_instance  IN INTEGER,
                                 p_id_workflow_instance IN VARCHAR2) RETURN BOOLEAN
  IS
  
    v_cnt_running INTEGER;
    v_result      BOOLEAN := TRUE;

  BEGIN

    -- Set result
    -- Find out if there are some unprocessed messges in inbound and outbound queue (from workflow engine point of view it is outbound / inbound)
    IF NOT owner_wfm.lib_etl_workflow_api.check_unproc_activity(p_id_workflow_instance => p_id_workflow_instance) THEN
      
      -- Find out if there are some running activities
      SELECT 
         COUNT(1) AS cnt_running
        INTO
         v_cnt_running
      FROM owner_wfm.etl_wf_running_activity
      WHERE id_process_instance = p_id_process_instance;
      
      IF v_cnt_running = 0 THEN
        -- If all activities and messages were processed set false
        v_result := FALSE;
      END IF;

    END IF;
    
    -- Return result
   RETURN v_result;
      
  END check_unproc_activity; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_RUNNING_ACTIVITY
  -- purpose:        Check if jobs processing activities are still alive
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_running_activity IS

    c_proc_name CONSTANT VARCHAR2(30) := 'CHECK_RUNNING_ACTIVITY';  
    
    CURSOR c_running_activity IS
     SELECT 
        id_instance,
        id_session,
        id_audit_session,
        date_effective,
        id_process_instance,
        id_workflow_activity,
        name_module,
        name_output_parameter
     FROM owner_wfm.etl_wf_running_activity wfa
     WHERE NOT EXISTS (SELECT 1
                       FROM sys.gv_$session s
                       WHERE s.inst_id = wfa.id_instance
                         AND s.sid = wfa.id_session
                         AND s.audsid = wfa.id_audit_session
                       );
      
  BEGIN
    
    -- Loop through "running" activities which are actually no longer running. Session has been either killed or it died.
    FOR r IN c_running_activity
    LOOP
      
      -- Set error message
      v_text_message := 'Session no longer exists. Session identification (Id instance - '||r.id_instance||', Id session - '||r.id_session||', Id audit session - '||r.id_audit_session||').';
      
      -- Send error message
      set_activity_result(p_id_workflow_activity => r.id_workflow_activity,
                          p_id_process_instance  => r.id_process_instance,
                          p_date_effective       => r.date_effective,
                          p_name_parameter       => r.name_output_parameter,
                          p_code_status          => c_status_error,
                          p_text_additional_info => v_text_message);

      -- Set process status to error
      BEGIN
        owner_wfm.lib_etl_process_run.error_process(p_id_process_instance => r.id_process_instance);
      EXCEPTION
        WHEN OTHERS THEN
          -- If the processs does not exists (was removed, do nothing)
          NULL;
      END;   
        
      -- Log process activity error
      owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => r.date_effective,
                                                     p_id_process_instance  => r.id_process_instance,
                                                     p_id_workflow_activity => r.id_workflow_activity,
                                                     p_name_module          => r.name_module,
                                                     p_name_activity        => c_error_activity,                         
                                                     p_text_message         => v_text_message);

      -- Cleanup
      DELETE owner_wfm.etl_wf_running_activity 
      WHERE id_workflow_activity = r.id_workflow_activity
        AND id_instance = r.id_instance
        AND id_session = r.id_session
        AND id_audit_session = r.id_audit_session;
        
      -- Commit
      COMMIT;
      
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN 
      -- Rollback
      ROLLBACK;
      -- Get error message
      v_text_error_message := dbms_utility.format_error_stack;
            
      -- Set error message
      v_text_message := 'Error message - ' || SUBSTR(v_text_error_message, 1 , 1500);
      
      -- Log activity error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error,
                                             p_name_activity      => c_proc_name,
                                             p_text_message       => v_text_message);    
    
  END check_running_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_STUCK_ACTIVITY
  -- purpose:        Check and if necessary restart stuck activity in workflow queue
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_stuck_activity IS

    c_proc_name                   CONSTANT VARCHAR2(30) := 'CHECK_STUCK_ACTIVITY';
    c_sysdate                     CONSTANT DATE := SYSDATE; 
    c_wf_aq_activity_inst_in      CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aq_activity_inst_in;
    c_wf_aqn_activity_inst_in_e   CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aqn_activity_inst_in_e;
    c_wf_stuck_activity_loop      CONSTANT NUMBER := owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'WF_STUCK_ACTIVITY_LOOP', p_code_group => 'WF_QUEUE');
    c_wf_stuck_activity_wait      CONSTANT NUMBER := owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'WF_STUCK_ACTIVITY_WAIT', p_code_group => 'WF_QUEUE');
    c_wf_stuck_activity_threshold CONSTANT NUMBER := owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'WF_STUCK_ACTIVITY_THRESHOLD', p_code_group => 'WF_QUEUE');
    c_queue_timezone              CONSTANT VARCHAR2(20) := owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'QUEUE_ENQTIME_TIMEZONE', p_code_group => 'ORACLE_ENV');
    c_default_timezone            CONSTANT VARCHAR2(60) := owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'DEFAULT_TIMEZONE', p_code_group => 'ORACLE_ENV');
    
    CURSOR c_wf_stuck_activity IS
      WITH wf_activity_instance AS (SELECT
                                       aqi.name_queue                    AS name_queue,
                                       aqi.id_message                    AS id_message,
                                       aqi.id_workflow_instance_main     AS id_workflow_instance_main,
                                       aqi.id_workflow_activity_instance AS id_workflow_activity,
                                       rai.id_workflow_activity_instance AS id_workflow_activity_run,
                                       aqi.id_process_instance           AS id_process_instance,
                                       aqi.date_effective                AS date_effective,
                                       aqi.name_module                   AS name_module
                                    FROM owner_wfe.v_wf_aq_activity_inst_in aqi
                                    LEFT JOIN owner_wfe.v_wf_run_activity_instance rai ON rai.id_workflow_activity_instance = aqi.id_workflow_activity_instance
                                                                                      AND rai.date_effective = aqi.date_effective
                                          -- Message is in exception queue
                                    WHERE aqi.name_queue = c_wf_aqn_activity_inst_in_e
                                          -- Or its there longer then specified threshold
                                       OR (c_sysdate - CAST(FROM_TZ(aqi.dtime_enqueue, c_queue_timezone) AT TIME ZONE CAST(c_default_timezone as VARCHAR2(60)) AS DATE)) * 1440 > c_wf_stuck_activity_threshold
                                      
                                    )
      SELECT
         ai.name_queue                                        AS name_queue,  
         ai.id_message                                        AS id_message,
         ai.id_workflow_instance_main                         AS id_workflow_instance_main,
         NVL(ai.id_workflow_activity, s.id_workflow_activity) AS id_workflow_activity,
         ai.id_workflow_activity_run                          AS id_workflow_activity_run,
         NVL(ai.id_process_instance, s.id_process_instance)   AS id_process_instance,
         NVL(ai.date_effective, s.date_effective)             AS date_effective,
         NVL(ai.name_module, s.name_module)                   AS name_module,
         s.cnt_restart                                        AS cnt_restart,
         s.dtime_updated                                      AS dtime_updated
      FROM wf_activity_instance ai
      FULL JOIN owner_wfm.etl_wf_stuck_activity s ON s.id_workflow_activity = ai.id_workflow_activity;
      
    v_unstuck_activity       BOOLEAN := FALSE;
    v_name_module            VARCHAR2(80);
      
  BEGIN
    
    -- Loop through stuck activities
    FOR s IN c_wf_stuck_activity
    LOOP
      
      -- Set module name
      IF s.name_module IS NOT NULL THEN

        -- Set module name 
        v_name_module := s.name_module;
          
      ELSE
        
        -- Get module name 
        SELECT
           NVL(MAX(name_module), c_xap)
          INTO
           v_name_module 
        FROM owner_wfm.etl_process_instance_activity
        WHERE date_effective = s.date_effective
          AND id_process_instance = s.id_process_instance
          AND id_workflow_activity = s.id_workflow_activity
          AND name_activity = c_run_activity; 
      
      END IF;
    
      -- If there is still stuck message
      IF s.id_message IS NOT NULL THEN
              
        -- If there is no record in stuck activity table
        IF s.dtime_updated IS NULL THEN
          
          -- Set message
          v_text_message := 'Activity is stuck in workflow AQ ('||c_wf_aq_activity_inst_in||'), because workflow engine refuses to process it. It will be necessary to check workflow logs to get detail information!';
          
          -- Set process status to stuck
          BEGIN
            owner_wfm.lib_etl_process_run.stuck_process(p_id_process_instance => s.id_process_instance);
          EXCEPTION
            WHEN OTHERS THEN 
              -- Procedure will raise exception if such process is no longer latest (doesnt exists in process status table)
              -- This error can be ignored
              NULL;
          END;
          
          -- Log process activity error
          owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => s.date_effective,
                                                         p_id_process_instance  => s.id_process_instance,
                                                         p_id_workflow_activity => s.id_workflow_activity,
                                                         p_name_module          => v_name_module,
                                                         p_name_activity        => c_stuck_activity,                         
                                                         p_text_message         => v_text_message);
          
          -- Insert new record
          INSERT INTO owner_wfm.etl_wf_stuck_activity
            (date_effective, 
             id_process_instance, 
             id_workflow_activity,
             name_module,
             cnt_restart, 
             dtime_inserted, 
             dtime_updated)
          VALUES
            (s.date_effective,
             s.id_process_instance,
             s.id_workflow_activity,
             v_name_module,
             0,
             c_sysdate,
             c_sysdate);
             
          -- Commit   
          COMMIT;

        END IF;
        
        -- If the stuck message is new or interval since last restart passed then restart it
        IF s.dtime_updated IS NULL
          OR (s.cnt_restart < c_wf_stuck_activity_loop AND (s.dtime_updated + c_wf_stuck_activity_wait / 1440) < c_sysdate) THEN
          
          -- Restart / resend expired outbound queue
          owner_wfe.lib_wf_queue_api.restart_wf_activity_inst_in(p_name_queue                => s.name_queue,
                                                                 p_id_workflow_instance_main => s.id_workflow_instance_main,
                                                                 p_id_workflow_activity_inst => s.id_workflow_activity);

          -- Increase counter
          UPDATE owner_wfm.etl_wf_stuck_activity
             SET cnt_restart = cnt_restart + 1,
                 dtime_updated = c_sysdate
          WHERE id_workflow_activity = s.id_workflow_activity;
          
          -- Commit
          COMMIT;
        
        END IF;
        
        -- If there is no record for running activity in workflow engine then purge it from outgoing queue
        IF s.id_workflow_activity_run IS NULL THEN
          
          -- Purge outbound queue for given workflow activity
          owner_wfe.lib_wf_queue_api.purge_wf_activity_inst_in(p_id_workflow_activity_inst => s.id_workflow_activity);
                               
          -- Set unstuck activity to TRUE
          v_unstuck_activity := TRUE;
        
        END IF;
        
      -- Otherwise mark activity as unstuck
      ELSE

        -- Set unstuck activity to TRUE
        v_unstuck_activity := TRUE;
        
      END IF;
      
      -- Cleanup stuck activity table
      IF v_unstuck_activity THEN
        
        -- Cleanup table
        DELETE owner_wfm.etl_wf_stuck_activity
        WHERE id_workflow_activity = s.id_workflow_activity;

        -- Set message
        v_text_message := 'Activity is no longer stuck in workflow AQ ('||c_wf_aq_activity_inst_in||').';
        
        -- Log
        owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => s.date_effective,
                                                       p_id_process_instance  => s.id_process_instance,
                                                       p_id_workflow_activity => s.id_workflow_activity,
                                                       p_name_module          => v_name_module,
                                                       p_name_activity        => c_unstuck_activity,                         
                                                       p_text_message         => v_text_message);

        -- Commit
        COMMIT;
      
      END IF;

    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN 
      -- Rollback
      ROLLBACK;
      -- Get error message
      v_text_error_message := dbms_utility.format_error_stack;
            
      -- Set error message
      v_text_message := 'Error message - ' || SUBSTR(v_text_error_message, 1 , 1500);
      
      -- Log activity error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error,
                                             p_name_activity      => c_proc_name,
                                             p_text_message       => v_text_message);    
    
  END check_stuck_activity;
 
END lib_etl_workflow_queue;
/
