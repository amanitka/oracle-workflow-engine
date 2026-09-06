CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_process_copy_metadata IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 20.2.2020
  -- purpose: Copy process metadata during replication of data to preprod
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: COPY_METADATA
  -- purpose:        Copy process metadata during replication of data to preprod
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE copy_metadata(p_name_process   IN VARCHAR2,
                          p_date_effective IN DATE,
                          p_dtime_start    IN DATE,
                          p_dtime_end      IN DATE,
                          p_code_status    IN VARCHAR2,
                          p_num_rows       OUT INTEGER);
 
END lib_etl_process_copy_metadata;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_process_copy_metadata IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------
  c_flag_n          CONSTANT VARCHAR2(1)  := 'N';
  c_xap             CONSTANT VARCHAR2(10) := 'XAP';
                                             
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: COPY_METADATA
  -- purpose:        Copy process metadata during replication of data to preprod     
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE copy_metadata(p_name_process   IN VARCHAR2,
                          p_date_effective IN DATE,
                          p_dtime_start    IN DATE,
                          p_dtime_end      IN DATE,
                          p_code_status    IN VARCHAR2,
                          p_num_rows       OUT INTEGER)
  IS
  
    c_proc_name           VARCHAR2(30) := 'COPY_METADATA';
    c_sysdate             DATE := SYSDATE;
    c_name_user           CONSTANT VARCHAR2(30) := USER;
    v_step                VARCHAR2(500);
    
    v_id_process          INTEGER;
    v_id_process_instance INTEGER;
    v_name_workflow       VARCHAR2(30);
    
  BEGIN
    
    -- Get process information
    v_step := 'Get process information';
    BEGIN
      
      SELECT
         id_process,
         name_workflow
        INTO
         v_id_process,
         v_name_workflow
      FROM owner_wfm.etl_process
      WHERE name_process = p_name_process;
      
    EXCEPTION
      WHEN no_data_found THEN
        -- There is nothing to copy
        RETURN;
    END;
  
    -- Get value for id process instance from sequence
    v_step := 'Get value for id process instance from sequence';
    SELECT 
       owner_wfm.s_etl_process_instance.nextval
      INTO
       v_id_process_instance
    FROM dual; 
    
    -- Set process instance
    v_step := 'Set process instance';
    INSERT INTO owner_wfm.etl_process_instance
      (id_process, 
       id_process_instance, 
       id_workflow_instance,
       name_process, 
       date_effective, 
       dtime_start, 
       dtime_end, 
       code_status, 
       flag_restart, 
       dtime_inserted, 
       user_inserted, 
       dtime_updated, 
       user_updated)
    VALUES
      (v_id_process, 
       v_id_process_instance, 
       c_xap, 
       p_name_process, 
       p_date_effective, 
       p_dtime_start, 
       p_dtime_end, 
       p_code_status, 
       c_flag_n, 
       c_sysdate, 
       c_name_user, 
       c_sysdate, 
       c_name_user);
       
    p_num_rows := SQL%ROWCOUNT;
    
    -- Set process status
    v_step := 'Set process status';   
    MERGE INTO owner_wfm.etl_process_status t
    USING (SELECT
              v_id_process          AS id_process, 
              v_id_process_instance AS id_process_instance, 
              c_xap                 AS id_workflow_instance, 
              p_name_process        AS name_process, 
              v_name_workflow       AS name_workflow, 
              p_date_effective      AS date_effective, 
              p_dtime_start         AS dtime_start, 
              p_dtime_end           AS dtime_end, 
              p_code_status         AS code_status, 
              c_flag_n              AS flag_restart, 
              c_sysdate             AS dtime_inserted, 
              c_name_user           AS user_inserted, 
              c_sysdate             AS dtime_updated, 
              c_name_user           AS user_updated
           FROM dual   
           ) s
    ON (t.id_process = s.id_process)
    WHEN NOT MATCHED THEN
      INSERT
        (id_process, 
         id_process_instance, 
         id_workflow_instance, 
         name_process, 
         name_workflow, 
         date_effective, 
         dtime_start, 
         dtime_end, 
         code_status,
         flag_restart, 
         dtime_inserted, 
         user_inserted, 
         dtime_updated, 
         user_updated)
      VALUES
        (s.id_process, 
         s.id_process_instance, 
         s.id_workflow_instance, 
         s.name_process, 
         s.name_workflow, 
         s.date_effective,
         s.dtime_start, 
         s.dtime_end, 
         s.code_status, 
         s.flag_restart, 
         s.dtime_inserted, 
         s.user_inserted, 
         s.dtime_updated, 
         s.user_updated) 
    WHEN MATCHED THEN
      UPDATE SET
        t.id_process_instance  = s.id_process_instance, 
        t.id_workflow_instance = s.id_workflow_instance, 
        t.name_process         = s.name_process, 
        t.name_workflow        = s.name_workflow, 
        t.date_effective       = s.date_effective, 
        t.dtime_start          = s.dtime_start, 
        t.dtime_end            = s.dtime_end, 
        t.code_status          = s.code_status,
        t.flag_restart         = s.flag_restart, 
        t.dtime_updated        = s.dtime_updated, 
        t.user_updated         = s.user_updated; 
      
  EXCEPTION
    WHEN OTHERS THEN
      -- Rollback
      ROLLBACK;
      -- Set message
      raise_application_error(-20001, 'Procedure '||c_proc_name||' ('||v_step||'): '||SQLERRM);
                                             
  END copy_metadata;
    
END lib_etl_process_copy_metadata;
/
