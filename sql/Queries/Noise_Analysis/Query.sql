Alter table Master_Session_Log
Rename column "Command_Success_Rate_%" to Command_Success_Rate;
--Find the exact noise threshold where command failures spike significantly using NTILE
with details as(
select noise_level_db,avg(command_failures) as avg_command_failure,
count(*) as total_sessions
from Master_Session_Log
group by Noise_Level_dB
),
Grouping as(
select *,
ntile(4)over(order by Noise_Level_dB) as pctile,
case when ntile(4)over(order by Noise_Level_dB)=1  then 'Low noise'
when ntile(4)over(order by Noise_Level_dB)=2 then 'medium noise'
when ntile(4)over(order by Noise_Level_dB)=3 then 'High noise'
else 'Very high noise'
end as classification
from details
),
Summary AS (
    SELECT 
        Classification,
        ROUND(MIN(Noise_Level_dB), 2) AS Min_Noise,
        ROUND(MAX(Noise_Level_dB), 2) AS Max_Noise,
        ROUND(AVG(Avg_Command_Failure), 2) AS Avg_Failures,
        SUM(Total_Sessions) AS Total_Sessions
    FROM Grouping
    GROUP BY Classification
)
SELECT *,
    ROUND(Avg_Failures - LAG(Avg_Failures) OVER (ORDER BY Min_Noise), 2) AS Spike_From_Previous
FROM Summary
ORDER BY Min_Noise;

--By this we get a thrushhold if noise_level_db>81.5 then we are in high_noise_zone

--Which combination of noise category + platform gives best command success rate

 with Grouping as(
select platform,command_success_rate,
ntile(4)over(order by Noise_Level_dB) as pctile,
case when ntile(4)over(order by Noise_Level_dB)=1  then 'Low noise'
when ntile(4)over(order by Noise_Level_dB)=2 then 'medium noise'
when ntile(4)over(order by Noise_Level_dB)=3 then 'High noise'
else 'Very high noise'
end as classification
from Master_Session_Log
)
select Platform,classification,round(avg(Command_Success_Rate),2) as avg_command_success_rate,
Rank()over(order by avg(command_success_rate)desc) as overall_rank
from grouping
group by platform,classification
order by overall_rank;


Identify which plants have highest noise levels and its impact on productivity