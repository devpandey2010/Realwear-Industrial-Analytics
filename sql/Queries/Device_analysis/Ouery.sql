/*Find devices that need immediate maintenance 
based on combined battery drain and command failure rate with risk classification*/

ALTER TABLE master_session_log
RENAME COLUMN "Battery_drain_%" TO battery_drain_percent;

with device_analysis as(
    select Device_ID,avg(battery_drain_percent) as avg_battery_drain,
    avg(Command_Failures) as avg_Command_Failure
    from Master_Session_Log
    group by Device_ID
),
Normalised as(
    select *,
    Round((Avg_battery_drain-Min(avg_battery_drain)Over())/(Max(avg_battery_drain)over()-Min(avg_battery_drain)over())*100.0,2) as norm_battery_drain,
    Round((avg_command_failure-Min(avg_command_failure)Over())/(Max(avg_command_failure)over()-Min(avg_command_failure)over())*100.0,2) as norm_command_failure
    from device_analysis
    
),
Risk_score as(
    select *,round((norm_battery_drain*0.6+norm_command_failure*0.4),2)
as battery_health
from Normalised
)
select *,
case when battery_health>=70 then "Critical-Immediate Maintenance"
when battery_health>=40 then "moderate-Schedule Maintenance"
 else "Good-No action required" 
 end as battery_condition
 from risk_score
 where battery_condition like "critical-Immediate Maintenance";

/*Identify which plants have most unhealthy devices and how it impacts overall productivity*/

/*Identify which plants have most unhealthy devices 
and how it impacts overall productivity*/

WITH Device_Health AS (
    SELECT 
        m.Plant_Location,
        m.Device_ID,
        ROUND(AVG(m.Productivity_Score), 2) AS Avg_Productivity,
        ROUND(AVG(m.battery_drain_percent), 2) AS Avg_Battery_Drain,
        ROUND(AVG(d.device_Health_Score), 2) AS Avg_Health_Score,
        ROUND(AVG(m.Command_Failures), 2) AS Avg_Command_Failures,
        COUNT(*) AS Total_Sessions
    FROM Master_Session_Log m
    JOIN Device_Health_Log d ON m.Device_ID = d.Device_ID
    GROUP BY m.Plant_Location, m.Device_ID
),
Plant_Summary AS (
    SELECT 
        Plant_Location,
        COUNT(DISTINCT Device_ID) AS Total_Devices,
        COUNT(DISTINCT CASE WHEN Avg_Health_Score < 65 THEN Device_ID END) AS Unhealthy_Devices,
        ROUND(AVG(Avg_Health_Score), 2) AS Avg_Device_Health,
        ROUND(AVG(Avg_Productivity), 2) AS Avg_Productivity,
        ROUND(AVG(Avg_Battery_Drain), 2) AS Avg_Battery_Drain,
        ROUND(AVG(Avg_Command_Failures), 2) AS Avg_Command_Failures
    FROM Device_Health
    GROUP BY Plant_Location
)
SELECT *,
    ROUND(Unhealthy_Devices * 100.0 / Total_Devices, 2) AS Unhealthy_Device_Pct,
    RANK() OVER (ORDER BY Avg_Device_Health ASC) AS Unhealthy_Rank,
    RANK() OVER (ORDER BY Avg_Productivity DESC) AS Productivity_Rank,
    CASE
        WHEN Avg_Device_Health < 40 THEN 'Critical Device Health'
        WHEN Avg_Device_Health < 60 THEN 'Moderate Device Health'
        ELSE 'Good Device Health'
    END AS Health_Status
FROM Plant_Summary
ORDER BY Unhealthy_Rank;

/*Find correlation between device usage frequency and command failure rate*/

--correlation shows relationship between two variable and strength of relationship

with relationship as(
    select device_id,count(*) as total_sessions,
    avg(Command_Failures) as avg_command_failue_per_device
    from Master_Session_Log
    group by device_id
),
Grouping as(
    select *,
    Ntile(4)over(order by total_sessions) as pctile,
    case when Ntile(4)over(order by total_sessions)=1 then 'Low usage'
     when Ntile(4)over(order by total_sessions) =2 then 'Medium Usage'
     when Ntile(4)over(order by total_sessions)=3 then 'high usage'
     else 'very high Usage'
     end as category   
     from relationship 
),
Avg_command_failure_per_group as(
    select *,avg(avg_command_failue_per_device) as command_failure_per_group,
    Min(Total_sessions)over() as Min_sessions,
    Max(Total_sessions)over() as Max_sessions,
    Avg(Total_sessions) as avg_sessions
    from Grouping 
    group by category
)
select *,
case when command_failure_per_group>Lag(command_failure_per_group,1)over(order by avg_sessions) then 'Increasing'
when command_failure_per_group <Lag(command_failure_per_group,1)over(order by avg_sessions) then 'Decreasing'
else 'Stable'
end as Failure_trend
from Avg_command_failure_per_group;

/* This Is Correlation but not causation 
We dont directly say that due to increasing Device usage productivity is decreasing
we need to apply correlation withour causation through confounding variable
then we should dob  A/B testing and then  we can conclude

Possible Confounding variable

Maybe heavily used devices are deployed in high noise plants — noise causes failures not usage
Maybe heavily used devices are older/degraded — age causes failures not usage
Maybe high usage devices are used in more complex operations — complexity causes failures not usage*/

