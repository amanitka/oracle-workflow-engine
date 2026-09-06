CREATE OR REPLACE PACKAGE OWNER_WFM.lib_etl_process_monitoring IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Workflow Team
  -- created: 15.11.2018
  -- purpose: Package for monitoring purpose
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: MAIN_PROCESS_MONITORING
  -- purpose:        main process for monitoring - checking duration, stuck, start in window
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE main_process_monitoring;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ADJUST_MONITORING
  -- purpose:        Procedure generating metadata for monitoring duration of activities
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE adjust_monitoring(p_process_key    IN NUMBER,
                              p_effective_date IN DATE,
                              p_data_type      IN VARCHAR2);   
                                

end lib_etl_process_monitoring;
/
CREATE OR REPLACE PACKAGE BODY OWNER_WFM.lib_etl_process_monitoring IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_code_error_status         CONSTANT VARCHAR2(30) := 'ERROR';  
  c_code_entity               CONSTANT VARCHAR2(15) := 'PROCESS';
  c_status_new                CONSTANT VARCHAR2(10) := 'NEW';
  c_status_running            CONSTANT VARCHAR2(10) := 'RUNNING';
  c_flag_N                    CONSTANT VARCHAR2(1)  := 'N';
  c_flag_Y                    CONSTANT VARCHAR2(1)  := 'Y';
  c_code_XAP                  CONSTANT VARCHAR2(3)  := 'XAP';
  c_minus_two                 CONSTANT INTEGER      := -2;
  c_responsible_group_default CONSTANT VARCHAR2(10)  := 'HCI';
  c_module_name               CONSTANT VARCHAR2(20) := 'MONITORING_MODULE';
  c_log_type_error            CONSTANT VARCHAR2(10) := 'ERROR';
  c_code_error_stuck          CONSTANT VARCHAR2(30) := 'STUCK';
  c_sla_incoming_queue        CONSTANT NUMBER := TO_NUMBER(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_SLA_INCOMING_QUEUE',
                                                                                                                     p_code_group     => 'Monitoring'));
  c_sla_outgoing_queue        CONSTANT NUMBER := TO_NUMBER(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_SLA_OUTGOING_QUEUE',
                                                                                                                     p_code_group     => 'Monitoring'));
  c_sla_stuck_process         CONSTANT NUMBER := TO_NUMBER(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_SLA_STUCK_PROCESS',
                                                                                                                     p_code_group     => 'Monitoring'));
  c_sla_running_process       CONSTANT NUMBER := TO_NUMBER(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_SLA_RUNNING_PROCESS',
                                                                                                                     p_code_group     => 'Monitoring'));
  c_fact_ext_time             CONSTANT NUMBER := TO_NUMBER(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_ADJUST_FACT_EXT_TIME',
                                                                                                                     p_code_group     => 'Monitoring'));
  c_dimension_ext_time        CONSTANT NUMBER := TO_NUMBER(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_ADJUST_DIM_EXT_TIME',
                                                                                                                     p_code_group     => 'Monitoring'));
  c_codelist_ext_time         CONSTANT NUMBER := TO_NUMBER(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_ADJUST_CODELIST_EXT_TIME',
                                                                                                                     p_code_group     => 'Monitoring'));
  c_refr_ext_time             CONSTANT NUMBER := TO_NUMBER(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_ADJUST_REFR_EXT_TIME',
                                                                                                                     p_code_group     => 'Monitoring'));
  c_dateformat                CONSTANT VARCHAR2(20) := owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'QUEUE_ENQTIME_TIMEZONE',
                                                                                                                 p_code_group     => 'ORACLE_ENV');
  c_tz                        CONSTANT VARCHAR2(60) := owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'DEFAULT_TIMEZONE',
                                                                                                                 p_code_group     => 'ORACLE_ENV');
  v_text_check_message        VARCHAR2(4000 CHAR);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_ACTIVITY_DURATION
  -- purpose:        check duration of running activities
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE check_activity_duration
  
  IS  
    v_proc_name              VARCHAR2(30 CHAR) := 'CHECK_ACTIVITY_DURATION';
    v_code_error_type        VARCHAR2(30 CHAR) := 'DURATION';

    CURSOR c_running_activity IS
      WITH base AS (SELECT
                       id_process_instance, 
                       id_workflow_activity, 
                       id_process,
                       name_process,
                       name_activity, 
                       name_module,
                       date_effective, 
                       num_process_severity, 
                       code_responsible_group,
                       dtime_inserted,
                       CASE WHEN name_activity     LIKE 'FT%'                   THEN 'FACT'
                            WHEN name_activity     LIKE 'DCT%' 
                                  OR name_activity LIKE 'DHT%' 
                                  OR name_activity LIKE 'DIM%'                  THEN 'DIMENSION'
                            WHEN name_activity     LIKE 'CLT%'                  THEN 'CODELIST'
                            WHEN name_activity     LIKE 'NOTIFY%'               THEN 'NOTIFICATION'
                            WHEN name_process      LIKE 'INT_MAIN_%' ESCAPE '\' THEN 'REFRESH'
                            ELSE 'OTHER' 
                       END AS instance_type    
                    FROM (SELECT
                             runact.id_process_instance, 
                             runact.id_workflow_activity, 
                             p.id_process,
                             p.name_process,
                             wfacti.name_activity,
                             runact.name_module, 
                             runact.date_effective, 
                             p.num_process_severity, 
                             p.code_responsible_group,
                             runact.dtime_inserted
                          FROM owner_wfm.etl_wf_running_activity runact
                          JOIN owner_wfm.etl_process_instance pi ON pi.id_process_instance = runact.id_process_instance
                                                                AND pi.date_effective = runact.date_effective
                          JOIN owner_wfm.etl_process p ON p.id_process = pi.id_process
                          LEFT JOIN owner_wfe.v_wf_run_activity_instance wfacti ON wfacti.id_workflow_activity_instance = runact.id_workflow_activity
                                                                               AND wfacti.date_effective = runact.date_effective 
                          )
                    )
      SELECT
         id_process_instance    AS id_entity_instance, 
         id_workflow_activity   AS id_entity_activity, 
         id_process             AS id_entity,
         date_effective         AS date_effective, 
         'Module '||name_activity||' in '||name_process||' is running over the limit! (Limit is '||TRUNC(num_new_runtime_sla)||' min.)' AS text_message, 
         num_process_severity   AS num_severity,
         code_responsible_group AS code_responsible_group
      FROM (SELECT
               base.id_process_instance, 
               base.id_workflow_activity, 
               base.id_process,
               base.name_process,
               base.name_activity, 
               base.date_effective, 
               base.dtime_inserted,
               mon.num_runtime_sla,
               CASE WHEN base.instance_type = 'FACT'         THEN NVL(mon.num_runtime_sla, c_fact_ext_time)
                    WHEN base.instance_type = 'DIMENSION'    THEN NVL(mon.num_runtime_sla, c_dimension_ext_time)
                    WHEN base.instance_type = 'CODELIST'     THEN NVL(mon.num_runtime_sla, c_codelist_ext_time)
                    WHEN base.instance_type = 'NOTIFICATION' THEN NVL(mon.num_runtime_sla, c_codelist_ext_time)
                    WHEN base.instance_type = 'REFRESH'      THEN NVL(mon.num_runtime_sla, c_refr_ext_time)
                    WHEN base.instance_type = 'OTHER'        THEN NVL(mon.num_runtime_sla, c_refr_ext_time)
               END AS num_new_runtime_sla,
               etl_module.name_object, 
               base.num_process_severity, 
               base.code_responsible_group, 
               CASE WHEN mon_log.id_entity_activity IS NULL THEN c_flag_N
                    ELSE c_flag_Y
               END AS flag_in_monitoring
            -- Running activities on db
            FROM base
            -- Get activity SLA  
            LEFT JOIN owner_wfm.etl_process_monitoring mon ON mon.name_activity = base.name_activity
                                                          AND mon.id_process = base.id_process
                                                          AND mon.flag_deleted <> 'Y'
            -- Get package and procedure name  
            LEFT JOIN owner_wfm.etl_module etl_module ON etl_module.name_module = base.name_module
            LEFT JOIN owner_wfm.etl_monitoring_log mon_log ON mon_log.code_entity = c_code_entity
                                                          AND mon_log.id_entity_instance = TO_CHAR(base.id_process_instance)
                                                          AND mon_log.id_entity_activity = base.id_workflow_activity
                                                          AND mon_log.date_effective = base.date_effective
                                                          AND mon_log.code_error_type = v_code_error_type
            )         
      WHERE flag_in_monitoring <> 'Y'
        AND (SYSDATE - dtime_inserted) * 1440 > num_new_runtime_sla;

  BEGIN

    -- Loop through overtime activity
    FOR i IN c_running_activity
    LOOP
          
      -- log error info
      owner_wfm.lib_etl_monitoring_log_api.log_error(p_date_effective            => i.date_effective,
                                                     p_code_entity               => c_code_entity,
                                                     p_id_entity                 => i.id_entity,
                                                     p_id_entity_instance        => i.id_entity_instance,
                                                     p_id_entity_activity        => i.id_entity_activity,
                                                     p_code_error_type           => v_code_error_type,
                                                     p_text_message              => i.text_message,
                                                     p_text_error_message        => NULL,
                                                     p_num_severity              => i.num_severity,
                                                     p_code_responsibility_group => i.code_responsible_group);
    END LOOP;
    
  EXCEPTION
    WHEN OTHERS THEN 
      v_text_check_message := c_module_name||': procedure '||v_proc_name||' Error occured - '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_module_name||'.'||v_proc_name,                         
                                             p_text_message       => v_text_check_message);
      ROLLBACK;      

  END check_activity_duration;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CONFIRM_ACTIVITY_DURATION
  -- purpose:        confirm logged activity duration
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE confirm_activity_duration
  
  IS  
    v_proc_name              VARCHAR2(30 CHAR) := 'CONFIRM_ACTIVITY_DURATION';
    v_code_error_type        VARCHAR2(30 CHAR) := 'DURATION';

    CURSOR c_process IS
        SELECT 
           date_effective,
           id_entity,
           id_entity_instance,
           id_entity_activity
          FROM owner_wfm.etl_monitoring_log
         WHERE flag_confirmed  = c_flag_N
           AND code_status     = c_code_error_status
           AND code_error_type = v_code_error_type
           AND id_entity_activity not in (
               select id_workflow_activity from owner_wfm.etl_wf_running_activity
           );

  BEGIN

   -- Loop through processes and set array
   FOR i IN c_process
        LOOP

          -- log error info
           owner_wfm.lib_etl_monitoring_log_api.confirm_error(p_date_effective     => i.date_effective,
                                                              p_code_entity        => c_code_entity,
                                                              p_id_entity          => i.id_entity,
                                                              p_id_entity_instance => i.id_entity_instance,
                                                              p_id_entity_activity => i.id_entity_activity,
                                                              p_code_error_type    => v_code_error_type);
    END LOOP;

    EXCEPTION
      WHEN OTHERS THEN 

        v_text_check_message := c_module_name||': procedure '||v_proc_name||': Error occured - '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
        owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                               p_name_activity      => c_module_name||'.'||v_proc_name,                         
                                               p_text_message       => v_text_check_message);
        ROLLBACK;      

  END confirm_activity_duration;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_ACTIVITY_IN_QUEUE
  -- purpose:        check activities waiting in INCOMING queue or zombies in OUTGOING queue
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE check_activity_in_queue
  
  IS  
    
    v_proc_name                 VARCHAR2(30 CHAR) := 'CHECK_ACTIVITY_IN_QUEUE';
    c_aq_incoming               VARCHAR2(20 CHAR) := 'AQ_INCOMING';
    c_aq_outgoing               VARCHAR2(20 CHAR) := 'AQ_OUTGOING';
    c_wf_aq_activity_inst_in    CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aq_activity_inst_in;
    c_wf_aqn_activity_inst_in_e CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aqn_activity_inst_in_e;
    c_wf_aq_activity_inst_out   CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aq_activity_inst_out;
    v_code_error_type           VARCHAR2(30 CHAR) := 'QUEUE';
    c_severity_default          INTEGER           := 3;

    CURSOR c_queue_activity IS
      SELECT
         NVL(inst.id_process_instance,c_minus_two)         AS id_entity_instance,
         NVL(db.id_workflow_activity,c_minus_two)          AS id_entity_activity,
         NVL(p.id_process,c_minus_two)                     AS id_entity,
         NVL(inst.date_effective, DATE'1000-01-01')        AS date_effective,
         'AQ Warning: '||CASE WHEN alog.name_module IS NULL THEN 'Activity for unknown module in process '||p.name_process
                              ELSE 'Activity for module '||alog.name_module||' in process '||p.name_process||' ['|| etl_module.name_object ||'] '
                         END
                       ||CASE WHEN db.code_queue_type = c_aq_incoming THEN 'is waiting in '||c_wf_aq_activity_inst_out||' for processing more than '||TO_CHAR(c_sla_incoming_queue)||' min, please check!'
                              WHEN db.code_queue_type = c_aq_outgoing THEN 'stays in '||c_wf_aq_activity_inst_in||' more than '||TO_CHAR(c_sla_outgoing_queue)||' min, looks like zombie state, please check!'
                         END AS text_message,
         NVL(p.num_process_severity,c_severity_default)    AS num_severity,
         NVL(p.code_responsible_group,c_responsible_group_default) AS code_responsible_group
      FROM (-- Incoming queue for workflow manager (Outgoing queue for workflow engine)
            SELECT
              id_workflow_activity_instance AS id_workflow_activity,
              id_process_instance           AS id_process_instance,
              date_effective                AS date_effective,
              name_module                   AS name_module,
              c_aq_incoming                 AS code_queue_type
            FROM owner_wfe.v_wf_aq_activity_inst_out
            WHERE (SYSDATE - CAST(FROM_TZ(dtime_enqueue, c_dateformat) AT TIME ZONE CAST(c_tz as VARCHAR2(60)) AS DATE)) * 1440 > c_sla_incoming_queue
              UNION ALL 
            -- Outgoing queue for workflow manager (Incoming queue for workflow engine)
            SELECT
              id_workflow_activity_instance AS id_workflow_activity,
              id_process_instance           AS id_process_instance,
              date_effective                AS date_effective,
              name_module                   AS name_module,
              c_aq_outgoing                 AS code_queue_type
            FROM owner_wfe.v_wf_aq_activity_inst_in t
            WHERE (SYSDATE - CAST(FROM_TZ(dtime_enqueue, c_dateformat) AT TIME ZONE CAST(c_tz as VARCHAR2(60)) AS DATE)) * 1440 > c_sla_outgoing_queue 
              -- Errors in outgoing queue are monitored in lib workflow queueu (stuck activity)
              AND name_queue != c_wf_aqn_activity_inst_in_e         
          ) db
      LEFT JOIN owner_wfm.etl_process_instance_activity alog ON alog.id_process_instance = db.id_process_instance
                                                            AND alog.date_effective = db.date_effective
                                                            AND alog.id_workflow_activity = TO_CHAR(db.id_workflow_activity)
                                                            AND alog.name_activity = 'RUN_ACTIVITY'
      LEFT JOIN owner_wfm.etl_process_instance inst ON inst.id_process_instance = db.id_process_instance
                                                   AND inst.date_effective = db.date_effective
      LEFT JOIN owner_wfm.etl_process p ON p.id_process = inst.id_process
      LEFT JOIN owner_wfm.etl_module etl_module ON etl_module.name_module = NVL(db.name_module, alog.name_module)
      LEFT JOIN owner_wfm.etl_monitoring_log mon_log ON mon_log.code_entity = c_code_entity
                                                    AND mon_log.id_entity_instance = TO_CHAR(db.id_process_instance)
                                                    AND mon_log.id_entity_activity = TO_CHAR(db.id_workflow_activity)
                                                    AND mon_log.date_effective = db.date_effective
      WHERE mon_log.id_entity_activity IS NULL;
            
  BEGIN

    -- Loop through processes and set array
    FOR i IN c_queue_activity
    LOOP
      
      -- log error info
      owner_wfm.lib_etl_monitoring_log_api.log_error(p_date_effective            => i.date_effective,
                                                     p_code_entity               => c_code_entity,
                                                     p_id_entity                 => i.id_entity,
                                                     p_id_entity_instance        => i.id_entity_instance,
                                                     p_id_entity_activity        => i.id_entity_activity,
                                                     p_code_error_type           => v_code_error_type,
                                                     p_text_message              => i.text_message,
                                                     p_text_error_message        => NULL,
                                                     p_num_severity              => i.num_severity,
                                                     p_code_responsibility_group => i.code_responsible_group);

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN 
      v_text_check_message := c_module_name||': procedure '||v_proc_name||': Error occured - '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_module_name||'.'||v_proc_name,                         
                                             p_text_message       => v_text_check_message);
      ROLLBACK;      

  END check_activity_in_queue;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CONFIRM_ACTIVITY_IN_QUEUE
  -- purpose:        confirm logged activities which have been in INCOMING/OUTCOMING AQ
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE confirm_activity_in_queue
  
  IS  
    
    v_proc_name                 VARCHAR2(30 CHAR) := 'CONFIRM_ACTIVITY_IN_QUEUE';
    v_code_error_type           VARCHAR2(30 CHAR) := 'QUEUE';
    c_wf_aqn_activity_inst_in_e CONSTANT VARCHAR2(55) := owner_wfe.lib_wf_constant.c_wf_aqn_activity_inst_in_e;

    CURSOR c_process IS
        SELECT 
           date_effective,
           id_entity,
           id_entity_instance,
           id_entity_activity
          FROM owner_wfm.etl_monitoring_log
         WHERE flag_confirmed  = c_flag_N
           AND code_status     = c_code_error_status
           AND code_error_type = v_code_error_type
           AND id_entity_activity NOT IN (-- Incoming queue for workflow manager (Outgoing queue for workflow engine)
                                          SELECT 
                                             id_workflow_activity_instance AS id_workflow_activity
                                          FROM owner_wfe.v_wf_aq_activity_inst_out t
                                            UNION ALL 
                                          -- Outgoing queue for workflow manager (Incoming queue for workflow engine)
                                          SELECT
                                             id_workflow_activity_instance AS id_workflow_activity
                                          FROM owner_wfe.v_wf_aq_activity_inst_in
                                          -- Errors in outgoing queue are monitored in lib workflow queueu (stuck activity)
                                          WHERE name_queue != c_wf_aqn_activity_inst_in_e
                                          );

  BEGIN

   -- Loop through processes and set array
   FOR i IN c_process
        LOOP

          -- log error info
           owner_wfm.lib_etl_monitoring_log_api.confirm_error(p_date_effective     => i.date_effective,
                                                              p_code_entity        => c_code_entity,
                                                              p_id_entity          => i.id_entity,
                                                              p_id_entity_instance => i.id_entity_instance,
                                                              p_id_entity_activity => i.id_entity_activity,
                                                              p_code_error_type    => v_code_error_type);
    END LOOP;

    EXCEPTION
      WHEN OTHERS THEN 

        v_text_check_message := c_module_name||': procedure '||v_proc_name||': Error occured - '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
        owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                               p_name_activity      => c_module_name||'.'||v_proc_name,                         
                                               p_text_message       => v_text_check_message);
        ROLLBACK;      

  END confirm_activity_in_queue;  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_PROCESS_START_WINDOW
  -- purpose:        Check whether process start in window
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE check_process_start_window
  
  IS  
    v_proc_name              VARCHAR2(30 CHAR) := 'CHECK_PROCESS_START_WINDOW';
    v_code_error_type        VARCHAR2(30 CHAR) := 'WINDOW';

  CURSOR c_process IS
          SELECT
            id_process_instance   AS id_entity_instance, 
            id_workflow_activity  AS id_entity_activity, 
            id_process            AS id_entity,
            date_effective, 
            text_message, 
            num_process_severity  AS num_severity, 
            code_responsible_group
          FROM (
            SELECT
                m.id_process_instance,
                m.id_workflow_activity,
                m.id_process,
                m.date_effective_real AS date_effective,
                'MON Window warning: Process '||m.name_module||' did not start at '||to_char(m.dtime_start_sla,'dd.mm.yyyy hh24:mi')||'!' AS text_message,
                m.num_process_severity,
                m.code_responsible_group
             FROM (SELECT p.id_process_instance,
                          p.id_workflow_activity,
                          p.name_process,
                          p.id_process,
                          p.name_module,
                          p.date_effective AS date_effective_planned,
                          p.date_effective_real,
                          p.dtime_start_sla,
                          p.next_lp_date,
                          p.prev_lp_date_1,
                          p.prev_lp_date_2,
                          p.num_process_severity,
                          p.code_responsible_group
                   FROM (SELECT id_process_instance,
                                id_workflow_activity,
                                name_process,
                                id_process,
                                name_module,
                                dtime_start_sla + num_start_time_delay as dtime_start_sla,
                                RANK() OVER (PARTITION BY name_process ORDER BY date_effective DESC) planned_eff_date_order,
                                LAG(date_effective)    OVER (PARTITION BY name_process ORDER BY date_effective DESC) next_lp_date,
                                LEAD(date_effective)   OVER (PARTITION BY name_process ORDER BY date_effective DESC) prev_lp_date_1,
                                LEAD(date_effective,2) OVER (PARTITION BY name_process ORDER BY date_effective DESC) prev_lp_date_2,
                                date_effective,
                                date_effective_real,
                                flag_plan_status,
                                num_process_severity,
                                code_responsible_group
                         FROM (-- Identify process that need to be checked
                               SELECT DISTINCT p.id_process,
                                               lp.id_process_instance,
                                               null as id_workflow_activity,
                                               pm.name_activity as name_module,
                                               (pp.date_effective + (pm.dtime_start_sla - TRUNC(pm.dtime_start_sla))) + NVL(num_start_time_offset, 0) AS dtime_start_sla,
                                               p.name_process,
                                               lp.date_effective,
                                               pp.date_effective as date_effective_real,
                                               pp.flag_plan_status,
                                               p.num_process_severity,
                                               p.code_responsible_group,
                                               NVL(pmo.num_start_time_delay / 1440, 0) AS num_start_time_delay
                               FROM owner_wfm.etl_process_monitoring pm
                               JOIN owner_wfm.etl_process p ON pm.name_activity = p.name_process 
                               --exclude processes which have current instance in error
                               JOIN owner_wfm.etl_process_status s ON s.id_process = p.id_process
                                                                  AND s.code_status not in ('ERROR')
                               JOIN owner_wfm.etl_process_plan pp ON pp.id_process = p.id_process
                                                                 AND pp.date_effective >= trunc(SYSDATE)-3 
                                                                 AND pp.date_effective <= trunc(SYSDATE)
                               LEFT JOIN owner_wfm.etl_process_instance lp ON pp.id_process = lp.id_process
                                                                          AND lp.date_effective = pp.date_effective
                               LEFT JOIN owner_wfm.etl_process_monitoring_outage pmo ON pmo.date_effective = pp.date_effective
                                                                                    AND pmo.flag_deleted <> 'Y' 
                               WHERE pm.dtime_start_sla IS NOT NULL
                                 AND pm.flag_deleted <> c_flag_Y
                                 AND p.flag_deleted <> c_flag_Y
                                 AND pp.flag_plan_status <> c_flag_N
                               ) 
                         ) p
                   WHERE date_effective IS NULL 
                     AND planned_eff_date_order < 3
                     AND (-- N, N, Y
                          (next_lp_date IS NULL AND prev_lp_date_1 IS NULL AND prev_lp_date_2 IS NOT NULL)
                          -- N, Y, Y
                          OR (next_lp_date IS NULL AND prev_lp_date_1 IS NOT NULL AND prev_lp_date_2 IS NOT NULL)
                          -- N, Y, N
                          OR (next_lp_date IS NULL AND prev_lp_date_1 IS NOT NULL AND prev_lp_date_2 IS NULL)
                          -- N, N, N
                          OR (next_lp_date IS NULL AND prev_lp_date_1 IS NULL AND prev_lp_date_2 IS NULL))
                   ) m
             LEFT JOIN owner_wfm.etl_monitoring_log n ON n.code_entity = c_code_entity
                                                     AND n.id_entity = TO_CHAR(m.id_process)
                                                     AND n.date_effective = m.date_effective_real
                                                     AND n.code_error_type = v_code_error_type
             WHERE n.id_entity IS NULL
               -- return only if the limit is passed beyond
               AND SYSDATE >= m.dtime_start_sla
             ORDER BY m.name_process, m.date_effective_real
          );  

    BEGIN

        -- Loop through processes and set array
        FOR i IN c_process
        LOOP

          -- log error info
           owner_wfm.lib_etl_monitoring_log_api.log_error(p_date_effective            => i.date_effective,
                                                          p_code_entity               => c_code_entity,
                                                          p_id_entity                 => i.id_entity,
                                                          p_id_entity_instance        => i.id_entity_instance,
                                                          p_id_entity_activity        => i.id_entity_activity,
                                                          p_code_error_type           => v_code_error_type,
                                                          p_text_message              => i.text_message,
                                                          p_text_error_message        => NULL,
                                                          p_num_severity              => i.num_severity,
                                                          p_code_responsibility_group => i.code_responsible_group);

    END LOOP;
 
    EXCEPTION
      WHEN OTHERS THEN 

        v_text_check_message := c_module_name||': procedure '||v_proc_name||': Error occured - '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
        owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                               p_name_activity      => c_module_name||'.'||v_proc_name,                         
                                               p_text_message       => v_text_check_message);
        ROLLBACK;      

  END check_process_start_window;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CONFIRM_PROCESS_START_WINDOW
  -- purpose:        Confirm errors for processes which started later
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE confirm_process_start_window
  
  IS  
    v_proc_name              VARCHAR2(30 CHAR) := 'confirm_process_start_window';
    v_code_error_type        VARCHAR2(30 CHAR) := 'WINDOW';

    CURSOR c_process IS
        SELECT 
           l.date_effective,
           l.id_entity,
           l.id_entity_instance,
           l.id_entity_activity
          FROM owner_wfm.etl_monitoring_log l
          JOIN owner_wfm.etl_process_status s 
            ON s.id_process = TO_CHAR(l.id_entity)
           AND l.date_effective <= s.date_effective
         WHERE l.flag_confirmed  = c_flag_N
           AND l.code_status     = c_code_error_status
           AND l.code_error_type = v_code_error_type
           AND l.code_entity     = c_code_entity;

  BEGIN

   -- Loop through processes and set array
   FOR i IN c_process
        LOOP

          -- Confirm error info
           owner_wfm.lib_etl_monitoring_log_api.confirm_error(p_date_effective     => i.date_effective,
                                                              p_code_entity        => c_code_entity,
                                                              p_id_entity          => i.id_entity,
                                                              p_id_entity_instance => i.id_entity_instance,
                                                              p_id_entity_activity => i.id_entity_activity,
                                                              p_code_error_type    => v_code_error_type);
    END LOOP;

    EXCEPTION
      WHEN OTHERS THEN 

        v_text_check_message := c_module_name||': procedure '||v_proc_name||': Error occured - '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
        owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                               p_name_activity      => c_module_name||'.'||v_proc_name,                         
                                               p_text_message       => v_text_check_message);
        ROLLBACK;      

  END confirm_process_start_window;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_PROCESS_STUCK
  -- purpose:        Check process stuck in NEW or RUNNING status
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE check_process_stuck
  
  IS  
    
    v_proc_name VARCHAR2(30 CHAR) := 'CHECK_PROCESS_STUCK';

  CURSOR c_process IS
    WITH stuck_process AS (SELECT
                              ps.id_process,
                              ps.name_process,
                              ps.date_effective,
                              ps.id_process_instance,
                              ps.code_status
                           FROM owner_wfm.etl_process_status ps
                           WHERE (-- Process is in status RUNNING
                                  ps.code_status = c_status_running
                                  AND ps.dtime_start + c_sla_stuck_process / 1440 < SYSDATE
                                  -- There is no running activity at this moment
                                  AND NOT EXISTS (SELECT 1
                                                  FROM owner_wfm.etl_wf_running_activity ra 
                                                  WHERE ra.date_effective = ps.date_effective
                                                    AND ra.id_process_instance = ps.id_process_instance
                                                  )
                                  -- There is no activity log entry in specified time
                                  AND NOT EXISTS (SELECT 1
                                                  FROM owner_wfm.etl_process_instance_activity pia
                                                  WHERE pia.date_effective = ps.date_effective
                                                    AND pia.id_process_instance = ps.id_process_instance
                                                    AND pia.dtime_inserted > SYSDATE - c_sla_running_process / 1440
                                                  )
                                  ) 
                              OR (-- Process is in status NEW longer then specified limit
                                  ps.code_status = c_status_new
                                  AND ps.dtime_start + c_sla_stuck_process / 1440 < SYSDATE
                                  ) 
                           )
    SELECT 
        sp.id_process_instance,
        sp.id_process,
        sp.name_process,
        sp.date_effective,
        sp.code_status,
        p.num_process_severity,
        p.code_responsible_group
    FROM stuck_process sp
    JOIN owner_wfm.etl_process p ON p.id_process = sp.id_process
                                AND p.flag_deleted <> 'Y'
    LEFT JOIN owner_wfm.etl_monitoring_log mon_log ON mon_log.code_entity = c_code_entity
                                                  AND mon_log.id_entity_instance = TO_CHAR(sp.id_process_instance)
                                                  AND mon_log.id_entity_activity = c_code_XAP
                                                  AND mon_log.date_effective = sp.date_effective
                                                  AND mon_log.code_error_type = c_code_error_stuck
    WHERE mon_log.id_entity_activity IS NULL;
              
  BEGIN

    -- Loop through processes and set array
    FOR i IN c_process
    LOOP

      -- Set message
      v_text_check_message := 'Process '||i.name_process||' is stuck in '||i.code_status||' state and probably not running! It will be necessary to check logs for more information.';

      -- log error info
      owner_wfm.lib_etl_monitoring_log_api.log_error(p_date_effective            => i.date_effective,
                                                     p_code_entity               => c_code_entity,
                                                     p_id_entity                 => i.id_process,
                                                     p_id_entity_instance        => i.id_process_instance,
                                                     p_id_entity_activity        => c_code_XAP,
                                                     p_code_error_type           => c_code_error_stuck,
                                                     p_text_message              => v_text_check_message,
                                                     p_text_error_message        => NULL,
                                                     p_num_severity              => i.num_process_severity,
                                                     p_code_responsibility_group => i.code_responsible_group);

    END LOOP;
 
  EXCEPTION
    WHEN OTHERS THEN 
      ROLLBACK;
      v_text_check_message := c_module_name||': procedure '||v_proc_name||': Error occured - '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_module_name||'.'||v_proc_name,                         
                                             p_text_message       => v_text_check_message);  

  END check_process_stuck;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CONFIRM_PROCESS_STUCK
  -- purpose:        Confirm errors for stuck processes
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE confirm_process_stuck
  
  IS  
    
    v_proc_name VARCHAR2(30 CHAR) := 'CONFIRM_PROCESS_STUCK';

    CURSOR c_process IS
      WITH monitoring_log AS (SELECT
                                 date_effective,
                                 id_entity,
                                 id_entity_instance,
                                 id_entity_activity
                              FROM owner_wfm.etl_monitoring_log
                              WHERE flag_confirmed     = c_flag_N
                                AND code_status        = c_code_error_status
                                AND code_error_type    = c_code_error_stuck
                                AND id_entity_activity = c_code_XAP
                              )
      SELECT
         l.date_effective,
         l.id_entity,
         l.id_entity_instance,
         l.id_entity_activity
      FROM monitoring_log l
      JOIN owner_wfm.etl_process_status ps ON ps.id_process = TO_NUMBER(l.id_entity)
      WHERE ps.code_status != c_status_new
        AND (-- There is running activity at this moment
             EXISTS (SELECT 1
                     FROM owner_wfm.etl_wf_running_activity ra 
                     WHERE ra.date_effective = l.date_effective
                       AND ra.id_process_instance = TO_NUMBER(l.id_entity_instance)
                     )
             -- There is activity log entry in specified time
             OR EXISTS (SELECT 1
                        FROM owner_wfm.etl_process_instance_activity pia
                        WHERE pia.date_effective = l.date_effective
                          AND pia.id_process_instance = TO_NUMBER(l.id_entity_instance)
                          AND pia.dtime_inserted > SYSDATE - c_sla_running_process / 1440
                        )
             );

  BEGIN

    -- Loop through processes and set array
    FOR i IN c_process
    LOOP

      -- Confirm error info
      owner_wfm.lib_etl_monitoring_log_api.confirm_error(p_date_effective     => i.date_effective,
                                                         p_code_entity        => c_code_entity,
                                                         p_id_entity          => i.id_entity,
                                                         p_id_entity_instance => i.id_entity_instance,
                                                         p_id_entity_activity => i.id_entity_activity,
                                                         p_code_error_type    => c_code_error_stuck);
                                                         
    END LOOP;
       
  EXCEPTION
    WHEN OTHERS THEN 

      v_text_check_message := c_module_name||': procedure '||v_proc_name||': Error occured - '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_module_name||'.'||v_proc_name,                         
                                             p_text_message       => v_text_check_message);
      ROLLBACK;      

  END confirm_process_stuck;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: MAIN_PROCESS_MONITORING
  -- purpose:        main procedure, checking and confirm duration, waiting or stucking activities in AQ, STARTs in window
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE main_process_monitoring
  IS

      v_proc_name  varchar2(30) := 'MAIN_PROCESS_MONITORING';
      v_step       varchar2(400);
  BEGIN
      
      v_step := 'Confirm duration of running activities';  
      confirm_activity_duration;

      v_step := 'Check duration of running activities';
      check_activity_duration;

      v_step := 'Check activities waiting in INCOMING queue or zombies in OUTGOING queue';  
      check_activity_in_queue;

      v_step := 'Confirm logged activities which have been in INCOMING/OUTCOMING AQ';
      confirm_activity_in_queue;

      v_step := 'Check whether process start in window';
      check_process_start_window;

      v_step := 'Confirm errors for processes which started later';  
      confirm_process_start_window;
      
      v_step := 'Check process stuck in NEW or RUNNING status';
      check_process_stuck;

      v_step := 'Confirm errors for stuck processes';  
      confirm_process_stuck;

  EXCEPTION
    WHEN OTHERS THEN 
      v_text_check_message := c_module_name||'.'||v_proc_name||': '||v_step||'- error occured - '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_module_name,                         
                                             p_text_message       => v_text_check_message);
      
      ROLLBACK;
  END main_process_monitoring;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: ADJUST_MONITORING
  -- purpose:        Procedure generating metadata for monitoring duration of activities
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE adjust_monitoring(p_process_key    IN NUMBER,
                              p_effective_date IN DATE,
                              p_data_type      IN VARCHAR2)
  IS

    c_fact_ext_time               CONSTANT NUMBER := to_number(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_ADJUST_FACT_EXT_TIME',
                                                                                                                         p_code_group     => 'Monitoring'));
    c_dimension_ext_time          CONSTANT NUMBER := to_number(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_ADJUST_DIM_EXT_TIME',
                                                                                                                         p_code_group     => 'Monitoring'));
    c_codelist_ext_time           CONSTANT NUMBER := to_number(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_ADJUST_CODELIST_EXT_TIME',
                                                                                                                         p_code_group     => 'Monitoring'));
    c_calc_time_multiplier        CONSTANT NUMBER := to_number(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_ADJUST_CALC_TIME_MULTIP',
                                                                                                                         p_code_group     => 'Monitoring'));
    c_num_of_runs_in_calc         CONSTANT NUMBER := to_number(owner_wfm.lib_etl_global_config_param.get_parameter_value(p_code_parameter => 'MONITORING_ADJUST_NUM_RUNS_CALC',
                                                                                                                         p_code_group     => 'Monitoring'));
    c_mapping_name                VARCHAR2(30) := 'ADJUST_MONITORING';
    v_calc_time_multiplier        NUMBER;
    
  BEGIN

    v_text_check_message := 'Prepare metadata for adjustment';
    v_calc_time_multiplier := (1 / c_calc_time_multiplier) + 1;
    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE owner_wfm.etl_adjustment_monitoring';
    
    INSERT INTO owner_wfm.etl_adjustment_monitoring
       (id_process,
        name_activity,
        num_runtime_sla,
        flag_deleted)
    WITH process_instance AS (SELECT /*+ materialize*/
                                 pi.id_workflow_instance,
                                 pi.date_effective,
                                 p.name_process,
                                 p.id_process
                              FROM owner_wfm.etl_process p
                              JOIN owner_wfm.etl_process_instance pi ON pi.id_process = p.id_process
                              WHERE pi.date_effective > (p_effective_date - c_num_of_runs_in_calc)
                                    -- Exclude processes that doesnt have id of workflow instance
                                AND pi.id_workflow_instance NOT IN ('XNA', 'XAP')
                                    -- Exclude deleted processes
                                AND p.flag_deleted != 'Y'
                                AND (-- SUP processes
                                     p.name_process LIKE 'SUP%'
                                     -- Load processes under DA
                                     OR p.name_process LIKE 'DWH%'
                                     -- Load processes under IA
                                     OR p.name_process LIKE 'LD%'
                                     -- Intradaily load processes
                                     OR p.name_process LIKE 'ILD%'
                                     -- OSA Intraday load processes
                                     OR p.name_process LIKE 'OSA%'
                                     -- Out processes
                                     OR p.name_process LIKE 'OUT%'
                                     -- Load processes under DA (Datamarts)
                                     OR p.name_process LIKE 'DM%'
                                     -- Integration processes
                                     OR p.name_process LIKE 'I\_%' ESCAPE '\'
                                     -- Refresh processes
                                     OR (p.name_process LIKE 'INT_MAIN_%' ESCAPE '\')
                                     -- Transfer processes
                                     OR (p.name_process LIKE 'INT\_TRANSFER\_%' ESCAPE '\')
                                     )
                              ),
         process_instance_activity AS (SELECT
                                          pi.id_process,
                                          pi.name_process,
                                          wfacti.name_activity,
                                          NVL((CAST(wfacti.dtime_end AS DATE) - CAST(wfacti.dtime_start AS DATE)) * 24 * 60, 0) AS num_duration
                                       FROM process_instance pi
                                       JOIN owner_wfe.v_wf_activity_instance wfacti ON TO_CHAR(wfacti.id_workflow_instance_main) = pi.id_workflow_instance
                                                                                   AND wfacti.date_effective = pi.date_effective
                                       WHERE wfacti.date_effective > (p_effective_date - c_num_of_runs_in_calc)
                                         -- Only receive task activity
                                         AND wfacti.code_activity_type = 'receiveTask'
                                         -- Only complete status
                                         AND wfacti.code_status = 'COMPLETE'
                                       )
    SELECT /*+ parallel(4)*/
       id_process          AS id_process,
       name_activity       AS name_activity,
       num_new_runtime_sla AS num_runtime_sla,
       flag_deleted        AS flag_deleted
    FROM (SELECT
             id_process                                AS id_process,
             name_activity                             AS name_activity,
             nvl(num_new_runtime_sla, num_runtime_sla) AS num_new_runtime_sla,
             num_runtime_sla                           AS num_runtime_sla,
             -- Decide if runtime limit can be reduced
             CASE WHEN instance_type = 'FACT'      AND num_new_runtime_sla < num_runtime_sla AND num_runtime_sla < c_fact_ext_time      THEN 'Y'
                  WHEN instance_type = 'DIMENSION' AND num_new_runtime_sla < num_runtime_sla AND num_runtime_sla < c_dimension_ext_time THEN 'Y'
                  WHEN instance_type = 'CODELIST'  AND num_new_runtime_sla < num_runtime_sla AND num_runtime_sla < c_codelist_ext_time  THEN 'Y'
                  WHEN instance_type = 'OTHER'     AND num_new_runtime_sla < num_runtime_sla AND num_runtime_sla < c_dimension_ext_time THEN 'Y'
                  ELSE 'N'
             END AS reduce_limit_duration,
             flag_deleted
          FROM (SELECT 
                   i.id_process      AS id_process,
                   i.name_activity   AS name_activity,
                   i.instance_type   AS instance_type,
                   -- Set new runtime limit
                   CASE WHEN i.instance_type = 'FACT'         THEN LEAST(greatest(42, i.num_avg_duration), c_fact_ext_time)
                        WHEN i.instance_type = 'DIMENSION'    THEN LEAST(greatest(30, i.num_avg_duration), c_dimension_ext_time)
                        WHEN i.instance_type = 'CODELIST'     THEN LEAST(greatest(5, i.num_avg_duration), c_codelist_ext_time)
                        WHEN i.instance_type = 'NOTIFICATION' THEN 10
                        WHEN i.instance_type = 'REFRESH'      THEN 60
                        WHEN i.instance_type = 'TRANSFER'     THEN 90
                        WHEN i.instance_type = 'OTHER'        THEN LEAST(greatest(30, i.num_avg_duration), c_dimension_ext_time)
                   END               AS num_new_runtime_sla,
                   i.num_runtime_sla AS num_runtime_sla,
                   i.flag_deleted    AS flag_deleted   
                FROM (SELECT 
                         CASE WHEN n.id_process IS NOT NULL THEN n.id_process
                              ELSE cfg.id_process
                         END AS id_process,
                         CASE WHEN n.id_process IS NOT NULL THEN n.name_activity
                              ELSE cfg.name_activity
                         END AS name_activity,
                         CASE WHEN n.id_process IS NOT NULL THEN 'N'
                              ELSE 'Y'
                         END AS flag_deleted,
                         -- Set instance type
                         CASE WHEN n.name_activity     LIKE 'FT%'                         THEN 'FACT'
                              WHEN n.name_activity     LIKE 'DCT%'
                                    OR n.name_activity LIKE 'DHT%'
                                    OR n.name_activity LIKE 'DIM%'                        THEN 'DIMENSION'
                              WHEN n.name_activity     LIKE 'CLT%'                        THEN 'CODELIST'
                              WHEN n.name_activity     LIKE 'NOTIFY%'                     THEN 'NOTIFICATION'
                              WHEN n.name_process      LIKE 'INT_MAIN_%' ESCAPE '\'       THEN 'REFRESH'
                              WHEN n.name_process      LIKE 'INT\_TRANSFER\_%' ESCAPE '\' THEN 'TRANSFER'
                              ELSE 'OTHER'
                         END AS instance_type,
                         NVL(num_avg_duration, 0) AS num_avg_duration,
                         NVL(cfg.num_runtime_sla, 0) AS num_runtime_sla,
                         cfg.num_runtime_sla AS num_runtime_slaold
                      FROM (SELECT 
                               id_process,
                               name_process,
                               name_activity,
                               ROUND(AVG(CASE WHEN num_idx BETWEEN 3 AND 15 THEN num_duration
                                              ELSE NULL
                                         END)
                                     ) AS num_avg_duration
                            FROM (SELECT 
                                     id_process                                                                           AS id_process,
                                     name_process                                                                         AS name_process,
                                     name_activity                                                                        AS name_activity,
                                     ROW_NUMBER() OVER(PARTITION BY id_process, name_activity ORDER BY num_duration DESC) AS num_idx,
                                     NVL(num_duration * v_calc_time_multiplier + 1, 0)                                    AS num_duration
                                  FROM process_instance_activity
                                  )
                            GROUP BY id_process,
                                     name_process,
                                     name_activity
                            ) n
                      FULL JOIN (SELECT 
                                    id_process,
                                    name_activity,
                                    num_runtime_sla
                                 FROM owner_wfm.etl_process_monitoring
                                 WHERE flag_deleted != 'Y'
                                   AND num_start_time_offset IS NULL
                                 ) cfg ON cfg.id_process = n.id_process
                                      AND cfg.name_activity = n.name_activity
                      ) i
                  -- Exclude modules for processes that are still in old WF        
                  JOIN owner_wfm.etl_process_status ps 
                    ON ps.id_process = i.id_process
                   AND ps.id_workflow_instance not in ('XNA','XAP')
                  )
    )
    WHERE  -- New record
     num_runtime_sla = 0
     -- Extend runtime 
     OR num_new_runtime_sla > num_runtime_sla
     -- Reduce runtime
     OR reduce_limit_duration = 'Y'
     -- Module is no longer used
     OR flag_deleted = 'Y';

    COMMIT;

    dbms_stats.gather_table_stats(ownname          => 'OWNER_WFM',
                                  tabname          => 'ETL_ADJUSTMENT_MONITORING',
                                  estimate_percent => dbms_stats.AUTO_SAMPLE_SIZE,
                                  cascade          => TRUE);  

    v_text_check_message := 'Adjust metadata for monitoring';
    MERGE INTO owner_wfm.etl_process_monitoring trg
    USING (SELECT
              id_process,
              name_activity,
              num_runtime_sla,
              flag_deleted,
              USER                  AS user_inserted,
              SYSDATE               AS dtime_inserted
           FROM owner_wfm.etl_adjustment_monitoring
           ) src
    ON (trg.id_process = src.id_process
        AND trg.name_activity = src.name_activity)
    WHEN NOT MATCHED THEN 
      INSERT
        (id_process,
         name_activity,
         num_runtime_sla,
         flag_deleted,
         user_inserted,
         dtime_inserted)
      VALUES
        (src.id_process,
         src.name_activity,
         src.num_runtime_sla,
         src.flag_deleted,
         src.user_inserted,
         src.dtime_inserted)    
    WHEN MATCHED THEN 
      UPDATE SET
         trg.num_runtime_sla       = src.num_runtime_sla,
         trg.flag_deleted          = src.flag_deleted,
         trg.user_inserted         = src.user_inserted,
         trg.dtime_inserted        = src.dtime_inserted;
   
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      v_text_check_message := 'Monitoring Adjustment - error occured: '||SUBSTR(dbms_utility.format_error_stack, 1 , 1500);
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_module_name||'.'||c_mapping_name,                         
                                             p_text_message       => v_text_check_message);

  END adjust_monitoring;

END lib_etl_process_monitoring;
/
