--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_etl_background_process
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_background_process AS
SELECT 
   bp.code_process_category             AS code_process_category,
   bp.code_process_group                AS code_process_group,
   bp.name_process_owner                AS name_process_owner,  
   bp.name_process                      AS name_process,
   bpg.text_description                 AS text_description,
   bp.text_parameter_value              AS text_parameter_value,
   bp.flag_active                       AS flag_active,
   CASE WHEN schj.state = 'RUNNING' THEN 'Y'
        ELSE 'N'
   END                                  AS flag_running,
   schj.owner                           AS name_job_owner,
   schj.job_name                        AS name_job,
   schj.job_type                        AS code_job_type,
   schj.job_class                       AS name_job_class,
   schj.state                           AS code_status,
   schj.run_count                       AS cnt_run,
   schj.failure_count                   AS cnt_failure,
   CAST(schj.start_date AS DATE)        AS dtime_start_first,
   CAST(schj.last_start_date AS DATE)   AS dtime_start_last,   
   CAST(schj.next_run_date AS DATE)     AS dtime_start_next,   
   schj.repeat_interval                 AS text_repeat_interval, 
   schj.comments                        AS text_comment,
   schj.job_action                      AS text_action,
   NVL(pp.flag_create_bg_process, 'N')  AS flag_create_bg_process_priv,
   NVL(pp.flag_drop_bg_process, 'N')    AS flag_drop_bg_process_priv
FROM owner_wfm.etl_background_process bp
JOIN owner_wfm.etl_background_process_group bpg ON bpg.code_process_group = bp.code_process_group
LEFT JOIN dba_scheduler_jobs schj ON schj.owner = bp.name_process_owner
                                 AND schj.job_name = 'JOB_'||bp.name_process 
LEFT JOIN owner_wfm.tmp_personal_privilege pp ON pp.code_responsible_group = bp.code_responsible_group
WHERE bp.flag_deleted != 'Y'
  AND bpg.flag_deleted != 'Y'
ORDER BY bp.code_process_category,
         bp.code_process_group,
         bp.name_process
WITH READ ONLY;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_etl_background_process
-----------------------------------------------------------------
-- Add comments to the table 
COMMENT ON TABLE owner_wfm.v_etl_background_process IS 'Background process definition for console';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfm.v_etl_background_process.code_process_category IS 'Code of the background process category';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.code_process_group IS 'Code of the background process group';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.name_process_owner IS 'Owner of the background process';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.name_process IS 'Name of the background process';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.text_description IS 'Background process description';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.text_parameter_value IS 'Parameter value';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.flag_active IS 'Flag marking background process as active (scheduled)';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.flag_running IS 'Flag marking background process as running';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.name_job_owner IS 'Name of the job owner';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.name_job IS 'Name of the job';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.code_job_type IS 'Code of the job type';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.name_job_class IS 'Name of the job class';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.cnt_run IS 'Count of the job executions';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.cnt_failure IS 'Count of the job failures';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.dtime_start_first IS 'Date and time of the first job start';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.dtime_start_last IS 'Date and time of the last job start';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.dtime_start_next IS 'Date and time of the next job start';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.text_repeat_interval IS 'Repeat interval of the job';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.text_comment IS 'Text comment of the job';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.text_action IS 'Text action of the job';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.flag_create_bg_process_priv IS 'Flag saying whether user has right to create the background process';
COMMENT ON COLUMN owner_wfm.v_etl_background_process.flag_drop_bg_process_priv IS 'Flag saying whether user has right to drop the background process';
/
