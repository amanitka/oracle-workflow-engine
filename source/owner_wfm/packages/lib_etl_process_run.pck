CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_process_run IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 15.3.2018
  -- purpose: Sartup of the processes
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------
  c_flag_n                 CONSTANT VARCHAR2(1)  := 'N';
  
  TYPE t_process_parameter IS RECORD 
   (
    name_parameter VARCHAR2(30),
    text_value     VARCHAR2(255) 
   );  

  TYPE tt_process_parameter IS TABLE OF t_process_parameter INDEX BY BINARY_INTEGER;

  TYPE t_process IS RECORD 
   (
    id_process                 INTEGER,
    name_process               VARCHAR2(30),
    name_workflow              VARCHAR2(30),
    num_process_priority       INTEGER,
    code_process_group         VARCHAR2(30),
    code_process_window        VARCHAR2(20),
    flag_multiple_start        VARCHAR2(1),
    code_start_method          VARCHAR2(30),
    code_start_interval        VARCHAR2(30),
    code_date_effective_method VARCHAR2(30),
    process_parameter          tt_process_parameter,
    date_effective_max         DATE,
    id_process_instance_new    INTEGER,
    id_workflow_instance_new   VARCHAR2(100),
    date_effective_new         DATE,
    dtime_start_new            DATE,
    flag_start_window          VARCHAR2(1),
    id_process_instance_curr   INTEGER,
    id_workflow_instance_curr  VARCHAR2(100),
    date_effective_curr        DATE,
    dtime_start_curr           DATE,
    dtime_end_curr             DATE,
    code_status_curr           VARCHAR2(10), 
    flag_first_start           VARCHAR2(1),
    flag_active                VARCHAR2(1),
    flag_deleted               VARCHAR2(1)
   );

  TYPE t_process_instance IS RECORD 
   (
    name_process               VARCHAR2(30),
    id_workflow_instance       VARCHAR2(100),
    date_effective             DATE,
    dtime_start                DATE  
   );  
   
  TYPE tt_process IS TABLE OF t_process INDEX BY BINARY_INTEGER;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_PROCESS_INFO
  -- purpose:       
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_process_info(p_dtime_start_new IN DATE,
                             p_process         OUT tt_process);
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_PROCESS_DATE_EFFECTIVE
  -- purpose:        Set new date effective for the process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_process_date_effective(p_id_process IN INTEGER,        
                                       p_process    IN OUT tt_process);
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_PROCESS_INSTANCE_PAR
  -- purpose:        Get parameter value for given process instance and parameter name
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_process_instance_par(p_id_process_instance IN INTEGER,  
                                     p_date_effective      IN DATE,
                                     p_name_parameter      IN VARCHAR2,
                                     p_text_value          OUT VARCHAR2);
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: Check basic conditions
  -- purpose:       
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_basic_conditions(p_id_process        IN INTEGER,
                                   p_process           IN tt_process,
                                   p_flag_manual_start IN VARCHAR2,
                                   p_text_message      OUT VARCHAR2,
                                   p_result            OUT BOOLEAN);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: Check date effective conditions
  -- purpose:       
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_dateeff_conditions(p_id_process       IN INTEGER,
                                     p_process          IN tt_process,
                                     p_flag_check_all   IN VARCHAR2 DEFAULT c_flag_n,
                                     p_text_message     OUT VARCHAR2,
                                     p_result           OUT BOOLEAN);
                                    
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: Check process conditions
  -- purpose:       
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_process_conditions(p_id_process        IN INTEGER,
                                     p_process           IN tt_process,
                                     p_flag_manual_start IN VARCHAR2,
                                     p_flag_check_all    IN VARCHAR2 DEFAULT c_flag_n,
                                     p_text_message      OUT VARCHAR2,
                                     p_result            OUT BOOLEAN);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: Check process status
  -- purpose:        Check current process status right before start of process (bug with multiple process start when called in parallel)
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_process_status(p_id_process   IN INTEGER,
                                 p_process      IN OUT tt_process,
                                 p_text_message OUT VARCHAR2,
                                 p_result       OUT BOOLEAN);
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_START_CONDITIONS_WF
  -- purpose:        Check start conditions inside of started process (called from workflow)
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_start_conditions_wf(p_process_key    IN INTEGER,
                                      p_effective_date IN DATE,
                                      p_data_type      IN VARCHAR2);

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
  -- procedure name: ERROR_PROCESS
  -- purpose:        Set error for specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE error_process(p_id_process_instance IN INTEGER);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: STUCK_PROCESS
  -- purpose:        Set stuck for specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE stuck_process(p_id_process_instance IN INTEGER);
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: COMPLETE_PROCESS
  -- purpose:        Complete specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE complete_process(p_id_process_instance IN INTEGER);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: COMPLETE_PROCESS
  -- purpose:        Complete specified process from workflow
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE complete_process_wf(p_process_key    IN INTEGER,
                                p_effective_date IN DATE,
                                p_data_type      IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SKIP_ACTIVITY
  -- purpose:        Skip activity for specified process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE skip_activity(p_id_process_instance  IN INTEGER,
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
  -- procedure name: START_PROCESS
  -- purpose:                                      
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_process(p_id_process IN INTEGER,        
                          p_process    IN OUT tt_process);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_PROCESS_AUTO
  -- purpose:        Autostart of all processes
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_process_auto;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_PROCESS_MANUAL
  -- purpose:        Manual start of process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_process_manual(p_name_process   IN VARCHAR2,
                                 p_date_effective IN DATE,
                                 p_text_message   OUT VARCHAR2); 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_PROCESS_WF
  -- purpose:        Start specified process from workflow
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_process_wf(p_process_key    IN INTEGER,
                             p_effective_date IN DATE,
                             p_data_type      IN VARCHAR2);

END lib_etl_process_run;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_process_run IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_mod_name                  CONSTANT VARCHAR2(30) := 'LIB_ETL_PROCESS_RUN';    
  c_flag_y                    CONSTANT VARCHAR2(1)  := 'Y';
  c_xna                       CONSTANT VARCHAR2(3)  := 'XNA';
  c_status_new                CONSTANT VARCHAR2(10) := 'NEW';
  c_status_running            CONSTANT VARCHAR2(10) := 'RUNNING';
  c_status_complete           CONSTANT VARCHAR2(10) := 'COMPLETE';
  c_status_cancel             CONSTANT VARCHAR2(10) := 'CANCEL';
  c_status_error              CONSTANT VARCHAR2(10) := 'ERROR';
  c_status_restart            CONSTANT VARCHAR2(10) := 'RESTART';
  c_status_suspend            CONSTANT VARCHAR2(10) := 'SUSPEND';
  c_status_resume             CONSTANT VARCHAR2(10) := 'RESUME';
  c_status_skip               CONSTANT VARCHAR2(10) := 'SKIP';
  c_status_stuck              CONSTANT VARCHAR2(10) := 'STUCK';
  c_status_unstuck            CONSTANT VARCHAR2(10) := 'UNSTUCK';
  c_autorun_method            CONSTANT VARCHAR2(30) := 'AUTORUN';
  c_autorun_transfer_method   CONSTANT VARCHAR2(30) := 'AUTORUN_TRANSFER';
  c_start_int_anytime         CONSTANT VARCHAR2(30) := 'ANYTIME';
  c_start_int_hour            CONSTANT VARCHAR2(30) := 'ONCE_HOUR';
  c_start_int_odd_hour        CONSTANT VARCHAR2(30) := 'ONCE_ODD_HOUR';
  c_start_int_even_hour       CONSTANT VARCHAR2(30) := 'ONCE_EVEN_HOUR'; 
  c_start_int_ten_minutes     CONSTANT VARCHAR2(30) := 'ONCE_TEN_MINUTES';
  c_start_int_thirty_minutes  CONSTANT VARCHAR2(30) := 'ONCE_THIRTY_MINUTES';
  c_start_deffmth_nextpl      CONSTANT VARCHAR2(30) := 'NEXT_PLANNED_DATE'; 
  c_start_deffmth_curr        CONSTANT VARCHAR2(30) := 'CURRENT_DATE'; 
  c_start_deffmth_refinc      CONSTANT VARCHAR2(30) := 'REFR_INCR_DATE'; 
  c_date_mask                 CONSTANT VARCHAR2(10) := 'DD.MM.YYYY';
  c_day_mask                  CONSTANT VARCHAR2(10) := 'DD';
  c_hh24_mask                 CONSTANT VARCHAR2(10) := 'HH24';
  c_min_mask                  CONSTANT VARCHAR2(10) := 'MI';
  c_log_type_message          CONSTANT VARCHAR2(10) := 'MESSAGE';
  c_log_type_error            CONSTANT VARCHAR2(10) := 'ERROR';
  c_activity_start_before     CONSTANT VARCHAR2(30) := 'START_BEFORE';
  c_activity_start_after      CONSTANT VARCHAR2(30) := 'START_AFTER'; 
  
  c_date_future               CONSTANT DATE := DATE'3000-01-01';  
  v_text_message              VARCHAR2(4000);
  c_name_user                 CONSTANT VARCHAR2(60) := CASE WHEN SYS_CONTEXT('USERENV', 'PROXY_USER') IS NULL THEN SYS_CONTEXT('USERENV', 'SESSION_USER')
                                                            ELSE SYS_CONTEXT('USERENV', 'PROXY_USER') ||'['|| SYS_CONTEXT('USERENV', 'SESSION_USER')||']'
                                                       END;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_PROCESS_INSTANCE
  -- purpose:        
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_process_instance(p_id_process IN INTEGER,        
                                 p_process    IN OUT tt_process)
  IS

    c_proc_name CONSTANT VARCHAR2(30) := 'SET_PROCESS_INSTANCE';  
    c_sysdate   CONSTANT DATE := SYSDATE;
    v_step      VARCHAR2(500);
    
  BEGIN

    -- Set process instance
    v_step := 'Set process instance';
    INSERT INTO owner_wfm.etl_process_instance
      (id_process, 
       id_process_instance, 
       id_workflow_instance,
       name_process, 
       date_effective, 
       dtime_start, 
       dtime_end, 
       code_status, 
       flag_restart, 
       dtime_inserted, 
       user_inserted, 
       dtime_updated, 
       user_updated)
    VALUES
      (p_id_process, 
       p_process(p_id_process).id_process_instance_new, 
       p_process(p_id_process).id_workflow_instance_new, 
       p_process(p_id_process).name_process, 
       p_process(p_id_process).date_effective_new, 
       p_process(p_id_process).dtime_start_new, 
       c_date_future, 
       NULL, 
       c_flag_n, 
       c_sysdate, 
       c_name_user, 
       c_sysdate, 
       c_name_user);
    
    -- Set process status
    v_step := 'Set process status';   
    MERGE INTO owner_wfm.etl_process_status t
    USING (SELECT
              p_id_process                                     AS id_process, 
              p_process(p_id_process).id_process_instance_new  AS id_process_instance, 
              p_process(p_id_process).id_workflow_instance_new AS id_workflow_instance, 
              p_process(p_id_process).name_process             AS name_process, 
              p_process(p_id_process).name_workflow            AS name_workflow, 
              p_process(p_id_process).date_effective_new       AS date_effective, 
              p_process(p_id_process).dtime_start_new          AS dtime_start, 
              c_date_future                                    AS dtime_end, 
              c_status_new                                     AS code_status, 
              c_flag_n                                         AS flag_restart, 
              c_sysdate                                        AS dtime_inserted, 
              c_name_user                                      AS user_inserted, 
              c_sysdate                                        AS dtime_updated, 
              c_name_user                                      AS user_updated
           FROM dual   
           ) s
    ON (t.id_process = s.id_process)
    WHEN NOT MATCHED THEN
      INSERT
        (id_process, 
         id_process_instance, 
         id_workflow_instance, 
         name_process, 
         name_workflow, 
         date_effective, 
         dtime_start, 
         dtime_end, 
         code_status,
         flag_restart, 
         dtime_inserted, 
         user_inserted, 
         dtime_updated, 
         user_updated)
      VALUES
        (s.id_process, 
         s.id_process_instance, 
         s.id_workflow_instance, 
         s.name_process, 
         s.name_workflow, 
         s.date_effective,
         s.dtime_start, 
         s.dtime_end, 
         s.code_status, 
         s.flag_restart, 
         s.dtime_inserted, 
         s.user_inserted, 
         s.dtime_updated, 
         s.user_updated) 
    WHEN MATCHED THEN
      UPDATE SET
        t.id_process_instance  = s.id_process_instance, 
        t.id_workflow_instance = s.id_workflow_instance, 
        t.name_process         = s.name_process, 
        t.name_workflow        = s.name_workflow, 
        t.date_effective       = s.date_effective, 
        t.dtime_start          = s.dtime_start, 
        t.dtime_end            = s.dtime_end, 
        t.code_status          = s.code_status,
        t.flag_restart         = s.flag_restart, 
        t.dtime_updated        = s.dtime_updated, 
        t.user_updated         = s.user_updated; 

    -- Add additional parameters
    v_step := 'Log additional parameters';
    IF p_process(p_id_process).process_parameter.count > 0 THEN

       -- Loop through migrations
       FOR i IN p_process(p_id_process).process_parameter.first .. p_process(p_id_process).process_parameter.last
       LOOP
         
         INSERT INTO owner_wfm.etl_process_instance_parameter
           (id_process_instance, 
            date_effective, 
            name_parameter, 
            text_value, 
            dtime_inserted, 
            user_inserted, 
            dtime_updated, 
            user_updated) 
         VALUES  
           (p_process(p_id_process).id_process_instance_new, 
            p_process(p_id_process).date_effective_new, 
            p_process(p_id_process).process_parameter(i).name_parameter, 
            p_process(p_id_process).process_parameter(i).text_value, 
            c_sysdate, 
            c_name_user, 
            c_sysdate, 
            c_name_user);
            
       END LOOP;
    END IF;
    
    -- Set variables into array
    v_step := 'Set variables into array';
    p_process(p_id_process).id_process_instance_curr   := p_process(p_id_process).id_process_instance_new;
    p_process(p_id_process).id_workflow_instance_curr  := p_process(p_id_process).id_workflow_instance_new;
    p_process(p_id_process).date_effective_curr        := p_process(p_id_process).date_effective_new;
    p_process(p_id_process).code_status_curr           := c_status_new;
    p_process(p_id_process).dtime_start_curr           := p_process(p_id_process).dtime_start_new;
    p_process(p_id_process).dtime_end_curr             := c_date_future;

  EXCEPTION 
    WHEN OTHERS THEN
      ROLLBACK;
      raise_application_error(-20001, 'Procedure '||c_proc_name||' ('||v_step||')', TRUE);

  END set_process_instance;  
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_PROCESS_INSTANCE_WF
  -- purpose:        
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_process_instance_wf(p_id_process IN INTEGER,        
                                    p_process    IN OUT tt_process)
  IS

    c_proc_name   CONSTANT VARCHAR2(30) := 'SET_PROCESS_INSTANCE_WF';  
    v_sysdate     DATE := SYSDATE;
    v_step        VARCHAR2(500);
    v_dtime_end   DATE;
    v_code_status VARCHAR2(10);
    
  BEGIN

    -- Set process instance (workflow instance)
    v_step := 'Set process instance (workflow instance)';         
    UPDATE owner_wfm.etl_process_instance
       SET id_workflow_instance = p_process(p_id_process).id_workflow_instance_new,
           dtime_updated = v_sysdate,
           user_updated  = c_name_user
    WHERE date_effective = p_process(p_id_process).date_effective_curr
      AND id_process_instance = p_process(p_id_process).id_process_instance_curr;
    
    -- Set process status (workflow instance)
    v_step := 'Set process status (workflow instance)';   
    UPDATE owner_wfm.etl_process_status
       SET id_workflow_instance = p_process(p_id_process).id_workflow_instance_new,
                         -- This case is there just for situation when process ends before it's even marked as RUNNING
           code_status = CASE WHEN p_process(p_id_process).code_status_curr = c_status_running AND code_status = c_status_complete THEN code_status
                              ELSE p_process(p_id_process).code_status_curr
                         END,
           dtime_updated = v_sysdate,
           user_updated  = c_name_user
    WHERE id_process = p_id_process
    RETURNING dtime_end,
              code_status  
    INTO v_dtime_end,
         v_code_status;
         
    -- Adjust process instance information for situation when process ends before it's even marked as RUNNING
    IF p_process(p_id_process).code_status_curr = c_status_running AND v_code_status = c_status_complete THEN
      
      -- Set variables into array
      v_step := 'Set variables into array';
      p_process(p_id_process).code_status_curr := v_code_status; 
      p_process(p_id_process).dtime_end_curr := v_dtime_end;
      
    END IF;
 
  EXCEPTION 
    WHEN OTHERS THEN
      ROLLBACK;
      raise_application_error(-20002, 'Procedure '||c_proc_name||' ('||v_step||')', TRUE);

  END set_process_instance_wf;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_PROCESS_INSTANCE_STATUS
  -- purpose:       
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_process_instance_status(p_id_process_instance IN INTEGER,
                                        p_code_status         IN VARCHAR2,
                                        p_process_instance    OUT t_process_instance)
  IS
  
    v_sysdate              DATE := SYSDATE;
    v_name_process         VARCHAR2(30);
    v_id_workflow_instance VARCHAR2(100);
    v_date_effective       DATE;
    v_dtime_start          DATE;
                
  BEGIN

    -- Set process status
    UPDATE owner_wfm.etl_process_status
       SET dtime_end     = CASE WHEN p_code_status IN (c_status_complete, c_status_cancel) THEN v_sysdate        
                                ELSE dtime_end
                           END,
           code_status   = CASE WHEN code_status = c_status_suspend THEN
                                     CASE WHEN p_code_status = c_status_resume             THEN c_status_running
                                          WHEN p_code_status = c_status_cancel             THEN c_status_cancel
                                          ELSE code_status  
                                     END
                                ELSE CASE WHEN p_code_status IN (c_status_restart, c_status_resume, c_status_skip, c_status_unstuck) 
                                                                                           THEN c_status_running 
                                          WHEN p_code_status = c_status_suspend            THEN c_status_suspend
                                          ELSE p_code_status 
                                     END
                           END,
           flag_restart  = CASE WHEN p_code_status = c_status_restart                      THEN c_flag_y
                                ELSE flag_restart
                           END,
           dtime_updated = v_sysdate,
           user_updated  = c_name_user
    WHERE id_process_instance = p_id_process_instance
    RETURNING name_process,
              id_workflow_instance,
              date_effective,
              dtime_start
    INTO v_name_process,
         v_id_workflow_instance,
         v_date_effective,
         v_dtime_start; 

    -- Set process instance status    
    IF p_code_status IN (c_status_complete, c_status_cancel, c_status_restart)  THEN
      
      UPDATE owner_wfm.etl_process_instance
         SET dtime_end    = CASE WHEN p_code_status IN (c_status_complete, c_status_cancel) THEN v_sysdate        
                                 ELSE dtime_end
                            END,
             code_status  = CASE WHEN p_code_status = c_status_restart                      THEN code_status
                                 ELSE p_code_status 
                            END,
             flag_restart = CASE WHEN p_code_status = c_status_restart                      THEN c_flag_y
                                 ELSE flag_restart  
                            END,
             dtime_updated = v_sysdate,
             user_updated = c_name_user
      WHERE id_process_instance = p_id_process_instance
        AND date_effective = v_date_effective;
        
    END IF; 
 
    -- Return process instance information
    p_process_instance.name_process         := v_name_process;
    p_process_instance.id_workflow_instance := v_id_workflow_instance;
    p_process_instance.date_effective       := v_date_effective;
    p_process_instance.dtime_start          := v_dtime_start;

  END set_process_instance_status;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_PROCESS_INFO
  -- purpose:       
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_process_info(p_dtime_start_new IN DATE,
                             p_process         OUT tt_process)
  IS
    
    v_timeshift INTEGER := NVL(TO_NUMBER(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'WF_TIMESHIFT_NUMDAYS', p_code_group => 'WF_TIMESHIFT')),0);
  
    CURSOR c_process IS
      WITH process_window AS (SELECT
                                 code_process_window,
                                 MAX(CASE WHEN p_dtime_start_new BETWEEN dtime_start_from AND dtime_start_to THEN c_flag_y 
                                          ELSE c_flag_n
                                     END) AS flag_start_window
                              FROM (SELECT
                                       code_process_window,
                                       TRUNC(p_dtime_start_new) + (dtime_start_from - TRUNC(dtime_start_from)) AS dtime_start_from,
                                       TRUNC(p_dtime_start_new) + (dtime_start_to   - TRUNC(dtime_start_to))   AS dtime_start_to
                                    FROM owner_wfm.etl_process_window
                                    -- Process window is not deleted
                                    WHERE flag_deleted = c_flag_n
                                    )
                              GROUP BY code_process_window
                              )
      SELECT
         p.id_process                  AS id_process, 
         p.name_process                AS name_process, 
         p.name_workflow               AS name_workflow, 
         p.num_process_priority        AS num_process_priority, 
         p.code_process_group          AS code_process_group, 
         p.code_process_window         AS code_process_window,    
         p.flag_multiple_start         AS flag_multiple_start,
         pg.code_start_method          AS code_start_method,
         pg.code_start_interval        AS code_start_interval, 
         pg.code_date_effective_method AS code_date_effective_method, 
         ps.id_process_instance        AS id_process_instance_curr, 
         ps.id_workflow_instance       AS id_workflow_instance_curr,
         p_dtime_start_new             AS dtime_start_new,
         pw.flag_start_window          AS flag_start_window,
         ps.date_effective             AS date_effective_curr, 
         ps.dtime_start                AS dtime_start_curr, 
         ps.dtime_end                  AS dtime_end_curr, 
         ps.code_status                AS code_status_curr,
         CASE WHEN ps.id_process_instance IS NULL THEN c_flag_y
              ELSE c_flag_n
         END                           AS flag_first_start,
         NVL(pg.flag_active, c_flag_n) AS flag_active,
         p.flag_deleted                AS flag_deleted
      FROM owner_wfm.etl_process p
      LEFT JOIN owner_wfm.etl_process_group pg ON p.code_process_group = pg.code_process_group
                                              AND pg.flag_deleted = c_flag_n   
      LEFT JOIN process_window pw ON p.code_process_window = pw.code_process_window
      LEFT JOIN owner_wfm.etl_process_status ps ON p.id_process = ps.id_process;
              
    a_process tt_process;
    
  BEGIN

    -- Reset process info
    a_process.delete();

    -- Loop through processes and set array
    FOR i IN c_process
    LOOP

      -- Set process info
      a_process(i.id_process).id_process                 := i.id_process;
      a_process(i.id_process).name_process               := i.name_process;
      a_process(i.id_process).name_workflow              := i.name_workflow;
      a_process(i.id_process).num_process_priority       := i.num_process_priority;
      a_process(i.id_process).code_process_group         := i.code_process_group;
      a_process(i.id_process).code_process_window        := i.code_process_window;
      a_process(i.id_process).flag_multiple_start        := i.flag_multiple_start;
      a_process(i.id_process).code_start_method          := i.code_start_method;
      a_process(i.id_process).code_start_interval        := i.code_start_interval;
      a_process(i.id_process).code_date_effective_method := i.code_date_effective_method;  
      a_process(i.id_process).date_effective_max         := TRUNC(i.dtime_start_new) + v_timeshift; 
      a_process(i.id_process).id_process_instance_new    := NULL;
      a_process(i.id_process).id_workflow_instance_new   := NULL;
      a_process(i.id_process).date_effective_new         := NULL;
      a_process(i.id_process).dtime_start_new            := i.dtime_start_new;
      a_process(i.id_process).flag_start_window          := i.flag_start_window;
      a_process(i.id_process).id_process_instance_curr   := i.id_process_instance_curr;
      a_process(i.id_process).id_workflow_instance_curr  := i.id_workflow_instance_curr;
      a_process(i.id_process).date_effective_curr        := i.date_effective_curr;
      a_process(i.id_process).dtime_start_curr           := i.dtime_start_curr;
      a_process(i.id_process).dtime_end_curr             := i.dtime_end_curr;
      a_process(i.id_process).code_status_curr           := i.code_status_curr;
      a_process(i.id_process).flag_first_start           := i.flag_first_start;
      a_process(i.id_process).flag_active                := i.flag_active;
      a_process(i.id_process).flag_deleted               := i.flag_deleted;      
            
    END LOOP;
    
    -- Set result
    p_process := a_process;

  END get_process_info;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_PROCESS_INFO_PREV
  -- purpose:        Get process info for previous process instance of given process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_process_info_prev(p_id_process IN INTEGER,
                                  p_process    IN OUT tt_process)
  IS

  BEGIN
    
    -- Set process info for "new" process instance
    p_process(p_id_process).id_process_instance_new    := p_process(p_id_process).id_process_instance_curr;
    p_process(p_id_process).id_workflow_instance_new   := p_process(p_id_process).id_workflow_instance_curr;
    p_process(p_id_process).date_effective_new         := p_process(p_id_process).date_effective_curr;
    p_process(p_id_process).dtime_start_new            := p_process(p_id_process).dtime_start_curr;
  
    -- Get process fo for "previous" process instance
    BEGIN
      
      SELECT
         id_process_instance,
         id_workflow_instance,
         date_effective,
         dtime_start,
         dtime_end,
         code_status
        INTO
         p_process(p_id_process).id_process_instance_curr,
         p_process(p_id_process).id_workflow_instance_curr,
         p_process(p_id_process).date_effective_curr,
         p_process(p_id_process).dtime_start_curr,
         p_process(p_id_process).dtime_end_curr,
         p_process(p_id_process).code_status_curr
      FROM (SELECT
               id_process_instance,
               id_workflow_instance,
               date_effective,
               dtime_start,
               dtime_end,
               code_status,
               ROW_NUMBER() OVER(PARTITION BY id_process ORDER BY date_effective desc, id_process_instance DESC) AS num_idx
            FROM owner_wfm.etl_process_instance
            WHERE id_process = p_id_process
              AND id_process_instance < p_process(p_id_process).id_process_instance_new
            )
      WHERE num_idx = 1;
      
    EXCEPTION
      WHEN no_data_found THEN
        -- If its first run, then set values for first load
        p_process(p_id_process).id_process_instance_curr  := NULL;
        p_process(p_id_process).id_workflow_instance_curr := NULL; 
        p_process(p_id_process).date_effective_curr       := NULL; 
        p_process(p_id_process).dtime_start_curr          := NULL; 
        p_process(p_id_process).dtime_end_curr            := NULL; 
        p_process(p_id_process).code_status_curr          := NULL;
        p_process(p_id_process).flag_first_start          := c_flag_y;
      
    END;

  END get_process_info_prev;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_PROCESS_DATE_EFFECTIVE
  -- purpose:        Set new date effective for the process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_process_date_effective(p_id_process IN INTEGER,        
                                       p_process    IN OUT tt_process)
  IS

  BEGIN

    -- If its not first start then get effective date
    IF p_process(p_id_process).flag_first_start = c_flag_n THEN
      
      -- If method is next planned date effective
      IF p_process(p_id_process).code_date_effective_method = c_start_deffmth_nextpl THEN
        
        -- Get effective date
        p_process(p_id_process).date_effective_new := owner_wfm.lib_etl_process_run_dateeff.get_date_effective_next_plan(p_id_process          => p_process(p_id_process).id_process,
                                                                                                                         p_date_effective_max  => p_process(p_id_process).date_effective_max,                         
                                                                                                                         p_date_effective_curr => p_process(p_id_process).date_effective_curr,
                                                                                                                         p_code_status_curr    => p_process(p_id_process).code_status_curr);
                           
      -- If method is refr / incr date effective
      ELSIF p_process(p_id_process).code_date_effective_method = c_start_deffmth_refinc THEN
        
        -- Get effective date
        p_process(p_id_process).date_effective_new := owner_wfm.lib_etl_process_run_dateeff.get_date_effective_refr_incr(p_name_process        => p_process(p_id_process).name_process,
                                                                                                                         p_date_effective_max  => p_process(p_id_process).date_effective_max);    

      -- If method is sysdate
      ELSIF p_process(p_id_process).code_date_effective_method = c_start_deffmth_curr THEN    
        
        -- Get effective date
        p_process(p_id_process).date_effective_new := TRUNC(p_process(p_id_process).dtime_start_new);
      
      END IF;
      
    END IF;

  END get_process_date_effective;  
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_PROCESS_INSTANCE_STATUS
  -- purpose:        Get status for given process instance
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_process_instance_status(p_id_process_instance IN INTEGER,        
                                        p_code_status         OUT VARCHAR2)
  IS

  BEGIN
    
    -- Get process instance status
    SELECT
       code_status
      INTO  
       p_code_status
    FROM owner_wfm.etl_process_status
    WHERE id_process_instance = p_id_process_instance; 
    
  END get_process_instance_status;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_PROCESS_INSTANCE_PAR
  -- purpose:        Get parameter value for given process instance and parameter name
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_process_instance_par(p_id_process_instance IN INTEGER,  
                                     p_date_effective      IN DATE,
                                     p_name_parameter      IN VARCHAR2,
                                     p_text_value          OUT VARCHAR2)
  IS

  BEGIN
    
    -- Get process instance parameter
    SELECT
       text_value
      INTO  
       p_text_value
    FROM owner_wfm.etl_process_instance_parameter
    WHERE date_effective = p_date_effective
      AND id_process_instance = p_id_process_instance
      AND name_parameter = p_name_parameter; 
    
  END get_process_instance_par;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_PROCESS_PLAN_MS
  -- purpose:        Get multiple start information from process plan
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_process_plan_ms(p_id_process     IN INTEGER,
                               p_date_effective IN DATE) RETURN BOOLEAN RESULT_CACHE RELIES_ON (owner_wfm.etl_process_plan)
  AS
  
    v_flag_multiple_start VARCHAR2(1);  

  BEGIN

    -- Get multiple start information from process plan
    BEGIN
      SELECT
         flag_multiple_start
        INTO
         v_flag_multiple_start
      FROM owner_wfm.etl_process_plan
      WHERE id_process = p_id_process
        AND date_effective = p_date_effective
        AND flag_plan_status != c_flag_n;
    EXCEPTION
      WHEN no_data_found THEN
        v_flag_multiple_start := c_flag_n; 
    END;

    -- Return result
    IF v_flag_multiple_start = c_flag_y THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;

  END get_process_plan_ms;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: Check start inteval
  -- purpose:       
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_start_interval(p_id_process   IN INTEGER,
                                 p_process      IN tt_process,
                                 p_text_message OUT VARCHAR2,
                                 p_result       OUT BOOLEAN)
  IS
  
    v_num_day_new   INTEGER;
    v_num_day_curr  INTEGER;
    v_num_hour_new  INTEGER;
    v_num_hour_curr INTEGER;
    v_num_min_new   INTEGER;
    v_num_min_curr  INTEGER;
    
  BEGIN
    
    -- Set default result
    p_text_message := NULL;
    p_result       := FALSE;

    -- Set new start day, hour and minute number
    v_num_day_new  := TO_CHAR(p_process(p_id_process).dtime_start_new, c_day_mask);
    v_num_hour_new := TO_CHAR(p_process(p_id_process).dtime_start_new, c_hh24_mask);
    v_num_min_new  := TO_CHAR(p_process(p_id_process).dtime_start_new, c_min_mask);
    
    -- Set curr start day, hour and minute number
    v_num_day_curr  := TO_CHAR(p_process(p_id_process).dtime_start_curr, c_day_mask);
    v_num_hour_curr := TO_CHAR(p_process(p_id_process).dtime_start_curr, c_hh24_mask);
    v_num_min_curr  := TO_CHAR(p_process(p_id_process).dtime_start_curr, c_min_mask);
    
    -- Every hour
    IF p_process(p_id_process).code_start_interval = c_start_int_hour THEN
      
      -- If the process did not run this hour or it is first run for given date effective
      IF v_num_hour_new != v_num_hour_curr 
          OR v_num_day_new != v_num_day_curr THEN
    
        -- Set result as true
        p_result := TRUE;

      -- Otherwise return flase
      ELSE

        -- Set check message, result as false
        p_text_message := 'Hour '||v_num_hour_new||' has been already processed';  
        
      END IF;      
     
    -- Every odd hour
    ELSIF p_process(p_id_process).code_start_interval = c_start_int_odd_hour THEN
      
      -- If this is odd hour
      IF MOD(v_num_hour_new, 2) != 0 THEN
        
        -- If the process did not run this hour or it is first run for given date effective
        IF v_num_hour_new != v_num_hour_curr 
            OR v_num_day_new != v_num_day_curr THEN
        
          -- Set result as true
          p_result := TRUE;
          
        -- Otherwise return flase
        ELSE

          -- Set check message, result as false
          p_text_message := 'Odd hour ('||v_num_hour_new||') has been already processed';     
        
        END IF;

      ELSE
        
        -- Set check message, result as false
        p_text_message := 'Current hour ('||v_num_hour_new||') is not odd'; 
        
      END IF;     

    -- Every even hour
    ELSIF p_process(p_id_process).code_start_interval = c_start_int_even_hour THEN
      
      -- If this is even hour
      IF MOD(v_num_hour_new, 2) = 0 THEN
        
        -- If the process did not run this hour or it is first run for given date effective
        IF v_num_hour_new != v_num_hour_curr
            OR v_num_day_new != v_num_day_curr THEN
        
          -- Set result as true
          p_result := TRUE;
          
        -- Otherwise return flase
        ELSE

          -- Set check message, result as false
          p_text_message := 'Even hour ('||v_num_hour_new||') has been already processed';      
        
        END IF;

      ELSE
        
        -- Set check message, result as false
        p_text_message := 'Current hour ('||v_num_hour_new||') is not even';
        
      END IF;  

    -- Every ten minutes
    ELSIF p_process(p_id_process).code_start_interval = c_start_int_ten_minutes THEN
    
      -- If the process did not run yet or it is first run for given date effective
      IF TRUNC(v_num_min_new / 10) != TRUNC(v_num_min_curr / 10)
          OR v_num_day_new != v_num_day_curr THEN
        
        -- Set result as true
        p_result := TRUE;
      
      -- Otherwise return flase
      ELSE
        
        -- Set check message, result as false
        p_text_message := 'Current ten minutes period has been already processed'; 
        
      END IF;

    -- Every thirty minutes
    ELSIF p_process(p_id_process).code_start_interval = c_start_int_thirty_minutes THEN
    
      -- If the process did not run yet or it is first run for given date effective
      IF TRUNC(v_num_min_new / 30) != TRUNC(v_num_min_curr / 30)
          OR v_num_day_new != v_num_day_curr THEN
        
        -- Set result as true
        p_result := TRUE;
      
      -- Otherwise return flase
      ELSE
        
        -- Set check message, result as false
        p_text_message := 'Current thirty minutes period has been already processed'; 
        
      END IF;

    -- Unknown start interval
    ELSE
    
      -- Set check message, result as false
      p_text_message := 'Unknown code start interval ('||p_process(p_id_process).code_start_interval||')';  

    END IF;      
     
  END check_start_interval;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: Check basic conditions
  -- purpose:       
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_basic_conditions(p_id_process        IN INTEGER,
                                   p_process           IN tt_process,
                                   p_flag_manual_start IN VARCHAR2,
                                   p_text_message      OUT VARCHAR2,
                                   p_result            OUT BOOLEAN)
  IS
  
  BEGIN
    
    -- Set default result
    p_text_message := NULL;
    p_result       := TRUE;

    -- Check process is running
    IF p_process(p_id_process).code_status_curr IN (c_status_new, c_status_running, c_status_error, c_status_suspend, c_status_stuck) THEN
      
      -- Set check message, result as false
      p_text_message := 'Same process is running (id_process_instance = '||p_process(p_id_process).id_process_instance_curr||')';
      p_result := FALSE;
      RETURN;
         
    END IF;

    -- Check if process is deleted
    IF p_process(p_id_process).flag_deleted = c_flag_y THEN 
     
      -- Set check message, result as false
      p_text_message := 'Process is deleted';          
      p_result := FALSE;
      RETURN;
             
    END IF;  

    -- Check if process is active
    IF p_flag_manual_start = c_flag_n 
        AND p_process(p_id_process).flag_active = c_flag_n THEN 
     
      -- Set check message, result as false
      p_text_message := 'Process is not active';          
      p_result := FALSE;
      RETURN;
       
    END IF;  
    
    -- Check if its first start  
    IF p_flag_manual_start = c_flag_n
        AND p_process(p_id_process).code_start_method != c_autorun_transfer_method
        AND p_process(p_id_process).flag_first_start = c_flag_y THEN 
    
      -- Set check message, result as false
      p_text_message := 'There is no initial load';          
      p_result := FALSE;
      RETURN;
    
    END IF;     
    
    -- Check if workflow process definition exists (only for first start)
    IF p_process(p_id_process).flag_first_start = c_flag_y 
        AND NOT owner_wfm.lib_etl_workflow_api.check_existing_workflow(p_name_workflow => p_process(p_id_process).name_workflow) THEN 
    
      -- Set check message, result as false
      p_text_message := 'Workflow process definition doesnt exist';          
      p_result := FALSE;
      RETURN;
    
    END IF;    

    -- Check start interval
    IF p_flag_manual_start = c_flag_n
        AND p_process(p_id_process).code_start_interval != c_start_int_anytime THEN
      
      -- Set check message, result
      check_start_interval(p_id_process   => p_id_process,
                           p_process      => p_process,
                           p_text_message => p_text_message,
                           p_result       => p_result);
      
      -- If result is false                     
      IF NOT p_result THEN                   
        RETURN;
      END IF;
            
    END IF;   

    -- Check start time
    IF p_flag_manual_start = c_flag_n
        AND p_process(p_id_process).flag_start_window = c_flag_n THEN 
       
      -- Set check message, result as false
      p_text_message := 'Start time is outside process start window';
      p_result := FALSE;
      RETURN;
            
    END IF;

  END check_basic_conditions;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: Check date effective conditions
  -- purpose:       
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_dateeff_conditions(p_id_process       IN INTEGER,
                                     p_process          IN tt_process,
                                     p_flag_check_all   IN VARCHAR2 DEFAULT c_flag_n,
                                     p_text_message     OUT VARCHAR2,
                                     p_result           OUT BOOLEAN)
  IS
  
    v_text_message VARCHAR2(4000);
  
  BEGIN
      
    -- Set default result
    p_text_message := NULL;
    v_text_message := NULL;
    p_result       := TRUE;
  
    -- Check if effective date exists
    IF p_process(p_id_process).date_effective_new IS NULL THEN 
 
      -- For purpose of manual start and collect all run conditions
      v_text_message := v_text_message||'Next effective date not found!'||CHR(10);  
      -- Set check message, result as false
      p_text_message := 'Next effective date not found';
      p_result := FALSE;

      IF p_flag_check_all = c_flag_n THEN
        RETURN;          
      END IF;    
    
    END IF;
     
    -- Check multiple start of process for same effective date
    IF p_process(p_id_process).flag_multiple_start = c_flag_n 
        AND p_process(p_id_process).date_effective_new = p_process(p_id_process).date_effective_curr 
        AND p_process(p_id_process).code_status_curr = c_status_complete THEN
     
      -- Get actual multiple start information from process plan
      IF NOT get_process_plan_ms(p_id_process     => p_id_process,
                                 p_date_effective => p_process(p_id_process).date_effective_new) THEN
      
   
        -- For purpose of manual start and collect all run conditions
        v_text_message := v_text_message||'Not allowed multiple start for effective date ('||TO_CHAR(p_process(p_id_process).date_effective_new, c_date_mask)||')'||CHR(10);  
        -- Set check message, result as false
        p_text_message := 'Effective date ('||TO_CHAR(p_process(p_id_process).date_effective_new, c_date_mask)||') has been processed (multiple start is not allowed)';
        p_result := FALSE;

        IF p_flag_check_all = c_flag_n THEN
          RETURN;  
        END IF;
        
      END IF;         
    
    END IF;    
    
    -- Check if greater effective date has been processed
    IF p_process(p_id_process).date_effective_new < p_process(p_id_process).date_effective_curr THEN
      
      -- For purpose of manual start and collect all run conditions
      v_text_message := v_text_message||'Greater effective date ('||TO_CHAR(p_process(p_id_process).date_effective_curr, c_date_mask)||') has been processed'||CHR(10);  
      -- Set check message, result as false
      p_text_message := 'Greater effective date ('||TO_CHAR(p_process(p_id_process).date_effective_curr, c_date_mask)||') has been processed';
      p_result := FALSE;

      IF p_flag_check_all = c_flag_n THEN
        RETURN;  
      END IF;
         
    END IF;   

    -- In case of manual start return collected information
    IF p_flag_check_all = c_flag_y THEN
      p_text_message := v_text_message;  
    END IF;

  END check_dateeff_conditions;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: Check process conditions
  -- purpose:       
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_process_conditions(p_id_process        IN INTEGER,
                                     p_process           IN tt_process,
                                     p_flag_manual_start IN VARCHAR2,
                                     p_flag_check_all    IN VARCHAR2 DEFAULT c_flag_n,
                                     p_text_message      OUT VARCHAR2,
                                     p_result            OUT BOOLEAN)
  IS

    v_int_result     INTEGER := 0;     
    v_ref_id_process INTEGER;
    v_stmt           VARCHAR2(500);
    v_text_message   VARCHAR2(4000);
    v_result_all     BOOLEAN;

    CURSOR c_process_condition IS
      SELECT
         code_type, 
         text_condition, 
         code_check_type,
         flag_manual_start_check
      FROM owner_wfm.etl_process_condition
      WHERE id_process = p_id_process
            -- Process is not deleted
        AND flag_deleted = c_flag_n
      ORDER BY num_order DESC;
  
  BEGIN

    -- Set default result
    p_text_message := NULL;
    v_text_message := NULL;
    p_result       := TRUE;
    
    -- Loop through process conditions
    FOR i IN c_process_condition
    LOOP

      v_result_all := TRUE;
      -- If flag force start is set to Y and flag manual start check is set to N then ignore such conditions
      IF p_flag_manual_start = c_flag_y AND i.flag_manual_start_check = c_flag_n THEN
    
        -- Do nothing
        NULL;
    
      ELSE
    
        -- If condition type is process
        IF i.code_type = 'PROCESS' THEN

          -- Set id of referenced process
          v_ref_id_process := TO_NUMBER(i.text_condition);  
          
          -- Check if referenced process is not deleted
          IF p_process(v_ref_id_process).flag_deleted = c_flag_n THEN
           
            --  Check if referenced process is complete (for current date)
            IF i.code_check_type = 'COMPLETE_CURRENT' THEN
              
              -- If the current date effective of referenced process is smaller 
              IF p_process(v_ref_id_process).date_effective_curr < p_process(p_id_process).date_effective_new THEN
                
                -- Process could not run for this effective date so result is 0
                v_int_result := 0;
                  
              -- If the current date effective of referenced process is same and status is complete
              ELSIF p_process(v_ref_id_process).date_effective_curr = p_process(p_id_process).date_effective_new
                     AND p_process(v_ref_id_process).code_status_curr = (c_status_complete) THEN  
                  
                -- Process run for this effective date so result is 1
                v_int_result := 1; 
                
              -- Otherwise find it in process instance  
              ELSE  
                     
                -- Find if process finished for current date
                SELECT
                   COUNT(1)
                  INTO
                   v_int_result 
                FROM owner_wfm.etl_process_instance
                WHERE id_process = v_ref_id_process
                  AND date_effective = p_process(p_id_process).date_effective_new
                  AND code_status = c_status_complete;
                  
              END IF;

              -- If referenced process is not complete for same date then return false
              IF v_int_result = 0 THEN
                
                -- Set check message, result as false
                p_text_message := i.code_check_type||' check failed on process '||p_process(v_ref_id_process).name_process||' for date effective '||TO_CHAR(p_process(p_id_process).date_effective_new, c_date_mask);
                p_result := FALSE;
                v_result_all := FALSE;

                --In case of standart start (not manual) we don't want to check all, call return. 
                IF p_flag_check_all = c_flag_n THEN
                  RETURN;
                END IF; 
                          
              END IF;
              
            -- Check if reference processes was not started (for current date)
            ELSIF i.code_check_type = 'NOSTART_CURRENT' THEN
              
              -- If the current date effective of referenced process is smaller 
              IF p_process(v_ref_id_process).date_effective_curr < p_process(p_id_process).date_effective_new THEN
                
                -- Process could not run for this effective date so result is 0
                v_int_result := 0;
                  
              -- If the current date effective of referenced process is same
              ELSIF p_process(v_ref_id_process).date_effective_curr = p_process(p_id_process).date_effective_new THEN
                  
                -- Process started for this effective date so result is 1
                v_int_result := 1;
                
              -- Otherwise find it in process instance  
              ELSE  
                     
                -- Find if process started for current date
                SELECT
                   COUNT(1)
                  INTO
                   v_int_result 
                FROM owner_wfm.etl_process_instance
                WHERE id_process = v_ref_id_process
                  AND date_effective = p_process(p_id_process).date_effective_new;
                  
              END IF;
                 
              -- If referenced process has been started for current date then return false
              IF v_int_result > 0 THEN
                           
                -- Set check message, result as false
                p_text_message := i.code_check_type||' check failed on process '||p_process(v_ref_id_process).name_process||' for date effective '||TO_CHAR(p_process(p_id_process).date_effective_new, c_date_mask);
                p_result := FALSE;
                v_result_all := FALSE;

                --In case of standart start (not manual) we don't want to check all, call return. 
                IF p_flag_check_all = c_flag_n THEN
                  RETURN;
                END IF; 
                          
              END IF;          

            -- Check if reference processes are not running (for current date)
            ELSIF i.code_check_type = 'NORUN_CURRENT' THEN
              
              -- If process is running for current date then return false
              IF p_process(v_ref_id_process).code_status_curr IN (c_status_new, c_status_running, c_status_error, c_status_suspend, c_status_stuck)
                  AND p_process(v_ref_id_process).date_effective_curr = p_process(p_id_process).date_effective_new THEN

                -- Set check message, result as false
                p_text_message := i.code_check_type||' check failed on process '||p_process(v_ref_id_process).name_process||' for date effective '||TO_CHAR(p_process(p_id_process).date_effective_new, c_date_mask);          
                p_result := FALSE;
                v_result_all := FALSE;

                --In case of standart start (not manual) we don't want to check all, call return. 
                IF p_flag_check_all = c_flag_n THEN
                  RETURN;
                END IF; 
              
              END IF;
     
            -- Check if reference processes are not running (for any date)
            ELSIF i.code_check_type = 'NORUN_ANY' THEN
              
              -- If process is running for any date return false
              IF p_process(v_ref_id_process).code_status_curr IN (c_status_new, c_status_running, c_status_error, c_status_suspend, c_status_stuck) THEN

                -- Set check message, result as false
                p_text_message := i.code_check_type||' check failed on process '||p_process(v_ref_id_process).name_process;          
                p_result := FALSE;
                v_result_all := FALSE;

                --In case of standart start (not manual) we don't want to check all, call return. 
                IF p_flag_check_all = c_flag_n THEN
                  RETURN;
                END IF; 
              
              END IF;  
            
            -- Check if reference process did run in planned date, which immediately precedes current date
            -- both mandatory and optional plans are taken into account
            -- if there is no plan for reference process, or reference process never run yet, than reference process is not blocking  
            ELSIF i.code_check_type = 'COMPLETE_PREVIOUS' THEN 
              
              -- Find if process finished for previous effective date
              WITH process_plan AS (SELECT
                                       id_process          AS id_process,
                                       MAX(date_effective) AS date_effective
                                    FROM owner_wfm.etl_process_plan
                                    WHERE id_process = v_ref_id_process
                                      AND flag_plan_status != c_flag_n
                                      AND date_effective < p_process(p_id_process).date_effective_new
                                    GROUP BY id_process
                                    )
              SELECT
                 COUNT(1)
                INTO
                 v_int_result 
              FROM process_plan pp
              JOIN owner_wfm.etl_process_instance pi ON pp.id_process = pi.id_process
                                                    AND pp.date_effective = pi.date_effective
              WHERE pi.code_status = c_status_complete; 
              
              -- If referenced process is not complete for previous date then return false
              IF v_int_result = 0 THEN
                           
                -- Set check message, result as false
                p_text_message := i.code_check_type||' check failed on process '||p_process(v_ref_id_process).name_process||' for date effective '||TO_CHAR(p_process(p_id_process).date_effective_new, c_date_mask);
                p_result := FALSE;
                v_result_all := FALSE;

                --In case of standart start (not manual) we don't want to check all, call return. 
                IF p_flag_check_all = c_flag_n THEN
                  RETURN;
                END IF; 
                          
              END IF;
        
            END IF;
            
          END IF;
                    
        -- If condition type is function
        ELSIF i.code_type = 'FUNCTION' THEN
          
          -- Set condition statement for function
          v_stmt := 'BEGIN :res := CASE WHEN ('||i.text_condition||') THEN 1 ELSE 0 END; END;';

          BEGIN
            
            -- Execute condition
            IF i.text_condition LIKE '%:%' THEN
              EXECUTE IMMEDIATE v_stmt USING OUT v_int_result, IN p_process(p_id_process).date_effective_new;
            ELSE
              EXECUTE IMMEDIATE v_stmt USING OUT v_int_result;
            END IF;
            
          EXCEPTION
            WHEN OTHERS THEN
              -- Set check message, result as false
              p_text_message := 'Invalid boolean condition specified in process condition for process '||p_process(p_id_process).name_process||': '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
              p_result := FALSE;
              RETURN;   
          END;
          
          -- If condition was not met return false
          IF ((v_int_result = 0 AND i.code_check_type = 'COND_TRUE') OR (v_int_result = 1 and i.code_check_type = 'COND_FALSE')) THEN

              -- Set check message, result as false
              p_text_message := 'Condition "'||SUBSTR(i.text_condition, 1, 100)||'..." failed for date effective '||TO_CHAR(p_process(p_id_process).date_effective_new, c_date_mask);         
              p_result := FALSE;
              v_result_all := FALSE;

              --In case of standart start (not manual) we don't want to check all, call return. 
              IF p_flag_check_all = c_flag_n THEN
                RETURN;
              END IF; 

          END IF;

        END IF;

        -- In case of manual start and check all set value, we need to collect information.
        IF p_flag_check_all = c_flag_y THEN

           IF i.code_type = 'PROCESS' THEN
              -- Collected text information about run conditions
              v_text_message := v_text_message||'('|| substr(i.code_type,0,1) ||') '||p_process(v_ref_id_process).name_process||' ['||i.code_check_type||']:  '||CASE WHEN v_result_all = FALSE THEN 'False' ELSE 'True' END||CHR(10);
           ELSIF i.code_type = 'FUNCTION' THEN
              -- Collected text information about run conditions
              v_text_message := v_text_message||'('|| substr(i.code_type,0,1) ||') '||SUBSTR(i.text_condition, 1, 100)||':  '||CASE WHEN v_result_all = FALSE THEN 'False' ELSE 'True' END||CHR(10);
           END IF; 
        END IF;
        
      END IF;
    
    END LOOP;

    -- In case of manual start return collected information about run conditions into p_text_message
    IF p_flag_check_all = c_flag_y THEN
      p_text_message := v_text_message;
    END IF;
 
  END check_process_conditions;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: Check process status
  -- purpose:        Check current process status right before start of process (bug with multiple process start when called in parallel)
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_process_status(p_id_process   IN INTEGER,
                                 p_process      IN OUT tt_process,
                                 p_text_message OUT VARCHAR2,
                                 p_result       OUT BOOLEAN)
  IS
  
  BEGIN
    
    -- Set default result
    p_text_message := NULL;
    p_result       := TRUE;
    
    -- Get actuall process status
    SELECT
       id_process_instance,
       date_effective,
       code_status
      INTO
       p_process(p_id_process).id_process_instance_curr,
       p_process(p_id_process).date_effective_curr, 
       p_process(p_id_process).code_status_curr
    FROM owner_wfm.etl_process_status
    WHERE id_process = p_id_process;

    IF p_process(p_id_process).code_status_curr IN (c_status_new, c_status_running, c_status_error, c_status_suspend, c_status_stuck) THEN
      
      -- Set check message, result as false
      p_text_message := 'Same process is running (id_process_instance = '||p_process(p_id_process).id_process_instance_curr||')';
      p_result := FALSE;
      RETURN;
         
    END IF;
    
  EXCEPTION
    WHEN no_data_found THEN
      NULL;

  END check_process_status;
   
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_START_CONDITIONS_WF
  -- purpose:        Check start conditions inside of started process (called from workflow)
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE check_start_conditions_wf(p_process_key    IN INTEGER,
                                      p_effective_date IN DATE,
                                      p_data_type      IN VARCHAR2)
  IS
  
    c_proc_name       VARCHAR2(30) := 'CHECK_START_CONDITIONS_WF';
    v_step            VARCHAR2(500); 
    v_dtime_start_new DATE := SYSDATE;
    v_id_process      INTEGER;
    v_result          BOOLEAN;
    a_process         tt_process;
    
    ex_no_start       EXCEPTION;
    
  BEGIN

     -- Get process info
     v_step := 'Get process info';
     get_process_info(p_dtime_start_new => v_dtime_start_new,
                      p_process         => a_process);

     -- Get id process
     v_step := 'Get id process';
     SELECT
        id_process
       INTO
        v_id_process
     FROM owner_wfm.etl_process_status
     WHERE id_process_instance = p_process_key
       AND date_effective = p_effective_date;
       
     -- Get process info for previous instance
     v_step := 'Get process info for previous instance';
     get_process_info_prev(p_id_process => v_id_process,
                           p_process    => a_process);

     -- Check basic conditions
     v_step := 'Check basic conditions';
     check_basic_conditions(p_id_process        => v_id_process,
                            p_process           => a_process,
                            p_flag_manual_start => c_flag_y,
                            p_text_message      => v_text_message,
                            p_result            => v_result);

     -- If result is false     
     IF NOT v_result THEN
       
       -- Raise expception
       RAISE ex_no_start;
       
     END IF;                           
    
     -- Check date effective conditions
     v_step := 'Check date effective conditions';
     check_dateeff_conditions(p_id_process   => v_id_process,
                              p_process      => a_process,
                              p_text_message => v_text_message,
                              p_result       => v_result);

     -- If result is false     
     IF NOT v_result THEN
       
       -- Raise expception
       RAISE ex_no_start;
       
     END IF;                                 
     
     -- Check process conditions
     v_step := 'Check process conditions'; 
     check_process_conditions(p_id_process        => v_id_process,
                              p_process           => a_process,
                              p_flag_manual_start => c_flag_n,
                              p_text_message      => v_text_message,
                              p_result            => v_result);

     -- If result is false
     IF NOT v_result THEN
       
       -- Raise expception
       RAISE ex_no_start;
       
     END IF;  
       
  EXCEPTION
    WHEN ex_no_start THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Process ('||a_process(v_id_process).name_process||') cannot continue - '||v_text_message;
      -- Log message 
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
      -- Log process activity
      owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => p_effective_date,
                                                     p_id_process_instance  => p_process_key,
                                                     p_name_activity        => c_proc_name,                         
                                                     p_text_message         => v_text_message); 
      -- Raise error
      -- Error number is set to 20222 on purpose -> its used by the autorestart
      raise_application_error(-20222, v_text_message);
                                               
   WHEN OTHERS THEN  
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
      -- Log process activity
      owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => p_effective_date,
                                                     p_id_process_instance  => p_process_key,
                                                     p_name_activity        => c_proc_name,                         
                                                     p_text_message         => v_text_message); 
      -- Raise error
      raise_application_error(-20004, v_text_message);
                                                
  END check_start_conditions_wf;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CANCEL_PROCESS
  -- purpose:        Cancel specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE cancel_process(p_id_process_instance IN INTEGER,
                           p_text_message        OUT VARCHAR2)
  IS
  
    c_proc_name            VARCHAR2(30) := 'CANCEL_PROCESS';
    v_step                 VARCHAR2(500); 
    v_code_status          VARCHAR2(10);
    a_process_instance     t_process_instance;
    
    ex_wrong_process_status EXCEPTION;
    ex_running_activity     EXCEPTION;
    
  BEGIN

     -- Get process instance status
     v_step := 'Get process instance status';
     get_process_instance_status(p_id_process_instance => p_id_process_instance,        
                                 p_code_status         => v_code_status);
         
     -- If status of given process instance is NEW, then just cancel process in process instance log
     IF v_code_status = c_status_new THEN
       
       -- Cancel process in process instance log
       v_step := 'Cancel process in process instance log';
       set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                   p_code_status         => c_status_cancel,
                                   p_process_instance    => a_process_instance);
       
     -- If status of given process instance is SUSPEND, then check if some activities are running
     ELSIF v_code_status = c_status_suspend THEN

       -- Cancel process in process instance log
       v_step := 'Cancel process in process instance log';
       set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                   p_code_status         => c_status_cancel,
                                   p_process_instance    => a_process_instance);
       
       -- If there is no running activity then cancel process
       IF NOT owner_wfm.lib_etl_workflow_queue.check_unproc_activity(p_id_process_instance  => p_id_process_instance,
                                                                     p_id_workflow_instance => a_process_instance.id_workflow_instance) THEN

         -- Cancel process in workflow engine
         v_step := 'Cancel process in workflow engine';
         owner_wfm.lib_etl_workflow_api.cancel_process(p_id_workflow_instance => a_process_instance.id_workflow_instance,
                                                       p_text_message         => c_proc_name);
       
       -- Otherwise process cannot be canceled
       ELSE
       
         -- Raise an exception
         RAISE ex_running_activity;
                                                      
       END IF;
         
     -- Otherwise process cannot be canceled
     ELSE
       
       -- Raise an exception
       RAISE ex_wrong_process_status;
     
     END IF;
      
     -- Commit
     COMMIT;

     -- Log message 
     v_step := 'Log message';
     -- Set message
     v_text_message := 'Process '||a_process_instance.name_process||' ('||p_id_process_instance||') has been canceled.';
     -- Set output message
     p_text_message := v_text_message;
     -- Log activity
     owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                            p_name_activity      => c_proc_name,                         
                                            p_text_message       => v_text_message);
     -- Log process activity
     owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => a_process_instance.date_effective,
                                                    p_id_process_instance  => p_id_process_instance,
                                                    p_name_activity        => c_proc_name,                         
                                                    p_text_message         => v_text_message); 

  EXCEPTION
    WHEN ex_wrong_process_status THEN
      -- Set message
      v_text_message := 'Only process with status '||c_status_new||' or '||c_status_suspend||' can be canceled!';
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);

    WHEN ex_running_activity THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Some activities are still running. Process cannot be canceled!';
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
      
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
      
  END cancel_process;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SUSPEND_PROCESS
  -- purpose:        Suspend specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE suspend_process(p_id_process_instance IN INTEGER,
                            p_text_message        OUT VARCHAR2)
  IS
  
    c_proc_name             VARCHAR2(30) := 'SUSPEND_PROCESS';
    v_step                  VARCHAR2(500); 
    v_code_status           VARCHAR2(10);
    a_process_instance      t_process_instance;

    ex_wrong_process_status EXCEPTION;
        
  BEGIN

     -- Get process instance status
     v_step := 'Get process instance status';
     get_process_instance_status(p_id_process_instance => p_id_process_instance,        
                                 p_code_status         => v_code_status);
         
     -- If status of given process instance is RUNNING, STUCK or ERROR, then proceed
     IF v_code_status IN (c_status_running, c_status_error, c_status_stuck) THEN
   
       -- Suspend process in process instance log
       v_step := 'Suspend process in process instance log';
       set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                   p_code_status         => c_status_suspend,
                                   p_process_instance    => a_process_instance);
       
       -- Suspend process in workflow engine
       v_step := 'Suspend process in workflow engine';
       owner_wfm.lib_etl_workflow_api.suspend_process(p_id_workflow_instance => a_process_instance.id_workflow_instance);

     -- Otherwise process cannot be suspended
     ELSE
       
       -- Raise an exception
       RAISE ex_wrong_process_status;
     
     END IF;
                           
     -- Commit
     COMMIT;

     -- Log message 
     v_step := 'Log message';
     -- Set message
     v_text_message := 'Process '||a_process_instance.name_process||' ('||p_id_process_instance||') has been suspended.';
     -- Set output message
     p_text_message := v_text_message;
     -- Log activity
     owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                            p_name_activity      => c_proc_name,                         
                                            p_text_message       => v_text_message);
     -- Log process activity
     owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => a_process_instance.date_effective,
                                                    p_id_process_instance  => p_id_process_instance,
                                                    p_name_activity        => c_proc_name,                         
                                                    p_text_message         => v_text_message); 
       
  EXCEPTION
    WHEN ex_wrong_process_status THEN
      -- Set message
      v_text_message := 'Only process with status '||c_status_running||' or '||c_status_error||' or '||c_status_stuck||' can be suspended!';
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);

    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity => c_proc_name,                         
                                             p_text_message  => v_text_message);
                                                   
  END suspend_process;  

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESUME_PROCESS
  -- purpose:        Resume specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE resume_process(p_id_process_instance IN INTEGER,
                           p_text_message        OUT VARCHAR2)
  IS
  
    c_proc_name             VARCHAR2(30) := 'RESUME_PROCESS';
    v_step                  VARCHAR2(500); 
    v_code_status           VARCHAR2(10);
    a_process_instance      t_process_instance;

    ex_wrong_process_status EXCEPTION;
        
  BEGIN
   
     -- Get process instance status
     v_step := 'Get process instance status';
     get_process_instance_status(p_id_process_instance => p_id_process_instance,        
                                 p_code_status         => v_code_status);
         
     -- If status of given process instance is SUSPEND, then proceed
     IF v_code_status = c_status_suspend THEN
  
       -- Resume process in process instance log
       v_step := 'Resume process in process instance log';
       set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                   p_code_status         => c_status_resume,
                                   p_process_instance    => a_process_instance);
       
       -- Resume process in workflow engine
       v_step := 'Resume process in workflow engine';
       owner_wfm.lib_etl_workflow_api.resume_process(p_id_workflow_instance => a_process_instance.id_workflow_instance);
                           
       -- Commit
       COMMIT;
       
       -- Find out if there is failed activity
       v_step := 'Find out if there is failed activity';
       --  Check if there are some failed acitvities in workflow
       IF owner_wfm.lib_etl_workflow_api.check_error_activity(p_id_workflow_instance => a_process_instance.id_workflow_instance) THEN

         -- Set error for process
         v_step := 'Set error for process';
         set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                     p_code_status         => c_status_error,
                                     p_process_instance    => a_process_instance);
                                     
       END IF;
       
     -- Otherwise process cannot be suspended
     ELSE
       
       -- Raise an exception
       RAISE ex_wrong_process_status;
     
     END IF;
       
     -- Commit
     COMMIT;

     -- Log message 
     v_step := 'Log message';
     -- Set message
     v_text_message := 'Process '||a_process_instance.name_process||' ('||p_id_process_instance||') has been resumed.';
     -- Set output message
     p_text_message := v_text_message;
     -- Log activity
     owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                            p_name_activity      => c_proc_name,                         
                                            p_text_message       => v_text_message);
     -- Log process activity
     owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective      => a_process_instance.date_effective,
                                                    p_id_process_instance => p_id_process_instance,
                                                    p_name_activity       => c_proc_name,                         
                                                    p_text_message        => v_text_message); 
       
  EXCEPTION
    WHEN ex_wrong_process_status THEN
      -- Set message
      v_text_message := 'Only process with status '||c_status_suspend||' can be resumed!';
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
      
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
                                                   
  END resume_process;  
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_PROCESS
  -- purpose:        Restart specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE restart_process(p_id_process_instance IN INTEGER,
                            p_text_message        OUT VARCHAR2)
  IS
  
    c_proc_name             VARCHAR2(30) := 'RESTART_PROCESS';
    v_step                  VARCHAR2(500); 
    v_code_status           VARCHAR2(10);
    a_process_instance      t_process_instance;

    ex_wrong_process_status EXCEPTION;
        
  BEGIN
        
     -- Get process instance status
     v_step := 'Get process instance status';
     get_process_instance_status(p_id_process_instance => p_id_process_instance,        
                                 p_code_status         => v_code_status);
     
     -- Process can be restarted only if it has running or error status                            
     IF v_code_status IN (c_status_running, c_status_error, c_status_stuck) THEN
                
       -- Restart process in process instance log
       v_step := 'Restart process in process instance log';
       set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                   p_code_status         => c_status_restart,
                                   p_process_instance    => a_process_instance);

       -- Restart process in workflow engine
       v_step := 'Restart process in workflow engine';
       owner_wfm.lib_etl_workflow_api.restart_process(p_id_workflow_instance => a_process_instance.id_workflow_instance);

       -- Commit
       COMMIT;
       
       -- Find out if there is still failed activity
       v_step := 'Find out if there is still failed activity';
       --  Check if there are some failed acitvities in workflow
       IF owner_wfm.lib_etl_workflow_api.check_error_activity(p_id_workflow_instance => a_process_instance.id_workflow_instance) THEN

         -- Set error for process
         v_step := 'Set error for process';
         set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                     p_code_status         => c_status_error,
                                     p_process_instance    => a_process_instance);
                                     
       END IF;
       
       -- Commit
       COMMIT;
       
       -- Log message for process
       v_step := 'Log message for process';
       -- Set message
       v_text_message := 'Process '||a_process_instance.name_process||' ('||p_id_process_instance||') has been restarted.';
       -- Set output message
       p_text_message := v_text_message;
       -- Log message
       owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                              p_name_activity      => c_proc_name,                         
                                              p_text_message       => v_text_message);
       -- Log process activity
       owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => a_process_instance.date_effective,
                                                      p_id_process_instance  => p_id_process_instance,
                                                      p_name_activity        => c_proc_name,                         
                                                      p_text_message         => v_text_message); 
                                              
    -- Otherwise raise an exception
    ELSE
      
      -- Raise exception
      RAISE ex_wrong_process_status;
      
    END IF;
     
  EXCEPTION
    WHEN ex_wrong_process_status THEN
      -- Set message
      v_text_message := 'Only process with status '||c_status_running||' or '||c_status_error||' can be restarted!';
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
      
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
                                                   
  END restart_process; 
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ERROR_PROCESS
  -- purpose:        Set error for specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE error_process(p_id_process_instance IN INTEGER)
  IS
  
    c_proc_name            VARCHAR2(30) := 'ERROR_PROCESS';
    v_step                 VARCHAR2(500); 
    a_process_instance     t_process_instance;

  BEGIN

     -- Set error for process
     v_step := 'Set error for process';
     set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                 p_code_status         => c_status_error,
                                 p_process_instance    => a_process_instance);
     
     -- Commit
     COMMIT;

     -- Log message 
     v_step := 'Log message';
     -- Set message
     v_text_message := 'Process '||a_process_instance.name_process||' ('||p_id_process_instance||') has failed.';
     -- Log activity
     owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                            p_name_activity      => c_proc_name,                         
                                            p_text_message       => v_text_message);
     -- Log process activity
     owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => a_process_instance.date_effective,
                                                    p_id_process_instance  => p_id_process_instance,
                                                    p_name_activity        => c_proc_name,                         
                                                    p_text_message         => v_text_message); 
       
  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
      -- Raise error
      raise_application_error(-20005, v_text_message);
                                                   
  END error_process;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: STUCK_PROCESS
  -- purpose:        Set stuck for specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE stuck_process(p_id_process_instance IN INTEGER)
  IS
  
    c_proc_name            VARCHAR2(30) := 'STUCK_PROCESS';
    v_step                 VARCHAR2(500); 
    v_code_status          VARCHAR2(10);
    a_process_instance     t_process_instance;

  BEGIN

     -- Get process instance status
     v_step := 'Get process instance status';
     get_process_instance_status(p_id_process_instance => p_id_process_instance,        
                                 p_code_status         => v_code_status);
         
     -- If status of given process instance is not COMPLETE or CANCEL, then proceed
     IF v_code_status NOT IN (c_status_complete, c_status_cancel) THEN

       -- Set stuck for process
       v_step := 'Set stuck for process';
       set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                   p_code_status         => c_status_stuck,
                                   p_process_instance    => a_process_instance);
       
       -- Commit
       COMMIT;

       -- Log message 
       v_step := 'Log message';
       -- Set message
       v_text_message := 'Process '||a_process_instance.name_process||' ('||p_id_process_instance||') is stuck.';
       -- Log activity
       owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                              p_name_activity      => c_proc_name,                         
                                              p_text_message       => v_text_message);
       -- Log process activity
       owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => a_process_instance.date_effective,
                                                      p_id_process_instance  => p_id_process_instance,
                                                      p_name_activity        => c_proc_name,                         
                                                      p_text_message         => v_text_message);
    END IF;
                                                      
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
      -- Raise error
      raise_application_error(-20006, v_text_message);
                                                   
  END stuck_process;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: COMPLETE_PROCESS
  -- purpose:        Complete specified process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE complete_process(p_id_process_instance IN INTEGER)
  IS
  
    c_proc_name            VARCHAR2(30) := 'COMPLETE_PROCESS';
    v_step                 VARCHAR2(500); 
    a_process_instance     t_process_instance;

  BEGIN

     -- Complete process in process instance log
     v_step := 'Complete process in process instance log';
     set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                 p_code_status         => c_status_complete,
                                 p_process_instance    => a_process_instance);

     -- Commit
     COMMIT;

     -- Log message 
     v_step := 'Log message';
     -- Set message
     v_text_message := 'Process '||a_process_instance.name_process||' ('||p_id_process_instance||') has been completed.';
     -- Log activity
     owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                            p_name_activity      => c_proc_name,                         
                                            p_text_message       => v_text_message);
     -- Log process activity
     owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => a_process_instance.date_effective,
                                                    p_id_process_instance  => p_id_process_instance,
                                                    p_name_activity        => c_proc_name,                         
                                                    p_text_message         => v_text_message); 
       
  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
      -- Raise error
      raise_application_error(-20007, v_text_message);
                                                   
  END complete_process; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: COMPLETE_PROCESS
  -- purpose:        Complete specified process from workflow
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE complete_process_wf(p_process_key    IN INTEGER,
                                p_effective_date IN DATE,
                                p_data_type      IN VARCHAR2)
  IS

  BEGIN

    -- Complete process 
    complete_process(p_id_process_instance => p_process_key);
                                                        
  END complete_process_wf; 

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SKIP_ACTIVITY
  -- purpose:        Skip activity for specified process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE skip_activity(p_id_process_instance  IN INTEGER,
                          p_id_workflow_activity IN VARCHAR2,
                          p_name_activity        IN VARCHAR2,
                          p_text_message         OUT VARCHAR2)
  IS
  
    c_proc_name            VARCHAR2(30) := 'SKIP_ACTIVITY';
    v_step                 VARCHAR2(500); 
    a_process_instance     t_process_instance;
    
  BEGIN

     -- Skip process activity in process instance log
     v_step := 'Skip process activity in process instance log';
     set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                 p_code_status         => c_status_skip,
                                 p_process_instance    => a_process_instance);

     -- Skip activity
     v_step := 'Skip activity';
     owner_wfm.lib_etl_workflow_api.skip_activity(p_id_workflow_activity => p_id_workflow_activity,
                                                  p_date_effective       => a_process_instance.date_effective);
                                                  
     -- Commit
     COMMIT;
                                                  
     -- Find out if there is still failed activity
     v_step := 'Find out if there is still failed activity';
     --  Check if there are some failed acitvities in workflow
     IF owner_wfm.lib_etl_workflow_api.check_error_activity(p_id_workflow_instance => a_process_instance.id_workflow_instance) THEN

       -- Set error for process
       v_step := 'Set error for process';
       set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                   p_code_status         => c_status_error,
                                   p_process_instance    => a_process_instance);
                                   
     END IF;
     
     -- Commit
     COMMIT;
     
     -- Log message for process activity
     v_step := 'Log message for process activity';
     -- Set message
     v_text_message := 'Activity has been skipped.';
     -- Set output message
     p_text_message := v_text_message;
     -- Log process activity
     owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => a_process_instance.date_effective,
                                                    p_id_process_instance  => p_id_process_instance,
                                                    p_id_workflow_activity => p_id_workflow_activity,
                                                    p_name_module          => p_name_activity,
                                                    p_name_activity        => c_proc_name,                         
                                                    p_text_message         => v_text_message); 
                                                    
     -- Log message for process
     v_step := 'Log message for process';
     -- Set message
     v_text_message := 'Activity in process '||a_process_instance.name_process||' ('||p_id_process_instance||') has been skipped.';
     -- Log message
     owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                            p_name_activity      => c_proc_name,                         
                                            p_text_message       => v_text_message);

  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
                                                                                                 
  END skip_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_ACTIVITY
  -- purpose:        Restart activity for specified process
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_activity(p_id_process_instance  IN INTEGER,
                             p_id_workflow_activity IN VARCHAR2,
                             p_name_activity        IN VARCHAR2,
                             p_text_message         OUT VARCHAR2)
  IS
  
    c_proc_name            VARCHAR2(30) := 'RESTART_ACTIVITY';
    v_step                 VARCHAR2(500); 
    a_process_instance     t_process_instance;
    
  BEGIN

     -- Restart process activity in process instance log
     v_step := 'Restart process activity in process instance log';
     set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                 p_code_status         => c_status_restart,
                                 p_process_instance    => a_process_instance);

     -- Restart activity
     v_step := 'Restart activity';
     owner_wfm.lib_etl_workflow_api.restart_activity(p_id_workflow_activity => p_id_workflow_activity,
                                                     p_date_effective       => a_process_instance.date_effective);

     -- Commit
     COMMIT;
                                                    
     -- Find out if there is still failed activity
     v_step := 'Find out if there is still failed activity';
     --  Check if there are some failed acitvities in workflow
     IF owner_wfm.lib_etl_workflow_api.check_error_activity(p_id_workflow_instance => a_process_instance.id_workflow_instance) THEN
       
       -- Set error for process
       v_step := 'Set error for process';
       set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                   p_code_status         => c_status_error,
                                   p_process_instance    => a_process_instance);
                                   
     END IF;
     
     -- Commit
     COMMIT;
     
     -- Log message for process activity
     v_step := 'Log message for process activity';
     -- Set message
     v_text_message := 'Activity has been restarted.';
     -- Set output message
     p_text_message := v_text_message;
     -- Log process activity
     owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => a_process_instance.date_effective,
                                                    p_id_process_instance  => p_id_process_instance,
                                                    p_id_workflow_activity => p_id_workflow_activity,
                                                    p_name_module          => p_name_activity,
                                                    p_name_activity        => c_proc_name,                         
                                                    p_text_message         => v_text_message); 

     -- Log message for process
     v_step := 'Log message for process';
     -- Set message
     v_text_message := 'Activity in process '||a_process_instance.name_process||' ('||p_id_process_instance||') has been restarted.';
     -- Log message
     owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                            p_name_activity      => c_proc_name,                         
                                            p_text_message       => v_text_message);

  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);    
                                                                                                                                          
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
  
    c_proc_name            VARCHAR2(30) := 'UNSTUCK_ACTIVITY';
    v_step                 VARCHAR2(500); 
    a_process_instance     t_process_instance;
    
  BEGIN

     -- Unstuck process activity in process instance log
     v_step := 'Unstuck process activity in process instance log';
     set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                 p_code_status         => c_status_unstuck,
                                 p_process_instance    => a_process_instance);
                                 
     -- If activity start type is start before
     IF p_code_activity_start_type = c_activity_start_before THEN

       -- Start before activity
       v_step := 'Start before activity';
       owner_wfm.lib_etl_workflow_api.start_before_activity(p_id_workflow_activity      => p_id_workflow_activity,
                                                            p_date_effective            => a_process_instance.date_effective,                               
                                                            p_id_workflow_element_start => p_id_workflow_element_start);
     
     -- If activity start type is start after  
     ELSIF p_code_activity_start_type = c_activity_start_after THEN

       -- Start after activity
       v_step := 'Start after activity';
       owner_wfm.lib_etl_workflow_api.start_after_activity(p_id_workflow_activity      => p_id_workflow_activity,
                                                           p_date_effective            => a_process_instance.date_effective,                               
                                                           p_id_workflow_element_start => p_id_workflow_element_start);
      
     -- Otherwise
     ELSE
       
       -- Set message
       v_text_message := 'Wrong input parameter. Supported option are '||c_activity_start_before||' or  '||c_activity_start_after;
       -- Return
       RETURN;
       
     END IF;
                                                  
     -- Find out if there is still failed activity
     v_step := 'Find out if there is still failed activity';
     --  Check if there are some failed acitvities in workflow
     IF owner_wfm.lib_etl_workflow_api.check_error_activity(p_id_workflow_instance => a_process_instance.id_workflow_instance) THEN

       -- Set error for process
       v_step := 'Set error for process';
       set_process_instance_status(p_id_process_instance => p_id_process_instance,
                                   p_code_status         => c_status_error,
                                   p_process_instance    => a_process_instance);
                                   
     END IF;
     
     -- Commit
     COMMIT;
     
     -- Log message for process activity
     v_step := 'Log message for process activity';
     -- Set message
     v_text_message := 'Activity has been canceled and process continues '||CASE WHEN p_code_activity_start_type = c_activity_start_before THEN 'before' ELSE 'after' END||' workflow element '||p_id_workflow_element_start||'.';
     -- Set output message
     p_text_message := v_text_message;
     -- Log process activity
     owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => a_process_instance.date_effective,
                                                    p_id_process_instance  => p_id_process_instance,
                                                    p_id_workflow_activity => p_id_workflow_activity,
                                                    p_name_module          => p_name_activity,
                                                    p_name_activity        => c_proc_name,                         
                                                    p_text_message         => v_text_message); 
                                                    
     -- Log message for process
     v_step := 'Log message for process';
     -- Set message
     v_text_message := 'Activity in process '||a_process_instance.name_process||' ('||p_id_process_instance||') has been canceled and process continues '||CASE WHEN p_code_activity_start_type = c_activity_start_before THEN 'before' ELSE 'after' END||' workflow element '||p_id_workflow_element_start||'.';
     -- Log message
     owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                            p_name_activity      => c_proc_name,                         
                                            p_text_message       => v_text_message);

  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
                                                                                                 
  END unstuck_activity;
   
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_PROCESS
  -- purpose:                                      
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_process(p_id_process IN INTEGER,        
                          p_process    IN OUT tt_process)
  IS

    c_proc_name             VARCHAR2(30) := 'START_PROCESS'; 
    v_step                  VARCHAR2(500); 
    v_id_process_instance   INTEGER;
    
  BEGIN

    -- Set id process instance
    v_step := 'Set id process instance';
    SELECT owner_wfm.s_etl_process_instance.nextval INTO v_id_process_instance FROM dual;
    
    -- Set id process instance into process info
    v_step := 'Set id process instance into process info';
    p_process(p_id_process).id_process_instance_new := v_id_process_instance;
    
    -- Set id workflow instance into process info
    v_step := 'Set id process instance into process info';
    p_process(p_id_process).id_workflow_instance_new := c_xna;    

    -- Set process instance
    v_step := 'Set process instance';
    set_process_instance(p_id_process => p_id_process,        
                         p_process    => p_process);
                         
    -- Commit
    COMMIT;

    -- Start process
    v_step := 'Start process';
    owner_wfm.lib_etl_workflow_api.start_process(p_name_workflow        => p_process(p_id_process).name_workflow,
                                                 p_id_process_instance  => p_process(p_id_process).id_process_instance_new,
                                                 p_date_effective       => p_process(p_id_process).date_effective_new,
                                                 p_num_process_priority => p_process(p_id_process).num_process_priority,
                                                 p_id_workflow_instance => p_process(p_id_process).id_workflow_instance_new);
        
    -- Set id workflow instance and process status into process info
    v_step := 'Set id workflow instance and process status into process info';
    p_process(p_id_process).id_workflow_instance_curr := p_process(p_id_process).id_workflow_instance_new;
    
    -- Set status to running
    p_process(p_id_process).code_status_curr := c_status_running;

    -- Set process instance workflow
    v_step := 'Set process instance workflow';
    set_process_instance_wf(p_id_process => p_id_process,        
                            p_process    => p_process);
    
    -- Commit
    COMMIT;

    -- Log message 
    v_step := 'Log message';
    -- Set message
    v_text_message := 'Process '||p_process(p_id_process).name_process||' ('||p_process(p_id_process).id_process_instance_curr||') has been started for effective date '||TO_CHAR( p_process(p_id_process).date_effective_curr, c_date_mask)||'.';
    -- Log activity
    owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                           p_name_activity      => c_proc_name,                         
                                           p_text_message       => v_text_message);
    -- Log process activity
    owner_wfm.lib_etl_log_api.log_process_activity(p_date_effective       => p_process(p_id_process).date_effective_curr,
                                                   p_id_process_instance  => p_process(p_id_process).id_process_instance_curr,
                                                   p_name_activity        => c_proc_name,                         
                                                   p_text_message         => v_text_message); 
                                           
  EXCEPTION                      
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_proc_name||' - ('||v_step||') - '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);                            
      -- Raise error
      RAISE;                                    
        
  END start_process;  
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_PROCESS_AUTO
  -- purpose:        Start of autorun processes
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_process_auto
  IS
  
    c_proc_name       VARCHAR2(30) := 'START_PROCESS_AUTO';
    v_step            VARCHAR2(500); 
    v_dtime_start_new DATE := SYSDATE;
    v_result          BOOLEAN;
    i                 INTEGER;
    a_process         tt_process;
    
    ex_no_start       EXCEPTION;
    
  BEGIN

     -- Get process info
     v_step := 'Get process info';
     get_process_info(p_dtime_start_new => v_dtime_start_new,
                      p_process         => a_process);
                      
     -- Loop throught processes
     v_step := 'Loop throught processes';
     
     -- Set first position
     i := a_process.first;
     WHILE (i IS NOT NULL)
     LOOP
             
       -- If the process should be started automatically 
       IF a_process(i).code_start_method = c_autorun_method THEN
         
         -- Set default values
         v_text_message := NULL;
         v_result       := FALSE; 
     
         BEGIN     
           
           -- Check basic conditions
           v_step := 'Check basic conditions';
           check_basic_conditions(p_id_process        => a_process(i).id_process,
                                  p_process           => a_process,
                                  p_flag_manual_start => c_flag_n,
                                  p_text_message      => v_text_message,
                                  p_result            => v_result);
           
           -- If result is false
           IF NOT v_result THEN
           
             -- Raise expcetion
             RAISE ex_no_start;
             
           END IF;   

           -- Get new effective date
           v_step := 'Get new effective date';
           get_process_date_effective(p_id_process => a_process(i).id_process,
                                      p_process    => a_process);

           -- Check date effective conditions
           v_step := 'Check date effective conditions';
           check_dateeff_conditions(p_id_process   => a_process(i).id_process,
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
           check_process_conditions(p_id_process        => a_process(i).id_process,
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
           check_process_status(p_id_process   => a_process(i).id_process,
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
           start_process(p_id_process => a_process(i).id_process,        
                         p_process    => a_process); 
           
         EXCEPTION
           WHEN ex_no_start THEN
             -- Set message
             v_text_message := 'Process ('||a_process(i).name_process||') cannot be started - '||v_text_message;
             -- Log message 
             owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                                    p_name_activity      => c_proc_name,                         
                                                    p_text_message       => v_text_message);
                                                    
           WHEN OTHERS THEN
             -- Rollback
             ROLLBACK;
             -- Set message
             v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): Process ('||a_process(i).name_process||') cannot be started - '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
             -- Log error
             owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                                    p_name_activity      => c_proc_name,                         
                                                    p_text_message       => v_text_message);
             
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
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): Process ('||a_process(i).name_process||') cannot be started - '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
                                             
  END start_process_auto;   
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_PROCESS_MANUAL
  -- purpose:        Manual start of process
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_process_manual(p_name_process   IN VARCHAR2,
                                 p_date_effective IN DATE,
                                 p_text_message   OUT VARCHAR2)
  IS
  
    c_proc_name       VARCHAR2(30) := 'START_PROCESS_MANUAL';
    v_step            VARCHAR2(500); 
    v_dtime_start_new DATE := SYSDATE;
    v_id_process      INTEGER;
    v_result          BOOLEAN := FALSE;
    a_process         tt_process;
    
    ex_no_start       EXCEPTION;
    
  BEGIN

     -- Get process info
     v_step := 'Get process info';
     get_process_info(p_dtime_start_new => v_dtime_start_new,
                      p_process         => a_process);

     -- Get id process
     v_step := 'Get id process';
     SELECT
        id_process
       INTO
        v_id_process 
     FROM owner_wfm.etl_process
     WHERE name_process = p_name_process;

     -- Check basic conditions
     v_step := 'Check basic conditions';
     check_basic_conditions(p_id_process        => v_id_process,
                            p_process           => a_process,
                            p_flag_manual_start => c_flag_y,
                            p_text_message      => v_text_message,
                            p_result            => v_result);

    -- If result is false
    IF NOT v_result THEN   
          
       -- Raise expcetion
       RAISE ex_no_start;
       
     END IF;                           
    
     -- Set new effective date
     v_step := 'Set new effective date';
     a_process(v_id_process).date_effective_new := p_date_effective;

     -- Check date effective conditions
     v_step := 'Check date effective conditions';
     check_dateeff_conditions(p_id_process   => v_id_process,
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
     check_process_conditions(p_id_process        => v_id_process,
                              p_process           => a_process,
                              p_flag_manual_start => c_flag_y,
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
     check_process_status(p_id_process   => v_id_process,
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
     start_process(p_id_process => v_id_process,        
                   p_process    => a_process);  
                   
     -- Set output message
     p_text_message := v_text_message;     
       
  EXCEPTION
    WHEN ex_no_start THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Process ('||p_name_process||') cannot be started - '||v_text_message;
      -- Set output message
      p_text_message := v_text_message;
      -- Log message 
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_message, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
                                               
   WHEN OTHERS THEN  
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Set output message
      p_text_message := v_text_message;
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
                                                
  END start_process_manual;
    
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_PROCESS_WF
  -- purpose:        Start specified process from workflow
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE start_process_wf(p_process_key    IN INTEGER,
                             p_effective_date IN DATE,
                             p_data_type      IN VARCHAR2)
  IS
 
    c_proc_name       VARCHAR2(30) := 'START_PROCESS_WF';
    v_step            VARCHAR2(500); 
    v_dtime_start_new DATE := SYSDATE;
    v_id_process      INTEGER;
    a_process         tt_process;
    
  BEGIN

     -- Get process info
     v_step := 'Get process info';
     get_process_info(p_dtime_start_new => v_dtime_start_new,
                      p_process         => a_process);

     -- Get id process
     v_step := 'Get id process';
     SELECT
        id_process
       INTO
        v_id_process 
     FROM owner_wfm.etl_process
     WHERE name_process = p_data_type;

     -- Set new effective date
     v_step := 'Set new effective date';
     a_process(v_id_process).date_effective_new := p_effective_date;
     
     -- Start process
     v_step := 'Start process'; 
     start_process(p_id_process => v_id_process,        
                   p_process    => a_process);  
       
  EXCEPTION                                              
   WHEN OTHERS THEN  
      -- Rollback
      ROLLBACK;
      -- Set message
      v_text_message := 'Error in '||c_mod_name||'.'||c_proc_name||' - ('||v_step||'): '||SUBSTR(dbms_utility.format_error_stack, 1, 1500);
      -- Log error
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_proc_name,                         
                                             p_text_message       => v_text_message);
      -- Raise error
      raise_application_error(-20008, v_text_message);
                                                   
  END start_process_wf; 
  
END lib_etl_process_run;
/
