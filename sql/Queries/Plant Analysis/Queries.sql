-Q1.Write a complete plant performance scorecard with all metrics in one query

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
