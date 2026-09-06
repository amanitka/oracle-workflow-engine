CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_wf_deployer_api IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 20.01.2020
  -- purpose: Deploy workflow definition
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------   

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_ID_DEPLOYMENT
  -- purpose:        Get id deployment from sequence
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_id_deployment RETURN INTEGER;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PURGE_WORKFLOW_FILE
  -- purpose:        Purge workflow files before validation and deployment
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE purge_workflow_file(p_code_result  OUT VARCHAR2,
                                p_text_message OUT CLOB);
                                
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: convert_workflow_file2xmltype
  -- purpose:        Convert workflow file to xmltype for validation and deployment
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE convert_workflow_file2xmltype(p_id_deployment IN INTEGER,
                                          p_code_result   OUT VARCHAR2,
                                          p_text_message  OUT CLOB);
                                 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: VALIDATE_WORKFLOW
  -- purpose:        Validate workflow files before deployment (check if everything is in place)       
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE validate_workflow(p_code_result  OUT VARCHAR2,
                              p_text_message OUT CLOB);
                           
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEPLOY_WORKFLOW
  -- purpose:        Deploy validated workflow definition     
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE deploy_workflow(p_id_deployment   IN INTEGER,
                            p_name_deployment IN VARCHAR2,
                            p_code_result     OUT VARCHAR2,
                            p_text_message    OUT CLOB);

END lib_etl_wf_deployer_api;        
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_wf_deployer_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_ID_DEPLOYMENT
  -- purpose:        Get id deployment from sequence
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_id_deployment RETURN INTEGER 
  IS
    
  BEGIN

    -- Get id deployment from sequence
    RETURN owner_wfe.lib_wf_deployer_api.get_id_deployment;

  END get_id_deployment;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: PURGE_WORKFLOW_FILE
  -- purpose:        Purge workflow files before validation and deployment
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE purge_workflow_file(p_code_result  OUT VARCHAR2,
                                p_text_message OUT CLOB)
  IS
  
  BEGIN

    -- Purge workflow files before validation and deployment
    owner_wfe.lib_wf_deployer_api.purge_workflow_file(p_code_result  => p_code_result,
                                                      p_text_message => p_text_message);

  END purge_workflow_file;
                              
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: convert_workflow_file2xmltype
  -- purpose:        Convert workflow file to xmltype for validation and deployment
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE convert_workflow_file2xmltype(p_id_deployment IN INTEGER,
                                          p_code_result   OUT VARCHAR2,
                                          p_text_message  OUT CLOB)
  IS
  
  BEGIN

    -- Convert workflow file to xmltype for validation and deployment
    owner_wfe.lib_wf_deployer_api.convert_workflow_file2xmltype(p_id_deployment => p_id_deployment,
                                                                p_code_result   => p_code_result,
                                                                p_text_message  => p_text_message);

  END convert_workflow_file2xmltype;
                            
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: VALIDATE_WORKFLOW
  -- purpose:        Validate workflow files before deployment (check if everything is in place)       
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE validate_workflow(p_code_result  OUT VARCHAR2,
                              p_text_message OUT CLOB)
  IS
  
  BEGIN

    -- Purge workflow files before validation and deployment
    owner_wfe.lib_wf_deployer_api.validate_workflow(p_code_result  => p_code_result,
                                                    p_text_message => p_text_message);

  END validate_workflow;
                           
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DEPLOY_WORKFLOW
  -- purpose:        Deploy validated workflow definition     
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE deploy_workflow(p_id_deployment   IN INTEGER,
                            p_name_deployment IN VARCHAR2,
                            p_code_result     OUT VARCHAR2,
                            p_text_message    OUT CLOB) 
  IS
  
  BEGIN

    -- Convert workflow file to xmltype for validation and deployment
    owner_wfe.lib_wf_deployer_api.deploy_workflow(p_id_deployment   => p_id_deployment,
                                                  p_name_deployment => p_name_deployment,
                                                  p_code_result     => p_code_result,
                                                  p_text_message    => p_text_message);

  END deploy_workflow;

END lib_etl_wf_deployer_api;
/
