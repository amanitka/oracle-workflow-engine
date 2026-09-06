CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_support_util is

  ---------------------------------------------------------------------------------------------------------
  -- author:  Workflow Team
  -- created: 23.3.2018
  -- purpose: Support package for workflow manager module
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_DURATION
  -- purpose:       Calculate duration from dates
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_duration(p_dtime_start IN DATE,
                        p_dtime_end   IN DATE) RETURN VARCHAR2;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_SQL_INFO
  -- purpose:        Get sql text and plan for given session
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE get_sql_info(p_id_instance   IN NUMBER,
                         p_id_session    IN NUMBER,
                         p_id_serial     IN NUMBER,
                         p_text_sql      OUT CLOB,
                         p_text_sql_plan OUT CLOB);
                                                         
END lib_etl_support_util;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_support_util IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------
  c_mod_name             CONSTANT VARCHAR2(30) := 'LIB_ETL_SUPPORT_UTIL';    
  c_date_future          CONSTANT DATE := DATE'3000-01-01';  

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_DURATION
  -- purpose:       Calculate duration from dates
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_duration(p_dtime_start IN DATE,
                        p_dtime_end   IN DATE) RETURN VARCHAR2                    
  AS
  
    v_duaration NUMBER;
    v_result    VARCHAR2(30);  
  
  BEGIN
    
    -- Compute duration in hours
    v_duaration := (CASE WHEN p_dtime_end = c_date_future THEN SYSDATE ELSE NVL(p_dtime_end, SYSDATE) END - p_dtime_start) * 24;
    
    -- Prepare duration in format HH24:MI:SS
    IF v_duaration IS NOT NULL THEN
      v_result := TO_CHAR(TRUNC(v_duaration)) || ':' || SUBSTR(TO_CHAR(TRUNC(MOD(v_duaration * 60, 60)), '09'), 2) || ':' || SUBSTR(TO_CHAR(MOD(v_duaration * 60 * 60, 60), '09'), 2);
    ELSE
      v_result := NULL;
    END IF; 
    
    -- Return result
    RETURN v_result;
  
  END get_duration;

  ---------------------------------------------------------------------------------------------------------
  -- function name: GET_SQL_PLAN
  -- purpose:       Get sql execution plan
  ---------------------------------------------------------------------------------------------------------
  FUNCTION get_sql_plan(p_id_instance          IN NUMBER,
                        p_id_sql               IN VARCHAR2,
                        p_num_sql_child_number IN NUMBER) RETURN CLOB
  AS
    
    v_result CLOB;

    CURSOR c_execution_plan IS
      SELECT 
         plan_table_output||CHR(10) AS execution_plan
      FROM TABLE(sys.dbms_xplan.display(table_name   => 'gv$sql_plan_statistics_all',
                                        statement_id => NULL,
                                        format       => 'ADVANCED +peeked_binds',
                                        filter_preds => 'inst_id = '||p_id_instance||' AND sql_id = '''||p_id_sql||''' AND child_number = '||p_num_sql_child_number));
                                                                            
  BEGIN
     
    -- Initialize CLOB
    sys.dbms_lob.createtemporary(v_result, TRUE);
    
    -- Loop through rows
    FOR eplan IN c_execution_plan
    LOOP
      
      dbms_lob.append(v_result, eplan.execution_plan);
    
    END LOOP;
    
    RETURN v_result;
    
  END get_sql_plan;

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_SQL_INFO
  -- purpose:        Get sql text and plan for given session
  --------------------------------------------------------------------------------------------------------- 
  PROCEDURE get_sql_info(p_id_instance   IN NUMBER,
                         p_id_session    IN NUMBER,
                         p_id_serial     IN NUMBER,
                         p_text_sql      OUT CLOB,
                         p_text_sql_plan OUT CLOB)
  IS
  
    c_proc_name            VARCHAR2(30) := 'GET_SQL_INFO';
    v_id_sql               VARCHAR2(100);
    v_num_sql_child_number NUMBER;
    
  BEGIN   
   
    -- Get sql information
    BEGIN
    
      SELECT
         s.sql_id,
         s.sql_child_number, 
         sq.sql_fulltext
        INTO
         v_id_sql,
         v_num_sql_child_number,
         p_text_sql
      FROM sys.gv_$session s
      JOIN sys.gv_$sql sq ON sq.inst_id = s.inst_id
                         AND sq.sql_id = s.sql_id
                         AND sq.hash_value = s.sql_hash_value
                         AND sq.child_number = s.sql_child_number
      WHERE s.inst_id = p_id_instance
        AND s.sid = p_id_session
        AND s.serial# = p_id_serial
        AND rownum = 1;
        
    EXCEPTION
      WHEN no_data_found THEN
        -- Set result to NULL
        v_id_sql               := NULL;
        v_num_sql_child_number := NULL;
        p_text_sql             := NULL;
        
    END;
    
    -- If sql information was filled then get execution plan
    IF v_id_sql IS NOT NULL
        AND v_num_sql_child_number IS NOT NULL THEN 
         
      -- Get sql execution plan 
      p_text_sql_plan := get_sql_plan(p_id_instance          => p_id_instance,
                                      p_id_sql               => v_id_sql,
                                      p_num_sql_child_number => v_num_sql_child_number);
                                      
    END IF;
                                                        
  END get_sql_info;
  
END lib_etl_support_util;
/
