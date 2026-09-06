CREATE OR REPLACE PACKAGE OWNER_WFM.lib_etl_global_config_param is

  ---------------------------------------------------------------------------------------------------------
  -- author:  Workflow Team
  -- created: 16.04.2018
  -- purpose: API for global config parameters
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: CREATE_PARAMETER
  -- purpose:        create new parameter in ETL_GLOBAL_CONFIG_PARAMETERS metadata table
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE create_parameter(p_code_parameter       IN VARCHAR2,
                             p_name_parameter       IN VARCHAR2 DEFAULT NULL,
                             p_code_group           IN VARCHAR2,
                             p_name_group           IN VARCHAR2 DEFAULT NULL,
                             p_code_data_type       IN VARCHAR2,
                             p_text_value           IN VARCHAR2 DEFAULT NULL);


  ---------------------------------------------------------------------------------------------------------
  -- function name:  GET_PARAMETER_VALUE
  -- purpose:        return parameter value for current code_parameter and code_group
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_parameter_value(p_code_parameter  IN VARCHAR2,
                               p_code_group      IN VARCHAR2) RETURN VARCHAR2 RESULT_CACHE;
                          
  ---------------------------------------------------------------------------------------------------------
  -- procedure name:  SET_PARAMETER_VALUE
  -- purpose:        set parameter value
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_parameter_value(p_code_parameter       IN VARCHAR2,
                                p_code_group           IN VARCHAR2,
                                p_text_value           IN VARCHAR2);


  ---------------------------------------------------------------------------------------------------------
  -- procedure name:  GET_AUTORESTART_PARAMETERS
  -- purpose:        return parameter value for autorestart
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_autorestart_parameters(p_text_sqlerror IN VARCHAR2,
                                       p_cnt_loop      OUT NUMBER,
                                       p_num_wait_sec  OUT NUMBER);


                          
