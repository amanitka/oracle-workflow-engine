--UTF8-BOM: české znaky: ěščřžýáíé a ruské znaky: йцгшщзфы a čínské znaky: 你好世界
--nemazat !!!
-- REGRANT objects, RECREATE VH/VD views, REFRESH WF metadata, REFRESH PREPROD metadata
SET SERVEROUTPUT ON SIZE 1000000;

ALTER PACKAGE appdeploy.lib_deployment_utils COMPILE;

BEGIN
  IF ora_database_name NOT LIKE 'PATCH_DB%' THEN
     appdeploy.lib_deployment_utils.execute_all;
  END IF;   
END;
/

-- Regrant objects according to roles
BEGIN
  IF ora_database_name NOT LIKE 'PATCH_DB%' THEN
    dbadmin.lib_ap_grants.grant_ALL;
  END IF;
END;
/
