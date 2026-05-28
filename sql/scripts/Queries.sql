/* To See all the table has been present or not*/
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

--PLANT ANALYSIS


--Q1.Write a complete plant performance scorecard with all metrics in one query

WITH Plant_Summary as(
    SELECT 
        Plant_Location,
        Count(*) as Total_Sessions,
        Round(sum(Downtime_Saved_min)/60, 2) as Total_Downtime_Saved_Hours,
        Round(avg(Productivity_Score), 2) as Avg_Productivity_Score,
        Round(avg(Resolution_Time_min), 2)as Avg_Resolution_Time,
        Round(Count(CASE WHEN Issue_Resolved = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 2) as Resolution_Rate_Pct,
        ROUND(COUNT(CASE WHEN Session_Status = 'Dropped' THEN 1 END) * 100.0 / COUNT(*), 2) as Drop_Rate_Pct,
        COUNT(CASE WHEN Incident_Reported = 'Yes' THEN 1 END) as Total_Incidents
    From Master_Session_Log
    Group by Plant_Location
)
SELECT 
    *,
    Round(PERCENT_RANK() OVER (ORDER BY Avg_Productivity_Score), 4) as Productivity_Percentile,
    RANK() OVER (ORDER BY Avg_Productivity_Score desc) as Productivity_Rank
FROM Plant_Summary
ORDER BY Productivity_Rank;

--Identify which plants are above and below overall average productivity with the gap amount

with plant_wise AS(
    select Plant_Location,
    Round(Avg(Productivity_Score),2) as avg_productivity_per_plant
    from Master_Session_Log
    group by Plant_Location
),
overall AS(
    select Round(avg(Productivity_Score),2) as overall_productivity
    from Master_Session_Log
)
Select p.Plant_Location,p.avg_productivity_per_plant,o.overall_productivity,Round(p.avg_productivity_per_plant-o.overall_productivity,2) as gap,
case when p.avg_productivity_per_plant>o.overall_productivity then 'Above'
when p.avg_productivity_per_plant<o.overall_productivity then 'below'
else 'same' 
end as information
from plant_wise p,overall o;

-- ============================================
-- Q: Find best performing department within each plant
-- ============================================

-- METRIC SELECTION DISCUSSION:
-- We considered multiple metrics: Productivity_Score, Resolution_Time_min,
-- Command_Success_Rate, Issue_Resolved, Downtime_Saved_min, Command_Failures
-- Final decision: Combine Productivity_Score + Downtime_Saved_min

-- WHY AVG DOWNTIME SAVED OVER SUM:
-- SUM(Downtime_Saved_min) is a volume metric — departments with more sessions
-- will naturally save more downtime regardless of efficiency
-- AVG(Downtime_Saved_min) measures efficiency per session — fairer comparison
-- Example: Dept A (500 sessions, 5000 mins saved) vs Dept B (100 sessions, 2000 mins saved)
-- SUM makes Dept A look better only because of volume not performance
-- AVG gives true per-session efficiency

-- WHY NORMALIZATION IS NEEDED:
-- Productivity_Score is on 0-100 scale
-- Avg_Downtime_Saved is in minutes (different scale)
-- Direct addition is meaningless — one metric dominates unfairly
-- Solution: MIN-MAX Normalization brings both to 0-100 scale
-- Formula: (Value - MIN) / (MAX - MIN) * 100

-- WHY 60/40 WEIGHTS:
-- Productivity_Score → 60% weight (primary metric — direct measure of worker output)
-- Avg_Downtime_Saved → 40% weight (supporting metric — measures operational efficiency)
-- In industrial settings productivity is the core KPI
-- Downtime saved is important but secondary to overall productivity

-- FINAL PERFORMANCE SCORE FORMULA:
-- Performance_Score = (Normalized_Productivity * 0.6) + (Normalized_Downtime * 0.4)
-- Higher score = better performing department within each plant
-- RANK() OVER (PARTITION BY Plant_Location) ranks departments within each plant

with plant_department as(
    select Plant_Location,department,
    avg(productivity_score) as avg_productivity,
    -- Normalize only Downtime_Saved_min
(AVG(Downtime_Saved_min) - MIN(AVG(Downtime_Saved_min)) OVER())/
(MAX(AVG(Downtime_Saved_min)) OVER() - MIN(AVG(Downtime_Saved_min)) OVER()) * 100 as normalised_downtime
    from Master_Session_Log
    group by Department,Plant_Location
),
Performance as(
    select *,(avg_productivity*0.6+normalised_downtime*0.4) as performance_score
    from plant_department
),
Ranked as(
    select *,
    Rank()over(Partition by Plant_Location order by performance_score desc) as rn
    from performance
)
select * 
from ranked
where rn=1;


-- ==============
--WORKER ANALYSIS
--===============

/*Rank workers within each plant using PARTITION BY and 
identify top performer per plant with all key metrics.*/

with Worker_details as(
    select Plant_Location,
    Worker_ID,
    round(avg(Productivity_Score),2) as avg_productivity,
    round(avg(Downtime_Saved_min),2) as avg_downtime_saved,
    round(count(case when Issue_Resolved='Yes' then 1 end)*100.0/count(*),2)  as resolution_rate,
    avg(Resolution_Time_min) as Avg_Resolution_Time
    from Master_Session_Log
    group by worker_id,Plant_Location

),
Ranked as(
    select *,
    Rank()over(Partition by Plant_Location order by avg_productivity desc,resolution_rate desc,avg_resolution_time) as rn   
    from worker_details
)
select * from Ranked where rn=1;


--Find workers who are below their plant average productivity and classify them as needs improvement

with workers_productivity as(
    select Plant_Location,worker_id,
    round(avg(Productivity_Score),2) as Avg_Productivity
    from Master_Session_Log
    group by worker_id,Plant_Location
),
Plant_avg as(
    select Plant_Location,
    round(avg(productivity_score),2) as avg_plant_productivity
    from Master_Session_Log
    group by Plant_Location
)
select w.Plant_Location,w.worker_id,w.avg_productivity,
p.avg_plant_productivity
from workers_productivity w,Plant_avg p    
where w.avg_productivity<p.avg_plant_productivity;


--Find which worker role performs best across all metrics using combined performance score

select Worker_Role,
round(avg(Avg_Productivity_Score),2) as avg_productivity_worker_role,
round(avg(Overall_Satisfaction_1to5),2) as avg_satisfaction_rate
from Worker_Master
group by Worker_Role
order by avg_productivity_worker_role desc;

/*The averaging problem

Imagine two groups of Floor Operators:
Group A: 10 workers all rate satisfaction = 3 → Average = 3.0
Group B: 5 workers rate 1, 5 workers rate 5 → Average = 3.0

Both give the same average — but they are completely different situations. 
Group A is uniformly neutral. Group B is polarised — half love the device, half hate it. 
A simple AVG hides this split entirely and gives you a fake picture of "moderate satisfaction."
so we have to think for the bimodal analysis*/

--Query 1 — Distribution breakdown per worker role
--WHAT THIS SHOWS: Exact count of workers at each satisfaction score (1–5) per role

select worker_role,
count(*) as total_roles,
count(case when Overall_Satisfaction_1to5=1 then 1 end)as score_1,
count(case when Overall_Satisfaction_1to5=2 then 1 end)as score_2,
count(case when Overall_Satisfaction_1to5=3 then 1 end)as score_3,
count(case when Overall_Satisfaction_1to5=4 then 1 end)as score_4,
count(case when Overall_Satisfaction_1to5=5 then 1 end)as score_5,

round(count(case when Overall_Satisfaction_1to5=1 then 1 else 0 end)*100.0/count(*),1) as pct_score_1,
round(count(case when Overall_Satisfaction_1to5=5 then 1 else 0 end)*100.0/count(*),1) as pct_score_5,

 -- still include avg for reference — but don't rely on it alone
    round(avg(Overall_Satisfaction_1to5), 2) AS Avg_Satisfaction
from Worker_Master
group by Worker_Role
order by avg_satisfaction desc;

SELECT
    Worker_Role,
    COUNT(*) AS Total_Roles,

    -- score distribution counts
    SUM(CASE WHEN Overall_Satisfaction_1to5 = 1 THEN 1 ELSE 0 END) AS Score_1,
    SUM(CASE WHEN Overall_Satisfaction_1to5 = 2 THEN 1 ELSE 0 END) AS Score_2,
    SUM(CASE WHEN Overall_Satisfaction_1to5 = 3 THEN 1 ELSE 0 END) AS Score_3,
    SUM(CASE WHEN Overall_Satisfaction_1to5 = 4 THEN 1 ELSE 0 END) AS Score_4,
    SUM(CASE WHEN Overall_Satisfaction_1to5 = 5 THEN 1 ELSE 0 END) AS Score_5,

    -- percentage at each score
    ROUND(SUM(CASE WHEN Overall_Satisfaction_1to5 = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Pct_Score_1,
    ROUND(SUM(CASE WHEN Overall_Satisfaction_1to5 = 5 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Pct_Score_5,

    -- still include avg for reference — but don't rely on it alone
    ROUND(AVG(Overall_Satisfaction_1to5), 2) AS Avg_Satisfaction

FROM Worker_Master
GROUP BY Worker_Role
ORDER BY Avg_Satisfaction DESC;

select Worker_Role,
count(*) as total_roles,
round(avg(Overall_Satisfaction_1to5)) as avg_satisfaction,

--unhappy workers(score 1-2)
round(count(case when Overall_Satisfaction_1to5<=2 then 1 end)*100.0/count(*),2) as pct_unhappy,

--neutral workers(score 3)
round(count(case when Overall_Satisfaction_1to5=3 then 1 end)*100.0/count(*),2) as pct_neutral,

--happy workers(score >=4)
round(count(case when Overall_Satisfaction_1to5>=4 then 1 end)*100.0/count(*),2) as pct_happy,

Round(count(case when Overall_Satisfaction_1to5<=2 then 1 end)*100.0/count(*)*
count(case when Overall_Satisfaction_1to5>=4 then 1 end)*100.0/count(*)/100,1) as polarisation_score
from Worker_Master
group by Worker_Role
order by polarisation_score desc;
    