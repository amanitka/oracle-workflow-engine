--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_etl_process_condition
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_process_condition AS
SELECT
   p.id_process,
   p.name_process,
   pc.num_order,
   pc.code_type,
   pc.text_condition,
   p2.name_process AS name_process_condition,
   pc.code_check_type,
   pc.flag_manual_start_check,
   pc.flag_deleted,
   pc.dtime_inserted,
   pc.user_inserted,
   pc.dtime_updated,
   pc.user_updated
FROM owner_wfm.etl_process p
JOIN owner_wfm.etl_process_condition pc ON pc.id_process = p.id_process
LEFT JOIN owner_wfm.etl_process p2 ON TO_CHAR(p2.id_process) = pc.text_condition
                                  AND pc.code_type = 'PROCESS'
WITH READ ONLY;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_etl_process_condition
-----------------------------------------------------------------
-- Add comments to the table 
COMMENT ON TABLE owner_wfm.v_etl_process_condition IS 'Start conditions for processes';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.id_process IS 'Process id';
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.name_process IS 'Process name';
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.num_order IS 'Order of start condition';
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.code_type is 'Start condition type - PROCESS or CONDITION';
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.text_condition IS 'Start condition - PROCESS = id_process, CONDITION = condition call';
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.name_process_condition IS 'Name of referenced process by condition';
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.code_check_type IS 'Start condition check type - COMPLETE_CURRENT, COMPLETE_PREVIOUS, COND_TRUE, COND_FALSE, NORUN_ANY, NORUN_CURRENT, NOSTART_CURRENT';
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.flag_manual_start_check IS 'Flag if condition should be checked during manual start';
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.flag_deleted IS 'Flag marking record as deleted';
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.dtime_inserted IS 'Date and time when the record was inserted';
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.user_inserted IS 'User who inserted the record';
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.dtime_updated IS 'Date and time when the record was updated';
COMMENT ON COLUMN owner_wfm.v_etl_process_condition.user_updated IS 'User who updated the record';