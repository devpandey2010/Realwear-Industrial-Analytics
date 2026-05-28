* To See all the table has been present or not*/
select name 
from sqlite_master
where type='table';

/* To see all the column names present in the table*/
SELECT name
FROM pragma_table_info('Device_Health_Log');

/*Write a single query that returns complete KPI summary — 
total sessions, workers, devices, avg productivity, total downtime saved, 
resolution rate, completion rate and drop rate*/

-- 1. COMPREHENSIVE KPI DASHBOARD QUERY
-- ============================================
-- Q1: Complete KPI Summary in one query
SELECT 
    count(*) AS Total_Sessions,
    count(DISTINCT Worker_ID) AS Total_Workers,
    count(DISTINCT Device_ID) AS Total_Devices,
    count(DISTINCT Plant_Location) AS Total_Plants,
    Round(AVG(Productivity_Score), 2) AS Avg_Productivity,
    Round(sum(Downtime_Saved_min)/60, 2) AS Total_Downtime_Saved_Hours,
    Round(Count(CASE WHEN Issue_Resolved = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) AS Resolution_Rate_Pct,
    Round(count(CASE WHEN Session_Status = 'Completed' THEN 1 END) * 100.0 / COUNT(*), 2) AS Completion_Rate_Pct,
    Round(count(CASE WHEN Session_Status = 'Dropped' THEN 1 END) * 100.0 / COUNT(*), 2) AS Drop_Rate_Pct
FROM Master_Session_Log;

--Q2.Find what % of sessions had both issue resolved AND incident reported simultaneously
select 
Round(count(case when Issue_Resolved='Yes'and Incident_Reported='Yes' then 1 End)*100.0/count(*),2) as session_with_resolved_issue_and_incident
from Master_Session_Log;

--Q3.Find the most common combination of Platform + Connection_Type + Shift that leads to highest productivity

select Platform,Connection_Type,Shift,
avg(Productivity_Score) as Avg_Productivity_Score
from Master_Session_Log
group by platform,Connection_Type,Shift
order by Avg_productivity_score desc
limit 5;
