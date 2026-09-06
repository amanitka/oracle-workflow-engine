--UTF8-BOM: české znaky: ěščřžýáíé a ruské znaky: йцгшщзфы a čínské znaky: 你好世界
--nemazat !!!
GRANT EXECUTE ON owner_wfe.lib_wf_engine_api TO owner_wfm;
GRANT EXECUTE ON owner_wfe.lib_wf_queue_api TO owner_wfm;
GRANT EXECUTE ON owner_wfe.lib_wf_diagram_api TO owner_wfm;
GRANT EXECUTE ON owner_wfe.lib_wf_deployer_api TO owner_wfm;
GRANT EXECUTE ON owner_wfe.lib_wf_constant TO owner_wfm;
GRANT SELECT ON owner_wfe.v_wf_activity_instance TO owner_wfm;
GRANT SELECT ON owner_wfe.v_wf_run_activity_instance TO owner_wfm;
GRANT SELECT ON owner_wfe.v_wf_aq_activity_inst_in TO owner_wfm;
GRANT SELECT ON owner_wfe.v_wf_aq_activity_inst_out TO owner_wfm;
GRANT SELECT, INSERT ON owner_wfe.wf_tmp_file2deployment TO owner_wfm;
