# KPI Master List
**Project:** RealWear Industrial Operations Analytics & Smart Factory Intelligence System  
**Data Range:** January 2025 – January 2026  
**Total Sessions:** 12,000 | **Plants:** 5 | **Devices:** 20


## 1. Operational KPIs

| KPI | Definition | Source Sheet | How to Measure |
|-----|-----------|--------------|----------------|
| Total Sessions | Total number of remote assistance sessions recorded | Master_Session_Log | COUNT(Session_ID) |
| Session Completion Rate | % of sessions with status = "Completed" | Master_Session_Log | COUNT(Completed) / COUNT(Total) × 100 |
| Session Drop Rate | % of sessions with status = "Dropped" | Master_Session_Log | COUNT(Dropped) / COUNT(Total) × 100 |
| Average Meeting Duration | Average length of a session in minutes | Master_Session_Log | AVERAGE(Meeting_Duration_min) |
| Issue Resolution Rate | % of sessions where issue was resolved | Master_Session_Log | COUNT(Issue_Resolved=Yes) / COUNT(Total) × 100 |
| Average Resolution Time | Average time taken to resolve an issue | Master_Session_Log | AVERAGE(Resolution_Time_min) |
| Downtime Saved (Total) | Total downtime saved across all sessions in minutes | Master_Session_Log | SUM(Downtime_Saved_min) |
| Incident Report Rate | % of sessions where an incident was reported | Master_Session_Log | COUNT(Incident_Reported=Yes) / COUNT(Total) × 100 |

---

## 2. Voice Command & Device KPIs

| KPI | Definition | Source Sheet | How to Measure |
|-----|-----------|--------------|----------------|
| Average Command Success Rate | Average % of voice commands that succeeded per session | Master_Session_Log | AVERAGE(Command_Success_Rate_%) |
| Total Command Failures | Total number of failed voice commands across all sessions | Master_Session_Log | SUM(Command_Failures) |
| Average Command Failures per Session | Average failed commands per session | Master_Session_Log | SUM(Command_Failures) / COUNT(Sessions) |
| Average Noise Level | Average ambient noise level across all sessions in dB | Master_Session_Log | AVERAGE(Noise_Level_dB) |
| External Mic Usage Rate | % of sessions where external microphone was used | Master_Session_Log | COUNT(External_Mic_Used=Yes) / COUNT(Total) × 100 |
| Average Battery Drain per Session | Average % battery consumed per session | Master_Session_Log | AVERAGE(Battery_Drain_%) |

---

## 3. Device Health KPIs

| KPI | Definition | Source Sheet | How to Measure |
|-----|-----------|--------------|----------------|
| Average Device Health Score | Average health score across all devices | Device_Health_Log | AVERAGE(Health_Score) |
| Devices Below Health Threshold | Count of devices with health score < 50 | Device_Health_Log | COUNT where Health_Score < 50 |
| Average Device Uptime | Average operational uptime per device | Device_Health_Log | AVERAGE(Uptime_hours) |
| Device Failure Count | Total number of logged device failures | Device_Health_Log | COUNT(Failure_Events) |

---

## 4. Worker Productivity KPIs

| KPI | Definition | Source Sheet | How to Measure |
|-----|-----------|--------------|----------------|
| Average Productivity Score | Average productivity score across all workers | Master_Session_Log | AVERAGE(Productivity_Score) |
| Top 10% Performers | Workers in the top 10% by productivity score | Worker_Master | RANK / PERCENTILE on Productivity_Score |
| Bottom 10% Performers | Workers needing support — bottom 10% productivity | Worker_Master | RANK / PERCENTILE on Productivity_Score |
| Average Sessions per Worker | How many sessions each worker handles on average | Master_Session_Log | COUNT(Sessions) / COUNT(Unique Workers) |

---

## 5. Platform Performance KPIs

| KPI | Definition | Source Sheet | How to Measure |
|-----|-----------|--------------|----------------|
| MS Teams Session Count | Total sessions using MS Teams | Master_Session_Log | COUNT where Platform = "MS Teams" |
| Webex Session Count | Total sessions using Webex | Master_Session_Log | COUNT where Platform = "Webex" |
| MS Teams Avg Resolution Time | Average resolution time for Teams sessions | Master_Session_Log | AVERAGE(Resolution_Time_min) where Platform = "MS Teams" |
| Webex Avg Resolution Time | Average resolution time for Webex sessions | Master_Session_Log | AVERAGE(Resolution_Time_min) where Platform = "Webex" |
| MS Teams Command Success Rate | Avg command success rate for Teams sessions | Master_Session_Log | AVERAGE(Command_Success_Rate_%) where Platform = "MS Teams" |
| Webex Command Success Rate | Avg command success rate for Webex sessions | Master_Session_Log | AVERAGE(Command_Success_Rate_%) where Platform = "Webex" |

---

## 6. Plant & Department KPIs

| KPI | Definition | Source Sheet | How to Measure |
|-----|-----------|--------------|----------------|
| Plant-wise Productivity Score | Average productivity score per plant | Plant_Department_Summary | AVERAGE(Productivity_Score) GROUP BY Plant |
| Plant-wise Issue Resolution Rate | % of issues resolved per plant | Plant_Department_Summary | COUNT(Resolved) / COUNT(Total) per Plant |
| Department-wise Failure Rate | Command failure rate by department | Master_Session_Log | AVG(Command_Failures) GROUP BY Department |
| Shift-wise Productivity | Average productivity per shift type | Master_Session_Log | AVERAGE(Productivity_Score) GROUP BY Shift |

---

## 7. Time-Series KPIs

| KPI | Definition | Source Sheet | How to Measure |
|-----|-----------|--------------|----------------|
| Monthly Session Volume | Number of sessions per month | Monthly_Trend | COUNT(Session_ID) GROUP BY Month |
| Monthly Avg Productivity | Average productivity score per month | Monthly_Trend | AVERAGE(Productivity_Score) GROUP BY Month |
| Monthly Failure Trend | Average command failures per month | Monthly_Trend | AVERAGE(Command_Failures) GROUP BY Month |
| Monthly Downtime Saved | Total downtime saved per month | Monthly_Trend | SUM(Downtime_Saved_min) GROUP BY Month |