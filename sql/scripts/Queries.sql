/* To See all the table has been present or not*/
select name 
from sqlite_master
where type='table';

/* To see all the column names present in the table*/
SELECT name
FROM pragma_table_info('Device_Health_Log');