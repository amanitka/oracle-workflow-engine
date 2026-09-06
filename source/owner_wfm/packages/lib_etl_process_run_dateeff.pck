CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_process_run_dateeff is

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 15.3.2018
  -- purpose: Get start date effective for given process
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_DATE_EFFECTIVE_NEXT_PLAN
  -- purpose:        Get next planned date effective for given process     
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_date_effective_next_plan(p_id_process          IN INTEGER,
                                        p_date_effective_max  IN DATE,                         
                                        p_date_effective_curr IN DATE,
                                        p_code_status_curr    IN VARCHAR2) RETURN DATE RESULT_CACHE;
                                        
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_DATE_EFFECTIVE_REFR_INCR
  -- purpose:        Get next date effective for refr / incr processes   
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_date_effective_refr_incr(p_name_process       IN VARCHAR2,
                                        p_date_effective_max IN DATE) RETURN DATE RESULT_CACHE;

END lib_etl_process_run_dateeff;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_process_run_dateeff IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------   
  c_flag_n        CONSTANT VARCHAR2(1)  := 'N';
  c_flag_y        CONSTANT VARCHAR2(1)  := 'Y';
  c_xna           CONSTANT VARCHAR2(10) := 'XNA';
  c_code_complete CONSTANT VARCHAR2(10) := 'COMPLETE';
  c_status_cancel CONSTANT VARCHAR2(10) := 'CANCEL';
  c_months        CONSTANT INTEGER := 2;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_DATE_EFFECTIVE_NEXT_PLAN
  -- purpose:        Get next planned date effective for given process     
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_date_effective_next_plan(p_id_process          IN INTEGER,
                                        p_date_effective_max  IN DATE,                         
                                        p_date_effective_curr IN DATE,
                                        p_code_status_curr    IN VARCHAR2) RETURN DATE RESULT_CACHE RELIES_ON (owner_wfm.etl_process_instance,
                                                                                                               owner_wfm.etl_process_plan)
  AS
  
    c_mapping             CONSTANT VARCHAR2(30) := 'GET_DATE_EFFECTIVE_NEXT_PLAN';
    v_date_effective_curr DATE; 
    v_date_effective_new  DATE;      
    v_result              DATE;  

  BEGIN
      
    -- If status is not canceled then keep value from parameter
    IF p_code_status_curr != c_status_cancel THEN
    
      v_date_effective_curr := p_date_effective_curr;
    
    -- Otherwise get date effective from the process instance
    ELSE
      
      BEGIN
        SELECT
           MAX(date_effective)
          INTO
           v_date_effective_curr 
        FROM owner_wfm.etl_process_instance
        WHERE id_process = p_id_process
          AND date_effective >= ADD_MONTHS(p_date_effective_curr, (c_months * -1)) 
          AND NVL(code_status, c_xna) != c_status_cancel;
      EXCEPTION
        WHEN no_data_found THEN
          v_date_effective_curr := NULL;
      END;
      
    END IF;

    -- Get next date effective from process plan
    IF v_date_effective_curr IS NOT NULL THEN
      
      BEGIN
        SELECT
           MIN(TRUNC(date_effective))
          INTO
           v_date_effective_new
        FROM owner_wfm.etl_process_plan
        WHERE id_process = p_id_process
          AND date_effective BETWEEN v_date_effective_curr + 1 AND p_date_effective_max 
          AND flag_plan_status != c_flag_n;
      EXCEPTION
        WHEN no_data_found THEN
          v_date_effective_new := NULL; 
      END;
      
    ELSE
      
      v_date_effective_new := NULL; 
      
    END IF;
    
    -- If cannot propose new effective date, return effective date of last run of process
    v_result := NVL(v_date_effective_new, v_date_effective_curr);
    RETURN v_result;

  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(-20001, 'Error in date effective determination '||c_mapping, TRUE);
      RETURN NULL;

  END get_date_effective_next_plan;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_DATE_EFFECTIVE_REFR_INCR
  -- purpose:        Get next date effective for refr / incr processes   
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_date_effective_refr_incr(p_name_process       IN VARCHAR2,
                                        p_date_effective_max IN DATE) RETURN DATE RESULT_CACHE RELIES_ON (owner_wfm.etl_process_status,
                                                                                                          owner_wfm.etl_process_instance,
                                                                                                          owner_wfm.etl_process_plan,
                                                                                                          owner_hub.etl_date_effective_settings)
                                                                                                        
  AS
     
    c_mapping                  CONSTANT VARCHAR2(30) := 'GET_DATE_EFFECTIVE_REFRINCR';
    v_result                   DATE;
    v_cnt                      INTEGER := 0;
    v_id_process_refr          INTEGER;
    v_id_process_incr          INTEGER;
    v_date_effective_last      DATE; 
    v_date_effective_refr_curr DATE;
    v_date_effective_incr_curr DATE;
    v_name_process_base        VARCHAR2(30);
    v_name_process_suffix      VARCHAR2(30);
    v_name_process_refr        VARCHAR2(30);
    v_name_process_incr        VARCHAR2(30);
    v_code_status              VARCHAR2(10);

  BEGIN

    -- Set base process name
    v_name_process_base := SUBSTR(p_name_process, 1 ,INSTR(p_name_process, '_', 1, 3));
    
    -- Set suffix process name
    v_name_process_suffix := SUBSTR(p_name_process, INSTR(p_name_process, '_', 1, 3) + 1);
      
    -- Set refr process name
    IF v_name_process_suffix LIKE 'REFR%' THEN
      v_name_process_refr := v_name_process_base||v_name_process_suffix;
    ELSE 
      v_name_process_refr := v_name_process_base||'REFR';
    END IF;
    
    -- Set incr process name
    v_name_process_incr := v_name_process_base||'INCR';

    -- Get last effective date from metadata
    v_date_effective_last := owner_hub.lib_context_etl.get_last_dateeffective;
      
    -- Get last used effective date for refr process
    BEGIN
      
      SELECT
         id_process,      
         date_effective,
         code_status
        INTO
         v_id_process_refr,
         v_date_effective_refr_curr,
         v_code_status
      FROM owner_wfm.etl_process_status
      WHERE name_process = v_name_process_refr;
      
    EXCEPTION
      WHEN no_data_found THEN
        v_id_process_refr          := NULL;
        v_date_effective_refr_curr := NULL;
        v_code_status              := NULL;
        
    END; 
    
    IF v_id_process_refr IS NOT NULL AND v_code_status != c_code_complete THEN
      
      SELECT
         MAX(date_effective)
        INTO
         v_date_effective_refr_curr 
      FROM owner_wfm.etl_process_instance
      WHERE id_process = v_id_process_refr
        AND date_effective >= ADD_MONTHS(v_date_effective_refr_curr, (c_months * -1))
        AND code_status = c_code_complete;
      
    END IF;

    -- Get last used effective date for incr process
    BEGIN
      
      SELECT
         id_process,      
         date_effective,
         code_status
        INTO
         v_id_process_incr,
         v_date_effective_incr_curr,
         v_code_status
      FROM owner_wfm.etl_process_status
      WHERE name_process = v_name_process_incr;
      
    EXCEPTION
      WHEN no_data_found THEN
        v_id_process_incr          := NULL;
        v_date_effective_incr_curr := NULL;
        v_code_status              := NULL;
    END; 
    
    IF v_id_process_incr IS NOT NULL AND v_code_status != c_code_complete THEN
      
      SELECT
         MAX(date_effective)
        INTO
         v_date_effective_incr_curr 
      FROM owner_wfm.etl_process_instance
      WHERE id_process = v_id_process_incr
        AND date_effective >= ADD_MONTHS(v_date_effective_incr_curr, (c_months * -1))
        AND code_status = c_code_complete;
      
    END IF;
       
    -- In case thats process has only INCR, or REFR didnt run yet
    IF v_date_effective_refr_curr IS NULL AND v_date_effective_incr_curr IS NOT NULL THEN
      
      -- Set REFR effective date
      v_date_effective_refr_curr :=  LEAST(v_date_effective_incr_curr, v_date_effective_last);
    
    END IF;
      
    -- Find out how many days are between REFR and INCR processes  
    IF v_date_effective_refr_curr IS NOT NULL AND v_date_effective_incr_curr IS NOT NULL THEN
      
      IF v_date_effective_refr_curr < v_date_effective_incr_curr THEN

        -- minuse one for situation when incr has greater effective date
        v_cnt := -1;
       
      ELSIF v_date_effective_refr_curr = v_date_effective_incr_curr THEN
        
        -- zero days
        v_cnt := 0;
      
      ELSIF v_date_effective_refr_curr - v_date_effective_incr_curr = 1 THEN
        
        -- one day
        v_cnt := 1; 
      
      ELSE
        
        -- more days
        v_cnt := 2; 
          
      END IF;
          
    ELSE
      
      -- minus two for situation when INCR or REFR have not run yet 
      v_cnt := -2;
      
    END IF;
      
    -- Set new date effective
    IF v_cnt <= 0 THEN
      
      -- If its INCR process 
      IF p_name_process = v_name_process_incr THEN
          
        -- Effective date will be taken from plan
        BEGIN
          
          SELECT
             COALESCE(MIN(CASE WHEN flag_plan_status = c_flag_y THEN date_effective ELSE NULL END),
                      MAX(CASE WHEN flag_plan_status = '?'      THEN date_effective ELSE NULL END),
                      v_date_effective_incr_curr
                      ) res
            INTO v_result
          FROM owner_wfm.etl_process_plan
          WHERE id_process = v_id_process_incr
            AND date_effective > v_date_effective_incr_curr
            AND date_effective <= v_date_effective_last;
          
        EXCEPTION
          WHEN no_data_found THEN
            v_result := v_date_effective_incr_curr;
            
        END; 
            
      -- If its REFR process
      ELSE
        
        BEGIN
      
          SELECT
             COALESCE(MIN(CASE WHEN flag_plan_status = c_flag_y THEN date_effective ELSE NULL END),
                      MAX(CASE WHEN flag_plan_status = '?'      THEN date_effective ELSE NULL END),
                      v_date_effective_refr_curr
                      ) res
            INTO v_result
          FROM owner_wfm.etl_process_plan
          WHERE id_process = v_id_process_refr
            AND date_effective > v_date_effective_incr_curr
            AND date_effective <= v_date_effective_last;

        EXCEPTION
          WHEN no_data_found THEN
            v_result := v_date_effective_refr_curr;
          
        END; 

      END IF;
            
    ELSIF v_cnt = 1 THEN
      
      -- Effective date will be taken from last run of REFR process
      v_result := v_date_effective_refr_curr;
      
    ELSIF v_cnt > 1 THEN
      
      -- If its INCR process 
      IF p_name_process = v_name_process_incr THEN
        
        -- Find out next possible effective date
        SELECT
           MIN(CASE WHEN flag_plan_status = c_flag_y THEN date_effective ELSE NULL END)
          INTO 
           v_result
        FROM owner_wfm.etl_process_plan
        WHERE id_process = v_id_process_incr
          AND date_effective > v_date_effective_incr_curr 
          AND date_effective <= v_date_effective_refr_curr;
          
        -- If the result is NULL or different from last run of REFR process use current INCR date
        -- Otherwise use the result which is equal of last run of REFR process
        IF v_result IS NULL OR v_result != v_date_effective_refr_curr THEN
         
          -- Effective date will be take from last run of INCR process 
          v_result := v_date_effective_incr_curr;
        
        END IF;
      
      -- If its REFR process
      ELSE
        
        -- Effective date will be taken from last run of REFR process
        v_result := v_date_effective_refr_curr;
        
      END IF;
      
      -- Log error
      --owner_core.ms_global_log.os_error(0, 'Unable to set effective date for process '||p_name_process||'. There are more than one unprocessed effective days, where INCR process did not run.', 'EFFDATEMTH');
      
    END IF;
    
    -- If its INCR process, then prevent launch for actual/maximal date effective (current date + timeshift)
    IF p_name_process = v_name_process_incr AND v_date_effective_incr_curr IS NOT NULL THEN
      
      -- If new effective date is same as maximal date effective
      IF v_result = p_date_effective_max THEN
        
        -- Effective date will be take from last run of INCR process in order to prevent launch for maximal date effective
        v_result := v_date_effective_incr_curr;
        
      END IF;
    
    END IF;
    
    -- Return result
    RETURN v_result;

  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(-20002, 'Error in date effective determination '||c_mapping, TRUE);
      RETURN NULL;
      
  END get_date_effective_refr_incr;

END lib_etl_process_run_dateeff;
/
