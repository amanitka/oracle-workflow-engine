--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_etl_wf_file2deployment
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_wf_file2deployment AS      
SELECT
   id_deployment,
   name_workflow_file,
   text_workflow,
   dtime_inserted,
   user_inserted
FROM owner_wfe.wf_tmp_file2deployment;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_etl_wf_file2deployment
-----------------------------------------------------------------
-- Add comments to the table 
COMMENT ON TABLE owner_wfm.v_etl_wf_file2deployment IS 'Temporary repository for workflow files during the deployment';
  
-- Add comments to the columns
COMMENT ON COLUMN owner_wfm.v_etl_wf_file2deployment.id_deployment IS 'Id of the deployment';
COMMENT ON COLUMN owner_wfm.v_etl_wf_file2deployment.name_workflow_file IS 'Name of the workflow file';
COMMENT ON COLUMN owner_wfm.v_etl_wf_file2deployment.text_workflow IS 'Text of workflow definition';
COMMENT ON COLUMN owner_wfm.v_etl_wf_file2deployment.dtime_inserted IS 'Date and time when the record was inserted';
COMMENT ON COLUMN owner_wfm.v_etl_wf_file2deployment.user_inserted IS 'User who inserted the record';
/
