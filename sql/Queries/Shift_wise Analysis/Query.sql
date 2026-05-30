SELECT name
FROM pragma_table_info('Master_session_log');

--Complete shift performance scorecard with all metrics and rank
select shift,count(*) as total_session_per_shift,
round(avg(productivity_score),2) as avg_productivity,
round(avg(command_failures),2) as avg_command_failures,
round(sum(downtime_saved_min)/60,2) as total_downtime_saved_per_shift_in_hour,
count(case when Issue_Resolved='Yes' then 1 end)as Total_issue_resolved,
count(case when incident_reported='Yes' then 1 end)as Total_incident_reported,
round(avg(resolution_time_min),2) as avg_resolution_time_per_shift
from master_session_log 
group by shift
order by avg_productivity desc;

--Find which shift has most dropped sessions and identify pattern using issue type
with shift_drop as(
select shift,issue_type,count(*),
count(case when Session_Status='Dropped' then 1 end) as number_of_dropped_session_per_shift,
round(count(case when session_status='Dropped' then 1 end)*100.0/count(*),2) as drop_rate_pct
from Master_Session_Log
group by shift,issue_type
having count(case when Session_Status='Dropped' then 1 end)>0

)
select *,
Rank()over(partition by shift order by number_of_dropped_session_per_shift  desc) as rank_within_shift
from shift_drop
order by shift,rank_within_shift;

--Compare shift performance within each plant using PARTITION BY
 
 with details AS(
    select Plant_Location,shift,count(*) as total_session_per_shift,
round(avg(productivity_score),2) as avg_productivity,
round(avg(command_failures),2) as avg_command_failures,
round(sum(downtime_saved_min)/60,2) as total_downtime_saved_per_shift_in_hour,
count(case when Issue_Resolved='Yes' then 1 end)as Total_issue_resolved,
count(case when incident_reported='Yes' then 1 end)as Total_incident_reported,
round(avg(resolution_time_min),2) as avg_resolution_time_per_shift
from master_session_log 
group by shift,Plant_Location
 )
select *,
Rank()over(partition by plant_location order by avg_productivity desc) as rn  
from details;
