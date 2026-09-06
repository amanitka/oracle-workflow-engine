--UTF8-BOM: české znaky: ěščřžýáíé a ruské znaky: йцгшщзфы a čínské znaky: 你好世界
--nemazat !!!
DECLARE
   v_id_workflow_instance INTEGER;
BEGIN
  -- Call the procedure
  owner_wfe.lib_wf_engine_api.start_workflow(p_name_workflow => 'MAIN_PIPELINE_WORKFLOW',
                                             p_id_process_instance => 1,
                                             p_date_effective => TRUNC(SYSDATE),
                                             p_num_process_priority => 1,
                                             p_id_workflow_instance => v_id_workflow_instance);
end;

--suspend process
begin
  -- Call the procedure
  owner_wfe.lib_wf_engine_api.suspend_workflow(p_id_workflow_instance => 736);
end;

--resume process
begin
  -- Call the procedure
  owner_wfe.lib_wf_engine_api.resume_workflow(p_id_workflow_instance => 736);
end;

--restart process
begin
  -- Call the procedure
  owner_wfe.lib_wf_engine_api.restart_workflow(p_id_workflow_instance => 419);
end;

--cancel process
begin
  -- Call the procedure
  owner_wfe.lib_wf_engine_api.cancel_workflow(p_id_workflow_instance => 736, p_id_process_instance => 3,
                                              p_text_message => 'Test of manual cancel');
end;

-- Restart activity
begin
  -- Call the procedure
  owner_wfe.lib_wf_engine_api.restart_workflow_activity(p_id_workflow_activity_inst => 3779,
                                                        p_date_effective => DATE'2020-05-31');
end;

-- Skip activity
begin
  -- Call the procedure
  owner_wfe.lib_wf_engine_api.skip_workflow_activity(p_id_workflow_activity_inst => 3498,
                                                        p_date_effective => DATE'2020-05-28');
end;



3498

DECLARE 

   v_id_workflow_activity_inst INTEGER;
   v_id_process_instance       INTEGER;
   v_date_effective            DATE;
   v_name_module               VARCHAR2(255);
   v_text_data                 VARCHAR2(4000);
   v_code_status               VARCHAR2(30) := 'SKIP';
   v_text_message              VARCHAR2(4000) := 'Auto skip';
   --i                           INTEGER := 0;

BEGIN
  
    -- Get task for processing
    owner_wfe.lib_wf_queue_api.get_wf_activity_instance(p_id_workflow_activity_inst => v_id_workflow_activity_inst,
                                                        p_id_process_instance       => v_id_process_instance,
                                                        p_date_effective            => v_date_effective,
                                                        p_name_module               => v_name_module,
                                                        p_text_data                 => v_text_data);
                                                        
    IF v_id_workflow_activity_inst IS NOT NULL THEN
                                                        
      -- Set result after processing
      owner_wfe.lib_wf_queue_api.set_wf_activity_instance_res(p_id_workflow_activity_inst => v_id_workflow_activity_inst,
                                                              p_id_process_instance       => v_id_process_instance,
                                                              p_date_effective            => v_date_effective,
                                                              p_code_status               => v_code_status,
                                                              p_name_parameter            => NULL,
                                                              p_text_parameter_value      => NULL,
                                                              p_text_message              => v_text_message);
                                                              
    END IF;
                                                           
    COMMIT;
  
END;


DECLARE 

   v_id_workflow_activity_inst INTEGER;
   v_id_process_instance       INTEGER;
   v_date_effective            DATE;
   v_name_module               VARCHAR2(255);
   v_text_data                 VARCHAR2(4000);
   v_code_status               VARCHAR2(30) := 'ERROR';
   v_text_message              VARCHAR2(4000) := 'ORA-1234 Toto je testovaci chyba';

BEGIN
  
    -- Get task for processing
    owner_wfe.lib_wf_queue_api.get_wf_activity_instance(p_id_workflow_activity_inst => v_id_workflow_activity_inst,
                                                        p_id_process_instance       => v_id_process_instance,
                                                        p_date_effective            => v_date_effective,
                                                        p_name_module               => v_name_module,
                                                        p_text_data                 => v_text_data);
                                                        
    IF v_id_workflow_activity_inst IS NOT NULL THEN
                                                        
      -- Set result after processing
      owner_wfe.lib_wf_queue_api.set_wf_activity_instance_res(p_id_workflow_activity_inst => v_id_workflow_activity_inst,
                                                              p_id_process_instance       => v_id_process_instance,
                                                              p_date_effective            => v_date_effective,
                                                              p_code_status               => v_code_status,
                                                              p_name_parameter            => NULL,
                                                              p_text_parameter_value      => NULL,
                                                              p_text_message              => v_text_message);
                                                              
    END IF;
                                                           
    COMMIT;
  
END;



