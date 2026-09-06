--UTF8-BOM: české znaky: ěščřžýáíé a ruské znaky: йцгшщзфы a čínské znaky: 你好世界
--nemazat !!!
DECLARE 
  x_sequence VARCHAR(30 CHAR) := 'OWNER_CORE.S_ETL_PARTITION_LOG';
  x_table VARCHAR(30 CHAR) := 'OWNER_CORE.ETL_PARTITION_LOG';

  x_max NUMBER;
  x_current NUMBER;
  x_diff NUMBER;
  x_increment NUMBER;
  x_column VARCHAR2(30 CHAR);
BEGIN 
  SELECT column_name
  INTO x_column
  FROM dba_constraints c
  JOIN dba_cons_columns cc
    ON cc.constraint_name = c.constraint_name
   AND cc.owner = c.owner
 WHERE c.table_name = 'ETL_PARTITION_LOG'
   AND c.constraint_type = 'P'
   AND position = 1;

  EXECUTE IMMEDIATE 'select max('||x_column||') from ' || x_table INTO x_max;
  EXECUTE IMMEDIATE 'select '|| x_sequence || '.nextval from dual' INTO x_current;
  x_diff := x_max - x_current;
  IF x_diff > 0 THEN
    EXECUTE IMMEDIATE 'alter sequence '|| x_sequence || ' increment by ' || x_diff;
    EXECUTE IMMEDIATE 'select '|| x_sequence || '.nextval from dual' INTO x_current;
    EXECUTE IMMEDIATE 'alter sequence '|| x_sequence || ' increment by 1';
  END IF;
  dbms_output.put_line('Sequence: '|| x_sequence || ' was set to value: ' || to_char(x_current));
END;
/