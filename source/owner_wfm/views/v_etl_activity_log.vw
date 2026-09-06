--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_etl_activity_log
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_activity_log
AS
SELECT
   l.rowid              AS id_activity_log,
   l.name_activity_type AS name_activity_type, 
   l.name_activity      AS name_activity, 
   l.text_message       AS text_message, 
   l.dtime_inserted     AS dtime_inserted, 
   l.date_inserted      AS date_inserted, 
   l.user_inserted      AS user_inserted
FROM owner_wfm.etl_activity_log l
WHERE l.date_inserted >= TRUNC(SYSDATE - 1)
ORDER BY l.dtime_inserted DESC
WITH READ ONLY;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_etl_activity_log
-----------------------------------------------------------------
-- Add comments to the table 
COMMENT ON TABLE owner_wfm.v_etl_activity_log IS 'Logging table for all activities';
-- Add comments to the columns 
COMMENT ON COLUMN owner_wfm.v_etl_activity_log.id_activity_log IS 'Activity log id';
COMMENT ON COLUMN owner_wfm.v_etl_activity_log.name_activity_type IS 'Type of activity - WARNING/MESSAGE/ERROR or others';
COMMENT ON COLUMN owner_wfm.v_etl_activity_log.name_activity IS 'Name of activity';
COMMENT ON COLUMN owner_wfm.v_etl_activity_log.text_message IS 'Message of activity';
COMMENT ON COLUMN owner_wfm.v_etl_activity_log.dtime_inserted IS 'Date and time when the record was inserted';
COMMENT ON COLUMN owner_wfm.v_etl_activity_log.date_inserted IS 'Date when the record was inserted';
COMMENT ON COLUMN owner_wfm.v_etl_activity_log.user_inserted IS 'User who inserted the record';
/
