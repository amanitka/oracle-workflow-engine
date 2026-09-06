--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_etl_process_instance_act
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_process_instance_act AS
SELECT 
   date_effective,
   id_process_instance,
   id_workflow_activity,
   name_module, 
   name_activity, 
   text_message, 
   dtime_inserted, 
   user_inserted
FROM owner_wfm.etl_process_instance_activity;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_etl_process_instance_activity
-----------------------------------------------------------------
-- Add comments to the table 
COMMENT ON TABLE owner_wfm.v_etl_process_instance_act IS 'Process instance activity log for console';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfm.v_etl_process_instance_act.date_effective IS 'Effective date of the process';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance_act.id_process_instance IS 'Process instance id';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance_act.id_workflow_activity IS 'Workflow activity id';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance_act.name_module IS 'Module name';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance_act.name_activity IS 'Name of activity';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance_act.text_message IS 'Message of activity';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance_act.dtime_inserted IS 'Date and time when the record was inserted';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance_act.user_inserted IS 'User who inserted the record';