END lib_etl_global_config_param;
/
CREATE OR REPLACE PACKAGE BODY OWNER_WFM.lib_etl_global_config_param IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------   
  c_mod_name              CONSTANT VARCHAR2(30) := 'LIB_ETL_GLOBAL_CONFIG_PARAM';    
  c_log_type_error        CONSTANT VARCHAR2(10) := 'ERROR';
  v_text_check_message    VARCHAR2(2000);
  v_msg                   VARCHAR2(2000);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: create_parameter
  -- purpose:        create new parameter in ETL_GLOBAL_CONFIG_PARAMETERS metadata table
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE create_parameter(p_code_parameter       IN VARCHAR2,
                             p_name_parameter       IN VARCHAR2 DEFAULT NULL,
                             p_code_group           IN VARCHAR2,
                             p_name_group           IN VARCHAR2 DEFAULT NULL,
                             p_code_data_type       IN VARCHAR2,
                             p_text_value           IN VARCHAR2 DEFAULT NULL) 
  IS
    v_nflag_exist integer := 0;
    v_msg         varchar2(1000 char);
    v_proc_name   varchar2(40) := 'create_param';
  BEGIN

    --check if parameter exists
    SELECT Count(1)
      INTO v_nflag_exist
      FROM owner_wfm.etl_global_config_parameter
     WHERE code_parameter = p_code_parameter
       AND code_group = p_code_group;

    --stop, if parameter exists
    IF (v_nflag_exist > 1) THEN
      --log error
      v_msg := 'During the creation of new global parameter were detected more records for code_parameter = '||p_code_parameter||', code_group = '||p_code_group;
      v_text_check_message := 'Error in '||c_mod_name||'.'||v_proc_name||': '||v_msg;
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_mod_name||'.'||v_proc_name,                         
                                             p_text_message       => v_text_check_message);
      raise_application_error(-20100, v_msg);
    ELSE
      --create new param
      INSERT INTO owner_wfm.etl_global_config_parameter
        (
        code_parameter, 
        name_parameter, 
        code_group, 
        name_group, 
        code_data_type, 
        text_value, 
        flag_deleted, 
        user_inserted, 
        user_updated, 
        dtime_inserted, 
        dtime_updated
        )
      VALUES
        (
        p_code_parameter, 
        p_name_parameter, 
        p_code_group, 
        p_name_group, 
        p_code_data_type, 
        p_text_value, 
        'N',
        user,
        user,
        SYSDATE,
        sysdate
        );
      commit;
     END IF;

  END create_parameter;

  ---------------------------------------------------------------------------------------------------------
  -- function name:  GET_PARAMETER_VALUE
  -- purpose:        return parameter value for current code_parameter and code_group
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_parameter_value(p_code_parameter  IN VARCHAR2,
                               p_code_group      IN VARCHAR2) RETURN VARCHAR2 RESULT_CACHE RELIES_ON (owner_wfm.etl_global_config_parameter)
  IS
  
    v_proc_name     VARCHAR2(80) := 'get_param_value';
    v_text_value    owner_wfm.etl_global_config_parameter.text_value%TYPE;
  
  BEGIN

    --get the current value
    SELECT text_value
      INTO v_text_value
      FROM owner_wfm.etl_global_config_parameter
     WHERE code_parameter = p_code_parameter
       AND code_group     = p_code_group;

    RETURN v_text_value;

  EXCEPTION
    WHEN no_data_found THEN

      v_msg := 'No parameter found for code_parameter = '||p_code_parameter||', code_group = '||p_code_group;
      v_text_check_message := 'Error in '||c_mod_name||'.'||v_proc_name||': '||v_msg;
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_mod_name||'.'||v_proc_name,                         
                                             p_text_message       => v_text_check_message);
      raise_application_error(-20100, v_msg);

    WHEN too_many_rows THEN

      v_msg := 'Detected more than one records for code_parameter = '||p_code_parameter||', code_group = '||p_code_group;
      v_text_check_message := 'Error in '||c_mod_name||'.'||v_proc_name||': '||v_msg;
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_mod_name||'.'||v_proc_name,                         
                                             p_text_message       => v_text_check_message);
      raise_application_error(-20100, v_msg);

    WHEN OTHERS THEN
      raise;
  END get_parameter_value;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_PARAMETER_VALUE
  -- purpose:        set parameter value
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_parameter_value(p_code_parameter       IN VARCHAR2,
                                p_code_group           IN VARCHAR2,
                                p_text_value           IN VARCHAR2) 
  IS

    v_proc_name   VARCHAR2(80) := 'set_param_value';
    v_row        owner_wfm.etl_global_config_parameter%ROWTYPE;

  BEGIN

    --get the current value
    SELECT *
      INTO v_row
      FROM owner_wfm.etl_global_config_parameter
     WHERE code_parameter = p_code_parameter
       AND code_group     = p_code_group;

    --if exists set/update
    UPDATE owner_wfm.etl_global_config_parameter
       SET text_value = nvl(p_text_value, text_value)
     WHERE code_parameter = p_code_parameter
       AND code_group     = p_code_group;
    commit;

    RETURN;

  EXCEPTION
    WHEN no_data_found THEN

      v_msg := 'No parameter found for code_parameter = '||p_code_parameter||', code_group = '||p_code_group;
      v_text_check_message := 'Error in '||c_mod_name||'.'||v_proc_name||': '||v_msg;
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_mod_name||'.'||v_proc_name,                         
                                             p_text_message       => v_text_check_message);
      raise_application_error(-20100, v_msg);

    WHEN too_many_rows THEN

      v_msg := 'Detected more than one records for code_parameter = '||p_code_parameter||', code_group = '||p_code_group;
      v_text_check_message := 'Error in '||c_mod_name||'.'||v_proc_name||': '||v_msg;
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_mod_name||'.'||v_proc_name,                         
                                             p_text_message       => v_text_check_message);
      raise_application_error(-20100, v_msg);

    WHEN OTHERS THEN
      RAISE;
  END set_parameter_value;
  
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name:  GET_AUTORESTART_PARAMETERS
  -- purpose:        return parameter value for autorestart
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_autorestart_parameters(p_text_sqlerror  IN VARCHAR2,
                                       p_cnt_loop      OUT NUMBER,
                                       p_num_wait_sec  OUT NUMBER) IS
    
    v_proc_name   VARCHAR2(80) := 'get_autorestart_parameters';
    
    ex_loop       EXCEPTION;
    ex_wait_sec   EXCEPTION;
    
  BEGIN
    WITH autorestart_rules AS (SELECT 
                                  MAX(DECODE(SUBSTR(code_parameter, INSTR(code_parameter,'_') + 1), 'ERRC', text_value, NULL))     AS code_error,
                                  MAX(DECODE(SUBSTR(code_parameter, INSTR(code_parameter,'_') + 1), 'LOOP', text_value, NULL))     AS cnt_loop,
                                  MAX(DECODE(SUBSTR(code_parameter, INSTR(code_parameter,'_') + 1), 'WAIT', text_value ,NULL))     AS num_wait_sec
                               FROM owner_wfm.etl_global_config_parameter
                               WHERE code_group = 'WF_RESTART'
                                 AND flag_deleted = 'N'
                               GROUP BY SUBSTR(code_parameter, 1, INSTR(code_parameter,'_') - 1)
                               )
    SELECT
--       code_error,
       cnt_loop,
       num_wait_sec 
      INTO p_cnt_loop, p_num_wait_sec
      FROM autorestart_rules
      WHERE p_text_sqlerror LIKE '%'||code_error||'%'
        AND ROWNUM = 1;
    
    IF NVL(p_cnt_loop, 0) <= 0 THEN
      RAISE ex_loop;
    END IF;
    IF NVL(p_num_wait_sec, 0) <= 0 THEN
      RAISE ex_wait_sec;
    END IF;
    
     
  EXCEPTION
    WHEN no_data_found THEN 
      p_cnt_loop     := NULL;
      p_num_wait_sec := NULL;

    WHEN ex_loop THEN 
      v_msg := 'Loop count is <= 0';
      v_text_check_message := 'Error in '||c_mod_name||'.'||v_proc_name||': '||v_msg;
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_mod_name||'.'||v_proc_name,                         
                                             p_text_message       => v_text_check_message);
      raise_application_error(-20100, v_msg);

    WHEN ex_wait_sec THEN 
      v_msg := 'Wait second is <= 0';
      v_text_check_message := 'Error in '||c_mod_name||'.'||v_proc_name||': '||v_msg;
      owner_wfm.lib_etl_log_api.log_activity(p_name_activity_type => c_log_type_error, 
                                             p_name_activity      => c_mod_name||'.'||v_proc_name,                         
                                             p_text_message       => v_text_check_message);
      raise_application_error(-20100, v_msg);

    WHEN OTHERS THEN
      RAISE;
  END;
   

END lib_etl_global_config_param;
/