DECLARE 

   v_id_workflow_activity_inst INTEGER;
   v_id_process_instance       INTEGER;
   v_date_effective            DATE;
   v_name_module               VARCHAR2(255);
   v_text_data                 VARCHAR2(4000);
   v_code_status               VARCHAR2(30) := 'COMPLETE';
   v_text_message              VARCHAR2(4000);
   --i                           INTEGER := 0;

BEGIN
  
  FOR i IN 1 .. 30
  LOOP
  
    -- Get task for processing
    owner_wfe.lib_wf_queue_api.get_wf_activity_instance(p_id_workflow_activity_inst => v_id_workflow_activity_inst,
                                                        p_id_process_instance       => v_id_process_instance,
                                                        p_date_effective            => v_date_effective,
                                                        p_name_module               => v_name_module,
                                                        p_text_data                 => v_text_data);
                                                        
    IF v_id_workflow_activity_inst IS NOT NULL THEN
                                                        
      -- Set result after processing
      owner_wfe.lib_wf_queue_api.set_wf_activity_instance_res(p_id_workflow_activity_inst => v_id_workflow_activity_inst,
                                                              p_id_process_instance       => v_id_process_instance,
                                                              p_date_effective            => v_date_effective,
                                                              p_code_status               => v_code_status,
                                                              p_name_parameter            => NULL,
                                                              p_text_parameter_value      => NULL,
                                                              p_text_message              => NULL);
                                                              
    END IF;
                                                           
    COMMIT;
  
  END LOOP;
  
END;
/





DELETE FROM owner_wfe.wf_tmp_file;
INSERT INTO owner_wfe.wf_tmp_file
  (name_workflow_file, 
  text_workflow)
SELECT 
   name_workflow_file,
   text_workflow 
FROM owner_wfe.wf_rep_file WHERE id_workflow_definition = 3298;
COMMIT;

DECLARE

  v_code_result  VARCHAR(30);
  v_text_message CLOB;

begin
  -- Call the procedure
  owner_wfe.lib_wf_parser.parse_workflow(p_parse_process => FALSE,
                                         p_parse_diagram => TRUE,
                                         p_code_result => v_code_result,
                                         p_text_message => v_text_message);
end;

SELECT * FROM owner_wfe.wf_tmp_shape;
SELECT * FROM owner_wfe.wf_tmp_shape_attr;



WITH activity_instance AS (SELECT
                              hai.id_workflow_activity,
                              hai.id_workflow_activity_super,
                              COALESCE(hai.code_status, rai.code_status) AS code_status
                           FROM owner_wfe.wf_hist_activity_instance hai
                           LEFT JOIN owner_wfe.wf_run_activity_instance rai ON rai.id_workflow_activity_instance = hai.id_workflow_activity_instance
                                                                           AND rai.date_effective = hai.date_effective 
                           WHERE hai.id_workflow_instance = 2
                             AND hai.date_effective = DATE'2020-06-12'
                           ),
     shape_base AS (SELECT 
                       sh.name_workflow_file,
                       sh.id_workflow_activity_shape,
                       sh.code_shape_type,
                       sh.id_workflow_activity,
                       CASE WHEN ais.id_workflow_activity_super IS NOT NULL THEN 'COMPLETE'
                            ELSE ai.code_status
                       END AS code_status
                    FROM owner_wfe.wf_tmp_shape sh
                    LEFT JOIN activity_instance ai ON ai.id_workflow_activity = sh.id_workflow_activity
                    LEFT JOIN activity_instance ais ON ais.id_workflow_activity_super = sh.id_workflow_activity
                    )
SELECT
   name_workflow_file,
   id_workflow_activity_shape,
   code_shape_type
   id_workflow_activity,
   CASE WHEN code_status = 'COMPLETE' THEN 'rgb(67, 160, 71)'
        WHEN code_status = 'RUNNING'  THEN 'rgb(30, 136, 229)'
        WHEN code_status = 'ERROR'    THEN 'rgb(229, 57, 53)'
        WHEN code_status = 'RESTART'  THEN 'rgb(255, 225, 0)'
        WHEN code_status = 'SKIP'     THEN 'rgb(255, 225, 0)'
        WHEN code_status = 'CANCEL'   THEN 'rgb(251, 140, 0)'
        WHEN code_status = 'STUCK'    THEN 'rgb(142, 36, 170)'
        ELSE NULL
   END AS text_stroke_color,
   CASE WHEN code_status = 'COMPLETE' THEN 'rgb(200, 230, 201)'
        WHEN code_status = 'RUNNING'  THEN 'rgb(187, 222, 251)'
        WHEN code_status = 'ERROR'    THEN 'rgb(255, 205, 210)'
        WHEN code_status = 'RESTART'  THEN 'rgb(255, 255, 201)'
        WHEN code_status = 'SKIP'     THEN 'rgb(255, 255, 201)'
        WHEN code_status = 'CANCEL'   THEN 'rgb(255, 224, 178)'
        WHEN code_status = 'STUCK'    THEN 'rgb(225, 190, 231)'
        ELSE NULL
   END AS text_full_color
FROM shape_base
