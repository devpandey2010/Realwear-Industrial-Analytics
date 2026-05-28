/*Find devices that need immediate maintenance 
based on combined battery drain and command failure rate with risk classification*/

ALTER TABLE master_session_log
RENAME COLUMN "Battery_drain_%" TO battery_drain_percent;

with device_analysis as(
    select Device_ID,avg(battery_drain_percent) as avg_battery_drain,
    avg(Command_Failures) as Command_Failure
    from Master_Session_Log
    group by Device_ID
),
grouping as(
    select *,round(avg_battery_drain*0.6-command_failure*0.4/100,2)
as battery_health
from device_analysis
)
select *,
case when battery_health<0.3 then "Critical"
when battery_health>0.3 and battery_health<=0.7  then "moderate"
 else "Good" 
 end as battery_codition
 from GROUPING;

