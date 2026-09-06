CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_workflow_extension_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_WORKFLOW_LIST
  -- purpose:       Get workflow list for given main workflow process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_workflow_list(p_name_workflow IN VARCHAR2) RETURN owner_wfe.lib_wf_diagram_api.tt_workflow_list;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_WORKFLOW
  -- purpose:        Get workflow definition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_workflow(p_id_workflow_definition IN INTEGER DEFAULT NULL,
                         p_name_workflow          IN VARCHAR2 DEFAULT NULL,
                         p_text_workflow          OUT CLOB);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_EXEC_WORKFLOW
  -- purpose:        Get executed workflow definition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_exec_workflow(p_id_workflow_instance IN INTEGER DEFAULT NULL,
                              p_id_workflow_activity IN INTEGER DEFAULT NULL,                       
                              p_date_effective       IN DATE,
                              p_text_workflow        OUT CLOB);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DELETE_WORKFLOW
  -- purpose:        Delete all workflow definitions for given id workflow    
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE delete_workflow(p_id_workflow IN VARCHAR2);
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DELETE_WORKFLOW_DEFINITION
  -- purpose:        Delete workflow definition 
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE delete_workflow_definition(p_id_workflow_definition IN INTEGER,
                                       p_id_workflow            IN VARCHAR2);
                                       
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DELETE_DEPLOYMENT
  -- purpose:        Delete whole deployment 
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE delete_deployment(p_id_deployment IN INTEGER);
                           
END lib_etl_workflow_extension_api;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_workflow_extension_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_WORKFLOW_LIST
  -- purpose:       Get workflow list for given main workflow process
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION get_workflow_list(p_name_workflow IN VARCHAR2) RETURN owner_wfe.lib_wf_diagram_api.tt_workflow_list IS
  
  BEGIN

    -- Return workflow list for given main workflow process
    RETURN owner_wfe.lib_wf_diagram_api.get_workflow_list(p_name_workflow  => p_name_workflow);

  END get_workflow_list;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_WORKFLOW
  -- purpose:        Get workflow definition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_workflow(p_id_workflow_definition IN INTEGER DEFAULT NULL,
                         p_name_workflow          IN VARCHAR2 DEFAULT NULL,
                         p_text_workflow          OUT CLOB) IS
        
  BEGIN

    -- Get workflow definition
    owner_wfe.lib_wf_diagram_api.get_workflow(p_id_workflow_definition => p_id_workflow_definition,
                                              p_name_workflow          => p_name_workflow,
                                              p_text_workflow          => p_text_workflow);
  
  END get_workflow;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_EXEC_WORKFLOW
  -- purpose:        Get executed workflow definition
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE get_exec_workflow(p_id_workflow_instance IN INTEGER DEFAULT NULL,
                              p_id_workflow_activity IN INTEGER DEFAULT NULL,                       
                              p_date_effective       IN DATE,
                              p_text_workflow        OUT CLOB) IS
    
  BEGIN
    
    -- Get executed workflow definition
    owner_wfe.lib_wf_diagram_api.get_exec_workflow(p_id_workflow_instance      => p_id_workflow_instance,
                                                   p_id_workflow_activity_inst => p_id_workflow_activity,
                                                   p_date_effective            => p_date_effective,
                                                   p_text_workflow             => p_text_workflow);
  
  END get_exec_workflow;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DELETE_WORKFLOW
  -- purpose:        Delete all workflow definitions for given id workflow    
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE delete_workflow(p_id_workflow IN VARCHAR2)
  IS
  
  BEGIN
     
    -- Delete all definitions of workflow
    owner_wfe.lib_wf_deployer_api.delete_workflow(p_id_workflow => p_id_workflow);

      
  END delete_workflow;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DELETE_WORKFLOW_DEFINITION
  -- purpose:        Delete workflow definition 
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE delete_workflow_definition(p_id_workflow_definition IN INTEGER,
                                       p_id_workflow            IN VARCHAR2)
  IS
  
  BEGIN

    -- Delete workflow definition 
    owner_wfe.lib_wf_deployer_api.delete_workflow_definition(p_id_workflow_definition => p_id_workflow_definition,
                                                             p_id_workflow            => p_id_workflow);
      
  END delete_workflow_definition;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: DELETE_DEPLOYMENT
  -- purpose:        Delete whole deployment 
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE delete_deployment(p_id_deployment IN INTEGER)
  IS
  
  BEGIN
     
    -- Delete whole deployment 
    owner_wfe.lib_wf_deployer_api.delete_deployment(p_id_deployment => p_id_deployment);    
      
  END delete_deployment;
                                                  
END lib_etl_workflow_extension_api;
/
