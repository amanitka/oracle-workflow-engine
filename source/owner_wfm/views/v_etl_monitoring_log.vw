--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_etl_monitoring_log
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_monitoring_log AS
    SELECT 
        id,
        code_entity,
        id_entity,
        id_entity_instance,
        id_entity_activity,
        name_process, 
        date_effective, 
        code_error_type,
        text_error_message,
        text_message,
        code_responsible_group, 
        code_status, 
        num_severity, 
        flag_confirmed, 
        flag_sent,
        dtime_inserted,
        NVL(flag_confirm_err_log, 'N') AS flag_confirm_err_log_priv,
        case
          when code_status = 'COMPLETE' then 'Confirmed at '||to_char(dtime_updated,'HH24:MI:SS DD.MM.YYYY')
          when code_status <> 'COMPLETE' then 'Pending '||
          decode(num_pending_day,0,null,1,'1day ',num_pending_day||'days ')||num_pending_hour||'h '||num_pending_min||'min '||num_pending_s||'s'
        end as text_description,
        id_workflow_instance,
        dtime_process_instance_start,
        dtime_process_instance_end
FROM (
    SELECT 
        t.id,
        t.code_entity,
        t.id_entity,
        t.id_entity_instance,
        t.id_entity_activity, 
        i.name_process,
        t.date_effective, 
        initcap(t.code_error_type) as code_error_type,
        t.text_error_message, 
        t.text_message, 
        t.code_status,
        t.code_responsible_group, 
        t.num_severity, 
        t.flag_confirmed, 
        t.flag_sent,
        t.dtime_inserted,
        trunc(sysdate - add_months( t.dtime_inserted, months_between(sysdate,t.dtime_inserted))) as num_pending_day,
        trunc(24*mod(sysdate - t.dtime_inserted,1)) as num_pending_hour,
        trunc( mod(mod(sysdate - t.dtime_inserted,1)*24,1)*60 ) as num_pending_min,
        round(mod(mod(mod(sysdate - t.dtime_inserted,1)*24,1)*60,1)*60) as num_pending_s,
        t.dtime_updated,
        pp.flag_confirm_err_log,
        i.id_workflow_instance,
        i.dtime_start as dtime_process_instance_start,
        NVL(i.dtime_end,i.dtime_start+1) as dtime_process_instance_end
    FROM owner_wfm.etl_monitoring_log t
    LEFT JOIN owner_wfm.tmp_personal_privilege pp ON pp.code_responsible_group = t.code_responsible_group
    LEFT JOIN owner_wfm.v_etl_process_instance i ON i.id_process_instance = TO_NUMBER(t.id_entity_instance)
                                                AND i.date_effective = t.date_effective
                                                AND t.id_entity_instance != 'XAP'
    ORDER BY t.code_status desc, t.dtime_inserted desc
);
-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_etl_monitoring_log
-----------------------------------------------------------------
-- Add comments to the table 
COMMENT ON TABLE owner_wfm.v_etl_monitoring_log IS 'Process log for console';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.id IS 'Log id, is a primary key';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.id_entity_instance IS 'Entity instance id - in case of code_entity = PROCESS, describes ID_PROCESS_INSTANCE';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.id_entity_activity IS 'Entity activity id - in case of code_entity = PROCESS, describes ID_WORKFLOW_ACTIVITY';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.id_entity IS 'Entity id - in case of code_entity = PROCESS, describes ID_PROCESS';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.name_process IS 'Process name';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.code_entity IS 'Code of entity - PROCESS/REPLICAT/REPORT ROBOT';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.date_effective IS 'Date effective';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.code_error_type IS 'Code of type error - source of error - Duration, AQ, StartWindow, etc.';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.text_error_message IS 'Error message extension';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.text_message IS 'Error message';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.code_status IS 'Code status';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.num_severity IS 'Number of severity';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.flag_confirmed IS 'Flag marking record as deleted';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.flag_sent IS 'Flag whether was sent email or informed emergency';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.dtime_inserted IS 'Date logged';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.text_description IS 'Description';
COMMENT ON COLUMN owner_wfm.v_etl_monitoring_log.flag_confirm_err_log_priv IS 'Flag saying whether user has right to manualy confirm monitoring log';
/
