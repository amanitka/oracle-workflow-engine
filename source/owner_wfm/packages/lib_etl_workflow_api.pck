CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_workflow_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  TYPE t_workflow_activity_log IS RECORD (id_workflow_activity      VARCHAR2 (100),
                                          name_activity_type        VARCHAR2 (50),
                                          name_activity             VARCHAR2 (100),
                                          dtime_start               DATE,
                                          dtime_end                 DATE,
                                          code_status               VARCHAR2 (20),
                                          duration                  VARCHAR2 (20),
                                          text_message              VARCHAR2 (4000)); 
                                                                
  TYPE tt_workflow_activity_log IS TABLE OF t_workflow_activity_log;

  ---------------------------------------------------------------------------------------------------------
  -- function name: CHECK_EXISTING_WORKFLOW
  -- purpose:       Find out if workflow exists in repository
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION check_existing_workflow(p_name_workflow IN VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_ERROR_ACTIVITY
  -- purpose:        Find out if there are failed workflow activities for given workflow process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION check_error_activity(p_id_workflow_instance IN VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_UNPROC_ACTIVITY
  -- purpose:        Find out if there are unprocessed workflow activities in inbound and outbound queue for given workflow process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION check_unproc_activity(p_id_workflow_instance IN VARCHAR2) RETURN BOOLEAN;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_PROCESS
  -- purpose:        Start process in workflow engine
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_process(p_name_workflow        IN  VARCHAR2,
                          p_id_process_instance  IN  INTEGER,
                          p_date_effective       IN  DATE,
                          p_num_process_priority IN  INTEGER,
                          p_id_workflow_instance OUT VARCHAR);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_PROCESS
  -- purpose:        Restart process in workflow engine
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_process(p_id_workflow_instance IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CANCEL_PROCESS
  -- purpose:        Cancel process in workflow engine
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE cancel_process(p_id_workflow_instance IN VARCHAR2,
                           p_text_message         IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SUSPEND_PROCESS
  -- purpose:        Suspend process in workflow engine
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE suspend_process(p_id_workflow_instance IN VARCHAR2);
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SUSPEND_PROCESS
  -- purpose:        Suspend process in camunda workflow engine
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE resume_process(p_id_workflow_instance IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_ACTIVITY
  -- purpose:        Restart activity in workflow engine
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE restart_activity(p_id_workflow_activity IN VARCHAR2,
                             p_date_effective       IN DATE);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SKIP_ACTIVITY
  -- purpose:        Skip activity in workflow engine
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE skip_activity(p_id_workflow_activity IN VARCHAR2,
                          p_date_effective       IN DATE);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_BEFORE_ACTIVITY
  -- purpose:        Cancel activity and start before some element in worfkflow engine (use only in emergency situation (stuck workflow), it can cause to unforeseen circumstances)
  -- parameters:     
  --   P_ID_WORKFLOW_ACTIVITY      - Id of workflow activity which needs to be canceled
  --   P_ID_WORKFLOW_ELEMENT_START - Id of workflow element (from workflow definition) before which should workflow start/continue
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_before_activity(p_id_workflow_activity      IN VARCHAR2,
                                  p_date_effective            IN DATE,
                                  p_id_workflow_element_start IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_AFTER_ACTIVITY
  -- purpose:        Cancel activity and start after some element in worfkflow engine (use only in emergency situation (stuck workflow), it can cause to unforeseen circumstances)
  -- parameters:     
  --   P_ID_WORKFLOW_ACTIVITY      - Id of workflow activity which needs to be canceled
  --   P_ID_WORKFLOW_ELEMENT_START - Id of workflow element (from workflow definition) after which should workflow start/continue
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_after_activity(p_id_workflow_activity      IN VARCHAR2,
                                 p_date_effective            IN DATE,
                                 p_id_workflow_element_start IN VARCHAR2);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_WORKFLOW_ACTIVITY_LOG
  -- purpose:        Get workflow_activity log
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_workflow_activity_log(p_id_workflow_instance    IN VARCHAR2,
                                      p_date_effective          IN DATE,
                                      p_display_additional_info IN VARCHAR2 DEFAULT NULL,
                                      p_workflow_activity_log   OUT tt_workflow_activity_log);
                           
END lib_etl_workflow_api;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_workflow_api IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_flag_n                CONSTANT VARCHAR2(1)  := 'N';
  c_flag_y                CONSTANT VARCHAR2(1)  := 'Y';

  ---------------------------------------------------------------------------------------------------------
  -- function name: CHECK_EXISTING_WORKFLOW
  -- purpose:       Find out if workflow exists in repository
  ---------------------------------------------------------------------------------------------------------  
  FUNCTION check_existing_workflow(p_name_workflow IN VARCHAR2) RETURN BOOLEAN
  IS
  
  BEGIN
  
    RETURN owner_wfe.lib_wf_engine_api.check_existing_workflow(p_name_workflow => p_name_workflow);
    
  END check_existing_workflow;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_ERROR_ACTIVITY
  -- purpose:        Find out if there are failed workflow activities for given workflow process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION check_error_activity(p_id_workflow_instance IN VARCHAR2) RETURN BOOLEAN
  IS

  BEGIN
 
    -- Find out if there are failed workflow activities for given workflow process              
    RETURN owner_wfe.lib_wf_engine_api.check_error_workflow_activity(p_id_workflow_instance_main => TO_NUMBER(p_id_workflow_instance));

  END check_error_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CHECK_UNPROC_ACTIVITY
  -- purpose:        Find out if there are unprocessed workflow activities in inbound and outbound queue for given workflow process
  ---------------------------------------------------------------------------------------------------------
  FUNCTION check_unproc_activity(p_id_workflow_instance IN VARCHAR2) RETURN BOOLEAN
  IS

  BEGIN
 
    -- Find out if there are failed workflow activities for given workflow process              
    RETURN owner_wfe.lib_wf_engine_api.check_unproc_workflow_activity(p_id_workflow_instance_main => TO_NUMBER(p_id_workflow_instance));

  END check_unproc_activity;
     
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_PROCESS
  -- purpose:        Start process in workflow engine
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_process(p_name_workflow        IN  VARCHAR2,
                          p_id_process_instance  IN  INTEGER,
                          p_date_effective       IN  DATE,
                          p_num_process_priority IN  INTEGER,
                          p_id_workflow_instance OUT VARCHAR)
  IS  
        
  BEGIN
    
    -- Create process in workflow engine
    owner_wfe.lib_wf_engine_api.start_workflow(p_name_workflow        => p_name_workflow,
                                               p_id_process_instance  => p_id_process_instance,
                                               p_date_effective       => p_date_effective,
                                               p_num_process_priority => p_num_process_priority,            
                                               p_id_workflow_instance => p_id_workflow_instance);
          
  END start_process;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_PROCESS
  -- purpose:        Restart process in workflow engine
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE restart_process(p_id_workflow_instance IN VARCHAR2)
  IS  
    
  BEGIN  
    
    -- Restart process in workflow engine                                                  
    owner_wfe.lib_wf_engine_api.restart_workflow(p_id_workflow_instance_main => TO_NUMBER(p_id_workflow_instance));

  END restart_process;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CANCEL_PROCESS
  -- purpose:        Cancel process in workflow engine
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE cancel_process(p_id_workflow_instance IN VARCHAR2,
                           p_text_message         IN VARCHAR2)
  IS  
       
  BEGIN  
             
    -- Cancel process in workflow engine                                                        
    owner_wfe.lib_wf_engine_api.cancel_workflow(p_id_workflow_instance_main => TO_NUMBER(p_id_workflow_instance),
                                                p_text_message              => p_text_message);

  END cancel_process;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SUSPEND_PROCESS
  -- purpose:        Suspend process in workflow engine
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE suspend_process(p_id_workflow_instance IN VARCHAR2)
  IS  
    
  BEGIN  
    
    -- Suspend process in workflow engine                                                  
    owner_wfe.lib_wf_engine_api.suspend_workflow(p_id_workflow_instance_main => TO_NUMBER(p_id_workflow_instance));

  END suspend_process;
 
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESUME_PROCESS
  -- purpose:        Resume process in workflow engine
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE resume_process(p_id_workflow_instance IN VARCHAR2)
  IS  
    
  BEGIN  
 
    -- Resume process in workflow engine                                                  
    owner_wfe.lib_wf_engine_api.resume_workflow(p_id_workflow_instance_main => TO_NUMBER(p_id_workflow_instance));   

  END resume_process;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: RESTART_ACTIVITY
  -- purpose:        Restart activity in workflow engine
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE restart_activity(p_id_workflow_activity IN VARCHAR2,
                             p_date_effective       IN DATE)
  IS  

  BEGIN  
 
    -- Skip activity in workflow engine
    owner_wfe.lib_wf_engine_api.restart_workflow_activity(p_id_workflow_activity_inst => TO_NUMBER(p_id_workflow_activity),
                                                          p_date_effective            => p_date_effective);   

  END restart_activity;
   
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SKIP_ACTIVITY
  -- purpose:        Skip activity in workflow engine
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE skip_activity(p_id_workflow_activity IN VARCHAR2,
                          p_date_effective       IN DATE)
  IS  

  BEGIN  
    
    -- Skip activity in workflow engine
    owner_wfe.lib_wf_engine_api.skip_workflow_activity(p_id_workflow_activity_inst => TO_NUMBER(p_id_workflow_activity),
                                                       p_date_effective            => p_date_effective);
 
  END skip_activity;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_BEFORE_ACTIVITY
  -- purpose:        Cancel activity and start before some element in worfkflow engine (use only in emergency situation (stuck workflow), it can cause to unforeseen circumstances)
  -- parameters:     
  --   P_ID_WORKFLOW_ACTIVITY      - Id of workflow activity which needs to be canceled
  --   P_ID_WORKFLOW_ELEMENT_START - Id of workflow element (from workflow definition) before which should workflow start/continue
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_before_activity(p_id_workflow_activity      IN VARCHAR2,
                                  p_date_effective            IN DATE,
                                  p_id_workflow_element_start IN VARCHAR2)
  IS  

  BEGIN  
    
    -- Cancel activity and start before some element in worfkflow engine
    owner_wfe.lib_wf_engine_api.start_before_workflow_activity(p_id_workflow_activity_inst  => TO_NUMBER(p_id_workflow_activity),
                                                               p_date_effective             => p_date_effective,
                                                               p_id_workflow_activity_start => p_id_workflow_element_start);

  END start_before_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: START_AFTER_ACTIVITY
  -- purpose:        Cancel activity and start after some element in worfkflow engine (use only in emergency situation (stuck workflow), it can cause to unforeseen circumstances)
  -- parameters:     
  --   P_ID_WORKFLOW_ACTIVITY      - Id of workflow activity which needs to be canceled (stuck subprocess)
  --   P_ID_WORKFLOW_ELEMENT_START - Id of workflow element (from workflow definition) after which should workflow start/continue
  ---------------------------------------------------------------------------------------------------------  
  PROCEDURE start_after_activity(p_id_workflow_activity      IN VARCHAR2,
                                 p_date_effective            IN DATE,
                                 p_id_workflow_element_start IN VARCHAR2)
  IS  

  BEGIN  
    
    -- Cancel activity and start after some element in worfkflow engine
    owner_wfe.lib_wf_engine_api.start_after_workflow_activity(p_id_workflow_activity_inst  => TO_NUMBER(p_id_workflow_activity),
                                                              p_date_effective             => p_date_effective,
                                                              p_id_workflow_activity_start => p_id_workflow_element_start);

  END start_after_activity;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_WORKFLOW_ACTIVITY_LOG
  -- purpose:        Get workflow_activity log
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_workflow_activity_log(p_id_workflow_instance    IN VARCHAR2,
                                      p_date_effective          IN DATE,
                                      p_display_additional_info IN VARCHAR2 DEFAULT NULL,
                                      p_workflow_activity_log   OUT tt_workflow_activity_log)
  IS
     
    CURSOR c_workflow_activity_log IS    
      WITH activity_base AS (SELECT
                                TO_CHAR(id_workflow_activity_instance) AS id_workflow_activity, 
                                UPPER(code_activity_type)              AS name_activity_type, 
                                name_activity                          AS name_activity, 
                                CAST(dtime_start AS DATE)              AS dtime_start, 
                                CAST(dtime_end AS DATE)                AS dtime_end,
                                code_status                            AS code_status, 
                                duration                               AS duration, 
                                text_message                           AS text_message, 
                                dtime_start                            AS dtime_inserted,
                                CASE WHEN (p_display_additional_info IS NULL OR p_display_additional_info = c_flag_N)
                                           AND code_activity_type IN ('parallelGateway', 'inclusiveGateway', 'startEvent', 'endEvent') THEN c_flag_n
                                     ELSE c_flag_y
                                END                           AS flag_display_record
                             FROM owner_wfe.v_wf_activity_instance 
                             WHERE id_workflow_instance_main = TO_NUMBER(p_id_workflow_instance)    
                               AND date_effective = CASE WHEN p_date_effective IS NOT NULL THEN p_date_effective 
                                                         ELSE date_effective
                                                    END                             
                             )
      SELECT
         id_workflow_activity, 
         name_activity_type, 
         name_activity, 
         dtime_start, 
         dtime_end, 
         code_status, 
         duration, 
         text_message
      FROM activity_base
      WHERE flag_display_record = c_flag_y
      ORDER BY dtime_inserted ASC;
      
    a_workflow_activity_log tt_workflow_activity_log;
          
  BEGIN

    -- Open cursor and fetch data
    OPEN c_workflow_activity_log;
      FETCH c_workflow_activity_log BULK COLLECT INTO a_workflow_activity_log;
    CLOSE c_workflow_activity_log;
    
    -- Set result
    p_workflow_activity_log := a_workflow_activity_log; 
     
  EXCEPTION
    WHEN OTHERS THEN
      -- Close cursor
      IF c_workflow_activity_log%ISOPEN THEN CLOSE c_workflow_activity_log; END IF;
    
  END get_workflow_activity_log;
  
END lib_etl_workflow_api;
/
