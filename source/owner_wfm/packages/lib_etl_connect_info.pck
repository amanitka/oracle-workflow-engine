CREATE OR REPLACE PACKAGE owner_wfm.lib_etl_connect_info IS

  ---------------------------------------------------------------------------------------------------------
  -- author:  Ludek
  -- created: 22.3.2019
  -- purpose: Store and retrieve connection info
  ---------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
  c_flag_N                   CONSTANT VARCHAR2(1)  := 'N';

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_CONNECT_INFO
  -- purpose:        Set connection info. Password will be encrypted.
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_connect_info(p_code_connect  IN VARCHAR2,
                             p_name_user     IN VARCHAR2,
                             p_text_password IN VARCHAR2,
                             p_text_host     IN VARCHAR2,
                             p_flag_deleted  IN VARCHAR2 DEFAULT c_flag_N);

  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_CONNECT_INFO
  -- purpose:        Get connection info
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_connect_info(p_code_connect  IN VARCHAR2,
                             p_name_user     OUT VARCHAR2,
                             p_text_password OUT VARCHAR2,
                             p_text_host     OUT VARCHAR2);
                            
END lib_etl_connect_info;
/
CREATE OR REPLACE PACKAGE BODY owner_wfm.lib_etl_connect_info IS

  ---------------------------------------------------------------------------------------------------------
  -- Global variables
  ---------------------------------------------------------------------------------------------------------  
      
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: SET_CONNECT_INFO
  -- purpose:        Set connection info. Password will be encrypted.
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE set_connect_info(p_code_connect  IN VARCHAR2,
                             p_name_user     IN VARCHAR2,
                             p_text_password IN VARCHAR2,
                             p_text_host     IN VARCHAR2,
                             p_flag_deleted  IN VARCHAR2 DEFAULT c_flag_N)
  IS
  
    v_text_password VARCHAR2(30);
  
  BEGIN
    
    -- If the password is provided, encrypt it
    IF p_text_password IS NOT NULL THEN
      v_text_password := owner_core.ps_global_crypt.encryptpwd(p_text_password);
    END IF;
    
    -- Store connection info
    MERGE INTO owner_wfm.etl_connect_info t
    USING (SELECT
              p_code_connect  AS code_connect,
              p_name_user     AS name_user,
              v_text_password AS text_password,
              p_text_host     AS text_host,
              p_flag_deleted  AS flag_deleted
           FROM dual
           ) s
    ON (t.code_connect = s.code_connect)
    WHEN NOT MATCHED THEN
      INSERT
        (code_connect, 
         name_user, 
         text_password, 
         text_host, 
         flag_deleted)  
      VALUES
        (s.code_connect, 
         s.name_user, 
         s.text_password, 
         s.text_host, 
         s.flag_deleted)
    WHEN MATCHED THEN
      UPDATE SET
        t.name_user     = s.name_user, 
        t.text_password = s.text_password, 
        t.text_host     = s.text_host, 
        t.flag_deleted  = s.flag_deleted;
  
    -- Commit 
    COMMIT;
            
  END set_connect_info;
  
  ---------------------------------------------------------------------------------------------------------
  -- procedure name: GET_CONNECT_INFO
  -- purpose:        Get connection info
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE get_connect_info(p_code_connect  IN VARCHAR2,
                             p_name_user     OUT VARCHAR2,
                             p_text_password OUT VARCHAR2,
                             p_text_host     OUT VARCHAR2)
  IS
  
  BEGIN
    
    -- Get connect info
    SELECT
       name_user                                            AS name_user,
       owner_core.ps_global_crypt.decryptpwd(text_password) AS text_password,
       text_host                                            AS text_host
      INTO
       p_name_user,
       p_text_password,
       p_text_host
    FROM owner_wfm.etl_connect_info
    WHERE code_connect = p_code_connect
      AND flag_deleted = c_flag_N;
      
  EXCEPTION
    WHEN no_data_found THEN
      -- Raise error
      raise_application_error(-20001, 'Missing connection info in table etl_connect_info for code connection - '||p_code_connect||'!', TRUE); 
            
  END get_connect_info;
    
END lib_etl_connect_info;
/
