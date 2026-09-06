--UTF8-BOM: české znaky: ěščřžýáíé a ruské znaky: йцгшщзфы a čínské znaky: 你好世界
--nemazat !!!

-- Stop camunda app

-- Drop users
-- It might me necessary to lock those accounts and kill all connected sessions
DROP USER owner_cam CASCADE;
DROP USER app_cam CASCADE;

-- Drop tablespaces
DROP TABLESPACE camunda_data;
DROP TABLESPACE camunda_index;

-- Drop oracle AQ
BEGIN
  dbms_aqadm.stop_queue(queue_name => 'OWNER_WFM.ETL_WF_ACTIVITY');
  dbms_aqadm.drop_queue(queue_name => 'OWNER_WFM.ETL_WF_ACTIVITY');
  dbms_aqadm.drop_queue_table(queue_table => 'OWNER_WFM.ETL_WF_ACTIVITY');
END;
/

BEGIN
  dbms_aqadm.stop_queue(queue_name => 'OWNER_WFM.ETL_WF_ACTIVITY_RESULT');
  dbms_aqadm.drop_queue(queue_name => 'OWNER_WFM.ETL_WF_ACTIVITY_RESULT');
  dbms_aqadm.drop_queue_table(queue_table => 'OWNER_WFM.ETL_WF_ACTIVITY_RESULT');
END;
/

-- Drop type used fro the AQ payload
DROP TYPE owner_wfm.t_wf_activity;
DROP TYPE owner_wfm.t_wf_activity_result;

-- Drop tables
DROP TABLE owner_wfm.etl_wf_parsed_definition;
DROP TABLE owner_wfm.etl_wf_parsed_proc_element;
DROP TABLE owner_wfm.etl_wf_parsed_proc_elem_attr;
DROP TABLE owner_wfm.etl_wf_to_analyze;

-- Drop package
DROP PACKAGE owner_wfm.lib_etl_wf_analyzer;
