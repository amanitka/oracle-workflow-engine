CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_process_run_api IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 15.3.2018
  -- purpose: Sartup of the process api
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_WORKFLOW_ACTIVITY_LOG
  -- purpose:       Get workflow_activity log
  --                Attributes p_dtime_start and p_dtime_end are no longer in use, they are kept for backwards compatibility  
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_workflow_activity_log(p_id_workflow_instance    IN VARCHAR2,
                                     p_dtime_start             IN DATE DEFAULT NULL,
                                     p_dtime_end               IN DATE DEFAULT NULL,
                                     p_date_effective          IN DATE DEFAULT NULL,
                                     p_display_additional_info IN VARCHAR2 DEFAULT NULL) RETURN owner_wfm.lib_etl_workflow_api.tt_workflow_activity_log PIPELINED;
                                     
  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_WORKFLOW_LIST
  -- purpose:       Get workflow list for given process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_workflow_list(p_name_process IN VARCHAR2) RETURN owner_wfe.lib_wf_diagram_api.tt_workflow_list PIPELINED;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_WORKFLOW
  -- purpose:        Get workflow definition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_workflow(p_id_workflow_definition IN INTEGER DEFAULT NULL,
                         p_name_workflow          IN VARCHAR2 DEFAULT NULL,
                         p_text_workflow          OUT CLOB,
                         p_text_message           OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_EXEC_WORKFLOW
  -- purpose:        Get executed workflow definition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_exec_workflow(p_id_workflow_instance IN INTEGER DEFAULT NULL,
                              p_id_workflow_activity IN INTEGER DEFAULT NULL,                       
                              p_date_effective       IN DATE,
                              p_text_workflow        OUT CLOB,
                              p_text_message         OUT VARCHAR2);
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_RUNNING_ACTIVITY_SQL
  -- purpose:        Get sql text and plan for running activity
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE get_running_activity_sql(p_id_process_instance  IN INTEGER,
                                     p_id_workflow_activity IN VARCHAR2,
                                     p_text_sql             OUT CLOB,
                                     p_text_sql_plan        OUT CLOB,
                                     p_text_message         OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_RUNNING_ACTIVITY_SQL_AI
  -- purpose:        Get sql additional information for running activity
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE get_running_activity_sql_ai(p_id_process_instance  IN INTEGER,
                                        p_id_workflow_activity IN VARCHAR2,
                                        p_id_instance          OUT NUMBER,
                                        p_id_sql               OUT VARCHAR2,
                                        p_text_message         OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_PROCESS_DETAIL
  -- purpose:        Get detailed info for process p_id_process
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE get_process_detail(p_id_process              IN INTEGER,
                               p_date_effective_selected IN DATE,
                               p_date_effective_next     OUT DATE,
                               p_text_detail             OUT CLOB, 
                               p_text_message            OUT VARCHAR2);
                               
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ACTIVATE_START_GROUP
  -- purpose:        Activate process start group
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE activate_start_group(p_code_start_group IN VARCHAR2,
                                 p_text_message     OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEACTIVATE_START_GROUP
  -- purpose:        Deactivate process start group
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE deactivate_start_group(p_code_start_group IN VARCHAR2,
                                   p_text_message     OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ACTIVATE_START_GROUP_ALL
  -- purpose:        Activate all process start groups for given category
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE activate_start_group_all(p_code_start_group_category IN VARCHAR2,
                                     p_text_message              OUT VARCHAR2);
                                     
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEACTIVATE_START_GROUP_ALL
  -- purpose:        Deactivate all process start groups for given category
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE deactivate_start_group_all(p_code_start_group_category IN VARCHAR2,
                                       p_text_message              OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CANCEL_PROCESS
  -- purpose:        Cancel specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE cancel_process(p_id_process_instance IN INTEGER,
                           p_text_message        OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SUSPEND_PROCESS
  -- purpose:        Suspend specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE suspend_process(p_id_process_instance IN INTEGER,
                            p_text_message        OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESUME_PROCESS
  -- purpose:        Resume specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE resume_process(p_id_process_instance IN INTEGER,
                           p_text_message        OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_PROCESS
  -- purpose:        Restart specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE restart_process(p_id_process_instance IN INTEGER,
                            p_text_message        OUT VARCHAR2);
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_PROCESS
  -- purpose:        Manual start of process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_process(p_name_process   IN VARCHAR2,
                          p_date_effective IN DATE,
                          p_text_message   OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SKIP_ACTIVITY
  -- purpose:        Skip activity for specified process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE skip_activity(p_id_process_instance  IN INTEGER,
                          p_id_workflow_activity IN VARCHAR2,
                          p_name_activity        IN VARCHAR2,
                          p_text_message         OUT VARCHAR2);
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: KILL_ACTIVITY
  -- purpose:        Kill activity for specified process
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE kill_activity(p_id_process_instance  IN INTEGER,
                          p_id_workflow_activity IN VARCHAR2,
                          p_name_activity        IN VARCHAR2,
                          p_text_message         OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_ACTIVITY
  -- purpose:        Restart activity for specified process
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE restart_activity(p_id_process_instance  IN INTEGER,
                             p_id_workflow_activity IN VARCHAR2,
                             p_name_activity        IN VARCHAR2,
                             p_text_message         OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: UNSTUCK_ACTIVITY
  -- purpose:        Cancel activity and start before/after some element in camunda worfkflow engine (use only in emergency situation (stuck workflow), it can cause to unforeseen circumstances)
  -- parameters:
  --   P_ID_PROCESS_INSTANCE        - Id of process instance which will be modified      
  --   P_ID_WORKFLOW_ACTIVITY       - Id of workflow activity which needs to be canceled (stuck subprocess)
  --   P_NAME_ACTIVITY              - Name of workflow activity which needs to be canceled (stuck subprocess)
  --   P_CODE_ACTIVITY_START_TYPE   - Code of activity start type (supposerted options are START_BEFORE and START_AFTER
  --   P_ID_WORKFLOW_ELEMENT_START  - Id of workflow element (from workflow definition) before/after which should workflow start/continue
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE unstuck_activity(p_id_process_instance       IN INTEGER,
                             p_id_workflow_activity      IN VARCHAR2,
                             p_name_activity             IN VARCHAR2,
                             p_code_activity_start_type  IN VARCHAR2,
                             p_id_workflow_element_start IN VARCHAR2,
                             p_text_message              OUT VARCHAR2);
                                  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: MANUAL_CONFIRM_LOG
  -- purpose:        Manual confirmation of record in monitoring log -> set status = 'COMPLETE', flag_confirmed = 'Y'
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE manual_confirm_log(p_id             IN NUMBER,
                               p_date_effective IN DATE,
                               p_text_message   OUT VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CONFIRM_FLAG_SEND
  -- purpose:        Confirm record in monitoring log, set FLAG_SEND = 'Y', Email has been sent to ServiceDesk or called emergency
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE confirm_flag_send(p_id             IN NUMBER, 
                              p_date_effective IN DATE,
                              p_text_message   OUT VARCHAR2);

END lib_etl_process_run_api;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_process_run_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name       CONSTANT VARCHAR2(30) := 'LIB_ETL_PROCESS_RUN'; 
  c_flag_n         CONSTANT VARCHAR2(1)  := 'N';
  c_flag_y         CONSTANT VARCHAR2(1)  := 'Y';
  c_log_type_error CONSTANT VARCHAR2(10) := 'ERROR';

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_WORKFLOW_ACTIVITY_LOG
  -- purpose:       Get workflow_activity log
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_workflow_activity_log(p_id_workflow_instance    IN VARCHAR2,
                                     p_dtime_start             IN DATE DEFAULT NULL,
                                     p_dtime_end               IN DATE DEFAULT NULL,
                                     p_date_effective          IN DATE DEFAULT NULL,
                                     p_display_additional_info IN VARCHAR2 DEFAULT NULL) RETURN owner_wfm.lib_etl_workflow_api.tt_workflow_activity_log PIPELINED
  IS

    a_workflow_activity_log  owner_wfm.lib_etl_workflow_api.tt_workflow_activity_log;
    t_workflow_activity_log  owner_wfm.lib_etl_workflow_api.t_workflow_activity_log;

    ex_uninitialized_collection EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_uninitialized_collection, -06531);
                            
  BEGIN
    
    -- Reset record
    t_workflow_activity_log := NULL;
    
    -- Get workflow activity log 
    owner_wfm.lib_etl_workflow_api.get_workflow_activity_log(p_id_workflow_instance    => p_id_workflow_instance,
                                                             p_date_effective          => p_date_effective,
                                                             p_display_additional_info => p_display_additional_info,
                                                             p_workflow_activity_log   => a_workflow_activity_log);

    -- If the array is not empty
    IF a_workflow_activity_log.count > 0 THEN

       -- Loop throught array
       FOR i IN a_workflow_activity_log.first .. a_workflow_activity_log.last  
       LOOP
         
         -- Set output record
         t_workflow_activity_log.id_workflow_activity      := a_workflow_activity_log(i).id_workflow_activity;
         t_workflow_activity_log.name_activity_type        := a_workflow_activity_log(i).name_activity_type;
         t_workflow_activity_log.name_activity             := a_workflow_activity_log(i).name_activity;
         t_workflow_activity_log.dtime_start               := a_workflow_activity_log(i).dtime_start;
         t_workflow_activity_log.dtime_end                 := a_workflow_activity_log(i).dtime_end;
         t_workflow_activity_log.code_status               := a_workflow_activity_log(i).code_status;
         t_workflow_activity_log.duration                  := a_workflow_activity_log(i).duration;
         t_workflow_activity_log.text_message              := a_workflow_activity_log(i).text_message;
         PIPE ROW(t_workflow_activity_log);
       
       END LOOP;
       
    END IF;  

    -- Return result
    RETURN;
    
  EXCEPTION
    WHEN ex_uninitialized_collection THEN
      -- Ignore error in case of reference to uninitialized collection
      NULL;
    WHEN OTHERS THEN
      RAISE;
  
  END get_workflow_activity_log;    

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_WORKFLOW_LIST
  -- purpose:       Get workflow list for given main workflow process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_workflow_list(p_name_process IN VARCHAR2) RETURN owner_wfe.lib_wf_diagram_api.tt_workflow_list PIPELINED IS

    v_name_workflow          VARCHAR2(255);
    
    a_workflow_list          owner_wfe.lib_wf_diagram_api.tt_workflow_list;
    t_workflow_list          owner_wfe.lib_wf_diagram_api.t_workflow_list;

    ex_uninitialized_collection EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_uninitialized_collection, -06531);
  
  BEGIN
    
    -- Get workflow name
    SELECT 
       name_workflow
      INTO
       v_name_workflow
    FROM owner_wfm.etl_process
    WHERE name_process = p_name_process;

    -- Return workflow list for given main workflow process
    a_workflow_list := owner_wfm.lib_etl_workflow_extension_api.get_workflow_list(p_name_workflow => v_name_workflow);
    
    -- If the array is not empty
    IF a_workflow_list.count > 0 THEN

       -- Loop throught array
       FOR i IN a_workflow_list.first .. a_workflow_list.last  
       LOOP
         
         -- Set output record
         t_workflow_list.id_workflow_definition := a_workflow_list(i).id_workflow_definition;
         t_workflow_list.name_workflow          := a_workflow_list(i).name_workflow;
         t_workflow_list.name_workflow_super    := a_workflow_list(i).name_workflow_super;
         t_workflow_list.text_path              := a_workflow_list(i).text_path;
         t_workflow_list.num_level              := a_workflow_list(i).num_level;
         t_workflow_list.num_version            := a_workflow_list(i).num_version;
         t_workflow_list.code_status            := a_workflow_list(i).code_status;
         t_workflow_list.dtime_valid_from       := a_workflow_list(i).dtime_valid_from;
         t_workflow_list.dtime_valid_to         := a_workflow_list(i).dtime_valid_to;
         t_workflow_list.user_inserted          := a_workflow_list(i).user_inserted;
         t_workflow_list.name_deployment        := a_workflow_list(i).name_deployment;         
         PIPE ROW(t_workflow_list);  
       
       END LOOP;
       
    END IF;  

    -- Return result
    RETURN;
    
  EXCEPTION
    WHEN ex_uninitialized_collection THEN
      -- Ignore error in case of reference to uninitialized collection
      NULL;
    WHEN OTHERS THEN
      RAISE;

  END get_workflow_list;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_WORKFLOW
  -- purpose:        Get workflow definition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_workflow(p_id_workflow_definition IN INTEGER DEFAULT NULL,
                         p_name_workflow          IN VARCHAR2 DEFAULT NULL,
                         p_text_workflow          OUT CLOB,
                         p_text_message           OUT VARCHAR2) IS
                         
    c_proc_name            VARCHAR2(30) := 'GET_WORKFLOW';
        
  BEGIN

    -- Get workflow definition
    owner_wfm.lib_etl_workflow_extension_api.get_workflow(p_id_workflow_definition => p_id_workflow_definition,
                                                          p_name_workflow          => p_name_workflow,
                                                          p_text_workflow          => p_text_workflow);

  EXCEPTION
    WHEN OTHERS THEN  
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||': '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
  
  END get_workflow;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_EXEC_WORKFLOW
  -- purpose:        Get executed workflow definition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_exec_workflow(p_id_workflow_instance IN INTEGER DEFAULT NULL,
                              p_id_workflow_activity IN INTEGER DEFAULT NULL,                       
                              p_date_effective       IN DATE,
                              p_text_workflow        OUT CLOB,
                              p_text_message         OUT VARCHAR2) IS
                              
    c_proc_name            VARCHAR2(30) := 'GET_EXEC_WORKFLOW';
    
  BEGIN
    
    -- Get executed workflow definition
    owner_wfm.lib_etl_workflow_extension_api.get_exec_workflow(p_id_workflow_instance => p_id_workflow_instance,
                                                               p_id_workflow_activity => p_id_workflow_activity,
                                                               p_date_effective       => p_date_effective,
                                                               p_text_workflow        => p_text_workflow);

  EXCEPTION
    WHEN OTHERS THEN  
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||': '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
  
  END get_exec_workflow;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_RUNNING_ACTIVITY_INFO
  -- purpose:        Get information aabout running activity
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_running_activity_info(p_id_process_instance  IN INTEGER,
                                      p_id_workflow_activity IN VARCHAR2,
                                      p_date_effective       OUT DATE,
                                      p_id_instance          OUT NUMBER,
                                      p_id_session           OUT NUMBER,
                                      p_id_serial            OUT NUMBER)
  IS
  
    v_id_audit_session NUMBER;
                            
  BEGIN
    
    -- Get information from wf running activity
    BEGIN
      
      SELECT
         date_effective,
         id_instance,
         id_session,
         id_audit_session
        INTO
         p_date_effective,
         p_id_instance,
         p_id_session,
         v_id_audit_session 
      FROM owner_wfm.etl_wf_running_activity
      WHERE id_process_instance = p_id_process_instance 
        AND id_workflow_activity = p_id_workflow_activity;
        
    EXCEPTION 
      WHEN no_data_found THEN
        -- Set result to NULL
        p_date_effective       := NULL;
        p_id_instance          := NULL;
        p_id_session           := NULL;
        p_id_serial            := NULL;
        
    END;
    
    -- If the audit session id variable is not null then get additional session info
    IF v_id_audit_session IS NOT NULL THEN
      
      -- Get session serial
      BEGIN
        
        SELECT
           serial#
          INTO
           p_id_serial     
        FROM sys.gv_$session
        WHERE inst_id = p_id_instance
          AND sid = p_id_session
          AND audsid = v_id_audit_session;
      
      EXCEPTION 
        WHEN OTHERS THEN
          -- Set additional result to NULL
          p_id_serial            := NULL;
        
    END;
    
    END IF;
  
  END get_running_activity_info;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_RUNNING_ACTIVITY_SQL
  -- purpose:        Get sql text and plan for running activity
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE get_running_activity_sql(p_id_process_instance  IN INTEGER,
                                     p_id_workflow_activity IN VARCHAR2,
                                     p_text_sql             OUT CLOB,
                                     p_text_sql_plan        OUT CLOB,
                                     p_text_message         OUT VARCHAR2)
  IS
  
    c_proc_name            VARCHAR2(30) := 'GET_RUNNING_ACTIVITY_SQL';
    v_step                 VARCHAR2(500); 
    v_date_effective       DATE;
    v_id_instance          NUMBER;
    v_id_session           NUMBER;
    v_id_serial            NUMBER;
    
  BEGIN
      
    -- Get session information about running activity
    v_step := 'Get session information about running activity';
    get_running_activity_info(p_id_process_instance  => p_id_process_instance,
                              p_id_workflow_activity => p_id_workflow_activity,
                              p_date_effective       => v_date_effective,
                              p_id_instance          => v_id_instance,
                              p_id_session           => v_id_session,
                              p_id_serial            => v_id_serial);
    
   
    -- If session information was successfully retrieved
    IF v_id_instance IS NOT NULL 
        AND v_id_session IS NOT NULL 
        AND v_id_serial IS NOT NULL THEN
      
      -- Get sql information for running activity
      v_step := 'Get sql information for running activity';
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
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
                                                    
  END get_running_activity_sql; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_RUNNING_ACTIVITY_SQL_AI
  -- purpose:        Get sql additional information for running activity
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE get_running_activity_sql_ai(p_id_process_instance  IN INTEGER,
                                        p_id_workflow_activity IN VARCHAR2,
                                        p_id_instance          OUT NUMBER,
                                        p_id_sql               OUT VARCHAR2,
                                        p_text_message         OUT VARCHAR2)
  IS
  
    c_proc_name            VARCHAR2(30) := 'GET_RUNNING_ACTIVITY_SQL_AI';
    v_step                 VARCHAR2(500); 
    v_date_effective       DATE;
    v_id_instance          NUMBER;
    v_id_session           NUMBER;
    v_id_serial            NUMBER;
    
  BEGIN
      
    -- Get session information about running activity
    v_step := 'Get session information about running activity';
    get_running_activity_info(p_id_process_instance  => p_id_process_instance,
                              p_id_workflow_activity => p_id_workflow_activity,
                              p_date_effective       => v_date_effective,
                              p_id_instance          => v_id_instance,
                              p_id_session           => v_id_session,
                              p_id_serial            => v_id_serial);
    
   
    -- If session information was successfully retrieved
    IF v_id_instance IS NOT NULL 
        AND v_id_session IS NOT NULL 
        AND v_id_serial IS NOT NULL THEN
        
      -- Set instance id
      p_id_instance := v_id_instance;
      
      -- Get sql id
      v_step := 'Get sql id';
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
                                                    
  END get_running_activity_sql_ai; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_PROCESS_DETAIL
  -- purpose:        Get detailed info for process p_id_process
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE get_process_detail(p_id_process              IN INTEGER,
                               p_date_effective_selected IN DATE,
                               p_date_effective_next     OUT DATE,
                               p_text_detail             OUT CLOB, 
                               p_text_message            OUT VARCHAR2)
  IS 

    c_proc_name        VARCHAR2(30) := 'GET_RUNNING_ACTIVITY_SQL_AI';
    v_step             VARCHAR2(500); 
    v_dtime_start_new  DATE := SYSDATE;
    a_process          owner_wfm.lib_etl_process_run.tt_process;
    v_result           BOOLEAN;
    v_text_message_out CLOB;
    v_text_message     VARCHAR2(4000);
      
  BEGIN


  -- Get process info
  v_step := 'Get process info';
  owner_wfm.lib_etl_process_run.get_process_info(p_dtime_start_new => v_dtime_start_new, 
                                                 p_process         => a_process);

  -- Get new date effective
  v_step := 'Get new date effective';
  owner_wfm.lib_etl_process_run.get_process_date_effective(p_id_process => p_id_process, 
                                                           p_process => a_process);  
  --set new date_effective  
  p_date_effective_next := NVL(a_process(p_id_process).date_effective_new, trunc(sysdate));

  IF p_date_effective_selected IS NOT NULL THEN 
    a_process(p_id_process).date_effective_new := p_date_effective_selected;
  END IF;

  --process detail
  v_step := 'Get process detail';
    WITH process_window AS (
      SELECT 
        code_process_window, 
        listagg(to_char(dtime_start_from,'DD.MM.YYYY HH24:MI:SS')||' - '||to_char(dtime_start_to,'DD.MM.YYYY HH24:MI:SS'),CHR(10)) WITHIN GROUP (ORDER BY num_order DESC) as text_window_period 
      FROM owner_wfm.etl_process_window
      -- Process window is not deleted
      WHERE flag_deleted = 'N'
      GROUP BY code_process_window
    )
    SELECT
      'Process severity: '||num_process_severity||CHR(10)||
      'Process window: '||code_process_window||' ('||text_window_period||')'||CHR(10)||      
      'Last sucessfull run: '||to_char(MAX(date_effective_complete),'DD.MM.YYYY HH24:MI:SS')||CHR(10)||
      'Average duration (Last30D): '||TRUNC(AVG(CASE WHEN flag_restart = 'N' THEN num_duration_min END))||'min'
      INTO v_text_message      
    FROM ( 
        SELECT 
          p.id_process, 
          p.num_process_severity, 
          p.code_process_window, 
          pw.text_window_period,
          CASE WHEN code_status = 'COMPLETE' THEN date_effective ELSE NULL END AS date_effective_complete,
          pi.date_effective,
          pi.code_status,
          pi.flag_restart,
          pi.dtime_end, pi.dtime_start,
          (pi.dtime_end - pi.dtime_start)*24*60 AS num_duration_min      
        FROM owner_wfm.etl_process p
        JOIN process_window pw ON p.code_process_window = pw.code_process_window
        LEFT JOIN owner_wfm.etl_process_instance pi
          ON pi.id_process = p.id_process  
         AND pi.date_effective BETWEEN p_date_effective_next-30 AND p_date_effective_next
        WHERE p.id_process = p_id_process
    )
    GROUP BY 
      id_process, 
      num_process_severity,
      code_process_window,
      text_window_period;

  v_text_message_out := v_text_message;
  v_text_message := NULL;

  v_step := 'Get date effective conditions';
  owner_wfm.lib_etl_process_run.check_dateeff_conditions(p_id_process     => p_id_process,
                                                         p_process        => a_process,
                                                         p_flag_check_all => c_flag_y,
                                                         p_text_message   => v_text_message,
                                                         p_result         => v_result);

  IF v_text_message IS NOT NULL THEN   
    v_text_message := CHR(10)||'Precondition check - effective date: '||CHR(10)||v_text_message; 
  END IF;  
  
  v_text_message_out := v_text_message_out||CHR(10)||v_text_message;
  v_text_message := NULL;
  
  v_step := 'Get process conditions';
  owner_wfm.lib_etl_process_run.check_process_conditions(p_id_process        => p_id_process,
                                                         p_process           => a_process,
                                                         p_flag_manual_start => c_flag_y,
                                                         p_flag_check_all    => c_flag_y,
                                                         p_text_message      => v_text_message,
                                                         p_result            => v_result); 

  IF v_text_message IS NOT NULL THEN   
    v_text_message := 'Precondition check - runconditions: '||CHR(10)||v_text_message; 
  END IF;  
  
  v_text_message_out := v_text_message_out||CHR(10)||v_text_message;

  p_text_detail := v_text_message_out;

  EXCEPTION
    WHEN OTHERS THEN  
      -- Rollback
      ROLLBACK;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);

  END get_process_detail;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_START_GROUP
  -- purpose:        Set process start group
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE set_start_group(p_code_start_group_category IN VARCHAR2 DEFAULT NULL,
                            p_code_start_group          IN VARCHAR2 DEFAULT NULL,
                            p_flag_active               IN VARCHAR2,
                            p_text_message              OUT VARCHAR2)
  IS

  BEGIN

    -- Set process start group
    IF p_code_start_group_category IS NOT NULL THEN 
      
      UPDATE owner_wfm.etl_process_group 
         SET flag_active = p_flag_active
      WHERE code_start_group_category = p_code_start_group_category;
    
    ELSE 
      
      UPDATE owner_wfm.etl_process_group 
         SET flag_active = p_flag_active
      WHERE code_start_group = p_code_start_group;

    END IF;
    
    -- Commit
    COMMIT;
    
    -- Set output message
    p_text_message := 'Start group'||
                         CASE WHEN p_code_start_group_category IS NOT NULL THEN ' category' END||
                         ' is now '||CASE WHEN p_flag_active = c_flag_y THEN 'active' ELSE 'inactive' END;
                                                  
  END set_start_group; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ACTIVATE_START_GROUP
  -- purpose:        Activate process start group
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE activate_start_group(p_code_start_group IN VARCHAR2,
                                 p_text_message     OUT VARCHAR2)
  IS

  BEGIN
    
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_activate_start_group(p_code_start_group, p_text_message)
    THEN
      RETURN;
    END IF;

    -- Activate process start group
    set_start_group(p_code_start_group => p_code_start_group,
                    p_flag_active      => c_flag_y,
                    p_text_message     => p_text_message);
                                                  
  END activate_start_group;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEACTIVATE_START_GROUP
  -- purpose:        Deactivate process start group
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE deactivate_start_group(p_code_start_group IN VARCHAR2,
                                   p_text_message     OUT VARCHAR2)
  IS

  BEGIN
    
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_deactivate_start_group(p_code_start_group, p_text_message)
    THEN
      RETURN;
    END IF;

    -- Deactivate process start group
    set_start_group(p_code_start_group => p_code_start_group,
                    p_flag_active      => c_flag_n,
                    p_text_message     => p_text_message);
                                                  
  END deactivate_start_group; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ACTIVATE_START_GROUP_ALL
  -- purpose:        Activate all process start groups for given category
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE activate_start_group_all(p_code_start_group_category IN VARCHAR2,
                                     p_text_message              OUT VARCHAR2)
  IS

  BEGIN
    
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_activate_start_group_all(p_code_start_group_category, p_text_message)
    THEN
      RETURN;
    END IF;

    -- Activate process start group
    set_start_group(p_code_start_group_category => p_code_start_group_category,
                    p_flag_active               => c_flag_y,
                    p_text_message              => p_text_message);
                                                  
  END activate_start_group_all;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEACTIVATE_START_GROUP_ALL
  -- purpose:        Deactivate all process start groups for given category
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE deactivate_start_group_all(p_code_start_group_category IN VARCHAR2,
                                       p_text_message              OUT VARCHAR2)
  IS

  BEGIN
    
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_deactivate_start_group_all(p_code_start_group_category, p_text_message)
    THEN
      RETURN;
    END IF;

    -- Deactivate process start group
    set_start_group(p_code_start_group_category => p_code_start_group_category,
                    p_flag_active               => c_flag_n,
                    p_text_message              => p_text_message);
                                                  
  END deactivate_start_group_all;
    
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CANCEL_PROCESS
  -- purpose:        Cancel specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE cancel_process(p_id_process_instance IN INTEGER,
                           p_text_message        OUT VARCHAR2)
  IS
    
  BEGIN
      
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_cancel_process(p_id_process_instance, p_text_message)
    THEN
        RETURN;
    END IF;

    -- Cancel proces
    owner_wfm.lib_etl_process_run.cancel_process(p_id_process_instance => p_id_process_instance,
                                                 p_text_message        => p_text_message);
    
  END cancel_process;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SUSPEND_PROCESS
  -- purpose:        Suspend specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE suspend_process(p_id_process_instance IN INTEGER,
                            p_text_message        OUT VARCHAR2)
  IS
        
  BEGIN
      
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_suspend_process(p_id_process_instance, p_text_message) THEN
      RETURN;
    END IF;
     
    -- Suspend process
    owner_wfm.lib_etl_process_run.suspend_process(p_id_process_instance => p_id_process_instance,
                                                  p_text_message        => p_text_message);
                                   
  END suspend_process;  

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESUME_PROCESS
  -- purpose:        Resume specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE resume_process(p_id_process_instance IN INTEGER,
                           p_text_message        OUT VARCHAR2)
  IS
        
  BEGIN
      
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_resume_process(p_id_process_instance, p_text_message)
    THEN
      RETURN;
    END IF;
    
    -- Resume process
    owner_wfm.lib_etl_process_run.resume_process(p_id_process_instance => p_id_process_instance,
                                                 p_text_message        => p_text_message);
                                 
  END resume_process;  
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_PROCESS
  -- purpose:        Restart specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE restart_process(p_id_process_instance IN INTEGER,
                            p_text_message        OUT VARCHAR2)
  IS
        
  BEGIN
      
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_restart_process(p_id_process_instance, p_text_message) THEN
      RETURN;
    END IF;
     
    -- Restart process
    owner_wfm.lib_etl_process_run.restart_process(p_id_process_instance => p_id_process_instance,
                                                  p_text_message        => p_text_message);
                                                   
  END restart_process;  
    
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_PROCESS
  -- purpose:        Start specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_process(p_name_process   IN VARCHAR2,
                          p_date_effective IN DATE,
                          p_text_message   OUT VARCHAR2)
  IS

  BEGIN
      
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_start_process(p_name_process, p_text_message) THEN
      RETURN;
    END IF;
    
    -- Start process
    owner_wfm.lib_etl_process_run.start_process_manual(p_name_process   => p_name_process,
                                                       p_date_effective => p_date_effective,
                                                       p_text_message   => p_text_message);
                                                                                                           
  END start_process; 
    
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SKIP_ACTIVITY
  -- purpose:        Skip activity for specified process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE skip_activity(p_id_process_instance  IN INTEGER,
                          p_id_workflow_activity IN VARCHAR2,
                          p_name_activity        IN VARCHAR2,
                          p_text_message         OUT VARCHAR2)
  IS

  BEGIN
      
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_skip_activity(p_id_process_instance, p_text_message) THEN
      RETURN;
    END IF;
      
    -- Skip activity
    owner_wfm.lib_etl_process_run.skip_activity(p_id_process_instance  => p_id_process_instance,
                                                p_id_workflow_activity => p_id_workflow_activity,
                                                p_name_activity        => p_name_activity,
                                                p_text_message         => p_text_message);

  EXCEPTION 
    WHEN OTHERS THEN 
      -- Suppress error send just message via out parameter
      NULL;
                                                                                                 
  END skip_activity; 
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: KILL_ACTIVITY
  -- purpose:        Kill activity for specified process
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE kill_activity(p_id_process_instance  IN INTEGER,
                          p_id_workflow_activity IN VARCHAR2,
                          p_name_activity        IN VARCHAR2,
                          p_text_message         OUT VARCHAR2)
  IS
  
    c_proc_name            VARCHAR2(30) := 'KILL_ACTIVITY';
    v_step                 VARCHAR2(500); 
    v_date_effective       DATE;
    v_id_instance          NUMBER;
    v_id_session           NUMBER;
    v_id_serial            NUMBER;
    
  BEGIN

    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_kill_activity(p_id_process_instance, p_text_message) THEN
      RETURN;
    END IF;
      
    -- Get information about running activity
    v_step := 'Get information about running activity';
    get_running_activity_info(p_id_process_instance  => p_id_process_instance,
                              p_id_workflow_activity => p_id_workflow_activity,
                              p_date_effective       => v_date_effective,
                              p_id_instance          => v_id_instance,
                              p_id_session           => v_id_session,
                              p_id_serial            => v_id_serial);
                                  
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
      
      -- Log message for process activity
      v_step := 'Log message for process activity';
      -- Set message
      p_text_message := 'Activity has been killed!';
      -- Log process activity
      owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => v_date_effective,
                                                     p_id_process_instance  => p_id_process_instance,
                                                     p_id_workflow_activity => p_id_workflow_activity,
                                                     p_name_module          => p_name_activity,
                                                     p_name_activity        => c_proc_name,                         
                                                     p_text_message         => p_text_message); 
    
    -- Otherwise ...                     
    ELSE
      
      -- Set message
      p_text_message := 'Activity cannot be killed, because it was not possible to retrieve session information!';
    
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN  
      -- Rollback
      ROLLBACK;
      -- Set message
      p_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => p_text_message);
                                                    
  END kill_activity; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_ACTIVITY
  -- purpose:        Restart activity for specified process
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE restart_activity(p_id_process_instance  IN INTEGER,
                             p_id_workflow_activity IN VARCHAR2,
                             p_name_activity        IN VARCHAR2,
                             p_text_message         OUT VARCHAR2)
  IS

  BEGIN

    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_restart_process(p_id_process_instance, p_text_message) THEN
      RETURN;
    END IF;

    -- Restart activity
    owner_wfm.lib_etl_process_run.restart_activity(p_id_process_instance  => p_id_process_instance,
                                                   p_id_workflow_activity => p_id_workflow_activity,
                                                   p_name_activity        => p_name_activity,
                                                   p_text_message         => p_text_message);
                                                  
  END restart_activity; 
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: UNSTUCK_ACTIVITY
  -- purpose:        Cancel activity and start before/after some element in camunda worfkflow engine (use only in emergency situation (stuck workflow), it can cause to unforeseen circumstances)
  -- parameters:
  --   P_ID_PROCESS_INSTANCE        - Id of process instance which will be modified      
  --   P_ID_WORKFLOW_ACTIVITY       - Id of workflow activity which needs to be canceled (stuck subprocess)
  --   P_NAME_ACTIVITY              - Name of workflow activity which needs to be canceled (stuck subprocess)
  --   P_CODE_ACTIVITY_START_TYPE   - Code of activity start type (supposerted options are START_BEFORE and START_AFTER
  --   P_ID_WORKFLOW_ELEMENT_START  - Id of workflow element (from workflow definition) before/after which should workflow start/continue
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE unstuck_activity(p_id_process_instance       IN INTEGER,
                             p_id_workflow_activity      IN VARCHAR2,
                             p_name_activity             IN VARCHAR2,
                             p_code_activity_start_type  IN VARCHAR2,
                             p_id_workflow_element_start IN VARCHAR2,
                             p_text_message              OUT VARCHAR2)
  IS
    
  BEGIN
    
    -- Check privilege
    IF NOT owner_wfm.lib_etl_application_privilege.can_unstuck_activity(p_id_process_instance, p_text_message) THEN
      RETURN;
    END IF;

    -- Unstuck activity
    owner_wfm.lib_etl_process_run.unstuck_activity(p_id_process_instance       => p_id_process_instance,
                                                   p_id_workflow_activity      => p_id_workflow_activity,
                                                   p_name_activity             => p_name_activity,
                                                   p_code_activity_start_type  => p_code_activity_start_type,
                                                   p_id_workflow_element_start => p_id_workflow_element_start,
                                                   p_text_message              => p_text_message);
                                                                                                 
  END unstuck_activity;     

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: MANUAL_CONFIRM_LOG
  -- purpose:        Manual confirmation of record in monitoring log -> set status = 'COMPLETE', flag_confirmed = 'Y'
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE manual_confirm_log(p_id             IN NUMBER,
                               p_date_effective IN DATE,
                               p_text_message   OUT VARCHAR2)
  IS
  BEGIN
      -- Check privilege
      IF NOT owner_wfm.lib_etl_application_privilege.can_manual_confirm_log(p_id, p_text_message)
      THEN
          RETURN;
      END IF;
      
     -- Manual confirmation of record
     owner_wfm.lib_etl_monitoring_log_api.confirm_error(p_date_effective => p_date_effective,
                                                        p_id             => p_id);
                                                             
     p_text_message:= 'Confirmed';
     
  END manual_confirm_log; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CONFIRM_FLAG_SEND
  -- purpose:        Confirm record in monitoring log, set FLAG_SEND = 'Y', Email has been sent to ServiceDesk or called emergency
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE confirm_flag_send(p_id             IN NUMBER,
                              p_date_effective IN DATE,
                              p_text_message   OUT VARCHAR2)
  IS
  BEGIN

     -- Manual confirmation of record
     owner_wfm.lib_etl_monitoring_log_api.set_error_sent(p_id             => p_id,
                                                         p_date_effective => p_date_effective);
     p_text_message:= 'Confirmed';

  END confirm_flag_send; 

    
END lib_etl_process_run_api;
/
