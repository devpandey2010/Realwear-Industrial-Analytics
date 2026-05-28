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