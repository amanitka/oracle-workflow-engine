CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_process_run_transfer IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 15.3.2018
  -- purpose: Sartup of the processes
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_TRANSFER_PROCESS_AUTO
  -- purpose:        Start of autorun transfer processes
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_transfer_process_auto; 
 
END lib_etl_process_run_transfer;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_process_run_transfer IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name                CONSTANT VARCHAR2(30) := 'LIB_ETL_PROCESS_RUN_TRANSFER';
  c_flag_n                  CONSTANT VARCHAR2(1)  := 'N';
  c_autorun_transfer_method CONSTANT VARCHAR2(30) := 'AUTORUN_TRANSFER';   
  c_status_cancel           CONSTANT VARCHAR2(10) := 'CANCEL'; 
  c_log_type_message        CONSTANT VARCHAR2(10) := 'MESSAGE';
  c_log_type_error          CONSTANT VARCHAR2(10) := 'ERROR';
  c_id_batch_param          CONSTANT VARCHAR2(30) := 'ID_BATCH';
  v_text_message            VARCHAR2(4000);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_TRANSFER_PROCESS_AUTO
  -- purpose:        Start of autorun transfer processes
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_transfer_process_auto
  IS
  
    c_proc_name           VARCHAR2(30) := 'START_TRANSFER_PROCESS_AUTO';
    v_step                VARCHAR2(500); 
    v_dtime_start_new     DATE := SYSDATE;
    v_date_effective_curr DATE;
    v_id_batch_ext        INTEGER;
    v_result              BOOLEAN;
    i                     INTEGER;
    a_process             owner_wfm.lib_etl_process_run.tt_process;
    
    ex_no_start           EXCEPTION;
    
  BEGIN

    -- Copy new notifications from source system
    v_step := 'Copy new notifications from source system';
    owner_hub.lib_notify.copy_notifications;

    -- Get process info
    v_step := 'Get process info';
    owner_wfm.lib_etl_process_run.get_process_info(p_dtime_start_new => v_dtime_start_new,
                                                   p_process         => a_process);
                     
    -- Loop throught processes
    v_step := 'Loop throught processes';
    
    -- Set first position
    i := a_process.first;
    WHILE (i IS NOT NULL)
    LOOP

      -- If the transfer process should be started automatically 
      IF a_process(i).code_start_method = c_autorun_transfer_method THEN
        
        -- Set default values
        v_text_message := NULL;
        v_result       := FALSE; 
    
        BEGIN     
          
          -- Check basic conditions
          v_step := 'Check basic conditions';
          owner_wfm.lib_etl_process_run.check_basic_conditions(p_id_process        => a_process(i).id_process,
                                                               p_process           => a_process,
                                                               p_flag_manual_start => c_flag_n,
                                                               p_text_message      => v_text_message,
                                                               p_result            => v_result);

          -- If result is false
          IF NOT v_result THEN
            
            -- Raise expcetion
            RAISE ex_no_start;
            
          END IF;   
          
          
          -- Get current date effective for process (canceled processes must be exluded)
          v_step := 'Get current date effective for process';
          IF a_process(i).code_status_curr != c_status_cancel THEN
            
            v_date_effective_curr := a_process(i).date_effective_curr;
            
          ELSE

            SELECT
               MAX(date_effective)
              INTO
               v_date_effective_curr 
            FROM owner_wfm.etl_process_instance
            WHERE id_process = a_process(i).id_process
              AND code_status != c_status_cancel;
              
          END IF;

          -- Get effective date and value for id batch
          v_step := 'Get effective date and value for id batch';
          owner_hub.lib_remote_transfer.process_group_ready(p_id_process          => a_process(i).id_process,
                                                            p_date_effective_curr => v_date_effective_curr,                    
                                                            p_code_process_group  => a_process(i).code_process_group,
                                                            p_date_effective      => a_process(i).date_effective_new,
                                                            p_id_batch_ext        => v_id_batch_ext);
 
          -- Set parameter name and value
          v_step := 'Set parameter name and value';   
          a_process(i).process_parameter(1).name_parameter := c_id_batch_param; 
          a_process(i).process_parameter(1).text_value := TO_CHAR(v_id_batch_ext); 

          -- Check date effective conditions
          v_step := 'Check date effective conditions';
          owner_wfm.lib_etl_process_run.check_dateeff_conditions(p_id_process   => a_process(i).id_process,
                                                                 p_process      => a_process,
                                                                 p_text_message => v_text_message,
                                                                 p_result       => v_result);

          -- If result is false
          IF NOT v_result THEN
            
            -- Raise expcetion
            RAISE ex_no_start;
            
          END IF;                               
          
          -- Check process conditions
          v_step := 'Check process conditions'; 
          owner_wfm.lib_etl_process_run.check_process_conditions(p_id_process        => a_process(i).id_process,
                                                                 p_process           => a_process,
                                                                 p_flag_manual_start => c_flag_n,
                                                                 p_text_message      => v_text_message,
                                                                 p_result            => v_result);

          -- If result is false
          IF NOT v_result THEN
            
            -- Raise expcetion
            RAISE ex_no_start;
            
          END IF;  

           -- Check current process status 
           -- It has to be done right before start of process (bug with multiple process start when called in parallel)
           v_step := 'Check process status'; 
           owner_wfm.lib_etl_process_run.check_process_status(p_id_process   => a_process(i).id_process,
                                                              p_process      => a_process,
                                                              p_text_message => v_text_message,
                                                              p_result       => v_result);

           -- If result is false
           IF NOT v_result THEN
           
             -- Raise expcetion
             RAISE ex_no_start;
             
           END IF; 
          
          -- Start process
          v_step := 'Start process'; 
          owner_wfm.lib_etl_process_run.start_process(p_id_process => a_process(i).id_process,        
                                                      p_process    => a_process);
          
        EXCEPTION
          WHEN ex_no_start THEN
            -- Set message
            v_text_message := 'Process ('||a_process(i).name_process||') cannot be started - '||v_text_message;
            -- Log message 
            owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                                   p_name_activity      => c_proc_name,                         
                                                   p_text_message       => v_text_message);
            NULL;
          WHEN OTHERS THEN
            -- Raise error
            RAISE;
            
        END;

      END IF;
      
      -- Set next position
      i := a_process.next(i);
      
    END LOOP; 
      
  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1000);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
                                             
  END start_transfer_process_auto;
    
END lib_etl_process_run_transfer;
/
