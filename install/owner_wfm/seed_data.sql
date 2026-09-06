--UTF8-BOM: české znaky: ěščřžýáíé a ruské znaky: йцгшщзфы a čínské znaky: 你好世界
--nemazat !!!
INSERT INTO owner_wfm.etl_global_config_parameter (code_parameter, name_parameter, code_group, name_group, code_data_type, text_value, flag_deleted)
VALUES ('WF_STUCK_ACTIVITY_THRESHOLD', 'Threshold interval for stuck workflow activity in workflow queue [min]', 'WF_QUEUE', 'Workflow queue', 'NUMBER', '10', 'N');

INSERT INTO owner_wfm.etl_global_config_parameter (code_parameter, name_parameter, code_group, name_group, code_data_type, text_value, flag_deleted)
VALUES ('WF_QUEUE_ENQTIME_FORMAT', 'Date format used for enque_date from queue', 'WF_QUEUE', 'Workflow queue', 'CHAR', 'UTC', 'N');

INSERT INTO owner_wfm.etl_global_config_parameter (code_parameter, name_parameter, code_group, name_group, code_data_type, text_value, flag_deleted)
VALUES ('WF_QUEUE_ENQTIME_TIMEZONE', 'Time zone used for enque_date from queue', 'WF_QUEUE', 'Workflow queue', 'CHAR', 'ASIA/SHANGHAI', 'N');

UPDATE owner_wfm.etl_global_config_parameter SET name_parameter = 'Restart loop count for stuck workflow activity in workflow queue' WHERE code_parameter = 'WF_STUCK_ACTIVITY_LOOP';
UPDATE owner_wfm.etl_global_config_parameter SET text_value = '10', name_parameter = 'Wait interval for stuck workflow activity in workflow queue [min]' WHERE code_parameter = 'WF_STUCK_ACTIVITY_WAIT';

UPDATE owner_wfm.etl_global_config_parameter SET text_value = '20' WHERE code_parameter = 'MONITORING_SLA_INCOMING_QUEUE';
UPDATE owner_wfm.etl_global_config_parameter SET text_value = '20' WHERE code_parameter = 'MONITORING_SLA_INCOMING_QUEUE';
UPDATE owner_wfm.etl_global_config_parameter SET text_value = '20' WHERE code_parameter = 'MONITORING_SLA_RUNNING_PROCESS';

DELETE FROM owner_wfm.etl_global_config_parameter WHERE code_parameter = 'MONITORING_QUEUE_ENQTIME_FORMAT';
DELETE FROM owner_wfm.etl_global_config_parameter WHERE code_parameter = 'MONITORING_QUEUE_ENQTIME_TIMEZONE';

COMMIT;
