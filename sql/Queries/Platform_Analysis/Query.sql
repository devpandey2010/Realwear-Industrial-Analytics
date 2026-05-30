/*Compare MS Teams vs Webex performance in HIGH noise environments specifically*/
SELECT 
    Platform,
    COUNT(*) AS Total_Sessions,
    ROUND(AVG(Noise_Level_dB), 2) AS Avg_Noise_Level,
    ROUND(AVG(Productivity_Score), 2) AS Avg_Productivity,
    ROUND(AVG(Command_Failures), 2) AS Avg_Command_Failures,
    ROUND(AVG(Resolution_Time_min), 2) AS Avg_Resolution_Time,
    ROUND(COUNT(CASE WHEN Issue_Resolved = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS Resolution_Rate_Pct,
    ROUND(COUNT(CASE WHEN Session_Status = 'Dropped' THEN 1 END) * 100.0 / COUNT(*), 2) AS Drop_Rate_Pct
FROM Master_Session_Log
WHERE Noise_Level_dB > 85
GROUP BY Platform
ORDER BY Avg_Productivity DESC;

--Find which platform performs better for each plant using PARTITION BY
with details as(
    select plant_location,platform,
    count(*)as Total_sessions,
    round(avg(productivity_score),2) as avg_productivity,
    round(avg(command_failures),2) as avg_command_failures,
    round(avg(resolution_time_min),2)as avg_resolution_time
    from Master_Session_Log
    group by platform,plant_location
),
Ranked as(
select *,
Rank()over(partition by plant_location order by avg_productivity desc) as rn   
from details 
)
select * from Ranked;

--Identify which platform resolves which issue types faster

with details as(
select platform, Issue_Type,
avg(Resolution_Time_min) as avg_resolution_time
from Master_Session_Log
group by platform,Issue_Type
)
select *,
rank()over(partition by Issue_Type order by avg_resolution_time) as rn  
from details
order by issue_type,rn;
