CREATE OR REPLACE TRIGGER owner_wfm.trg_etl_process_condition BEFORE INSERT OR UPDATE
ON owner_wfm.etl_process_condition FOR EACH ROW
DECLARE

   v_user    VARCHAR2(60);
   v_sysdate DATE;

BEGIN
    
  -- Set user name
  v_user := CASE WHEN SYS_CONTEXT('USERENV', 'PROXY_USER') IS NULL THEN SYS_CONTEXT('USERENV', 'SESSION_USER')
                 ELSE SYS_CONTEXT('USERENV', 'PROXY_USER') ||'['|| SYS_CONTEXT('USERENV', 'SESSION_USER')||']'
             END;
   
  -- Set date
  v_sysdate := SYSDATE;

  IF inserting THEN
       
    :new.user_inserted := v_user;
    :new.dtime_inserted := v_sysdate;
    :new.user_updated := v_user;
    :new.dtime_updated := v_sysdate; 
  
  ELSIF updating THEN
  
    :new.user_updated := v_user;
    :new.dtime_updated := v_sysdate; 
  
  END IF;

END;
/
