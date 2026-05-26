| Task              |                                               SQLite | MySQL                                                |
| ----------------- | ---------------------------------------------------: | ---------------------------------------------------- |
| Show columns      |                           `PRAGMA table_info(table)` | `DESCRIBE table`                                     |
| Only column names |               `SELECT name FROM pragma_table_info()` | `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS` |
| Show all tables   | `SELECT name FROM sqlite_master WHERE type='table';` | `SHOW TABLES;`                                       |

----

**Primary keys**

| Table                      |                    Primary Key | Reason                           |
| -------------------------- | -----------------------------: | -------------------------------- |
| `Master_Session_Log`       |                   `Session_ID` | Every session should be unique   |
| `Worker_Master`            |                    `Worker_ID` | Unique worker identifier         |
| `Device_Health_Log`        |           `(Device_ID, Month)` | Same device repeats monthly      |
| `Plant_Department_Summary` | `(Plant_Location, Department)` | One department summary per plant |
| `Issue_Type_Analysis`      |                   `Issue_Type` | Unique issue category            |
| `Monthly_Trend`            |                      `(Month)` | Monthly aggregate table          |

**Foreign Keys**

Master_Session_Log

This becomes the central fact table.

Worker_ID       → Worker_Master(Worker_ID)

Device_ID       → Device_Health_Log(Device_ID)

Issue_Type      → Issue_Type_Analysis(Issue_Type)



| Table Name                 | Candidate Key(s)               | Prime Attributes             | Non-Prime Attributes                                                                                                                                                                                                                                                                                                                          |
| -------------------------- | ------------------------------ | ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Master_Session_Log`       | `Session_ID`                   | `Session_ID`                 | `Session_Date, Shift, Plant_Location, Department, Worker_ID, Device_ID, Platform, Issue_Type, Issue_Priority, Resolution_Time_min, Command_Attempts, Command_Failures, Command_Success_Rate_%, Noise_Level_dB, External_Mic_Used, Battery_Drain_%, Downtime_Saved_min, Issue_Resolved, Productivity_Score, Session_Status, Incident_Reported` |
| `Worker_Master`            | `Worker_ID`                    | `Worker_ID`                  | `Experience_Level, Training_Hours_Received, Overall_Satisfaction_1to5, Preferred_Platform, Worker_Role, Department`                                                                                                                                                                                                                           |
| `Device_Health_Log`        | `(Device_ID, Month)`           | `Device_ID, Month`           | `Total_Usage_Hours, Overheating_Events, Mic_Failure_Events, Connectivity_Drops, Device_Health_Score, Health_Category, Battery_Health`                                                                                                                                                                                                         |
| `Plant_Department_Summary` | `(Plant_Location, Department)` | `Plant_Location, Department` | `Session_Count, Average_Productivity, Incident_Count, Resolution_Rate`                                                                                                                                                                                                                                                                        |
| `Issue_Type_Analysis`      | `Issue_Type`                   | `Issue_Type`                 | `Issue_Frequency, Resolution_Time, Severity`                                                                                                                                                                                                                                                                                                  |
| `Monthly_Trend`            | `Month`                        | `Month`                      | `Avg_Productivity, Total_Sessions, Incident_Count, Downtime, Failure_Rate`                                                                                                                                                                                                                                                                    |

1.First Normal Form (1NF)

All tables satisfy First Normal Form. Each attribute contains atomic values and no table contains multivalued attributes or repeating groups. Every cell stores a single value, ensuring data consistency and integrity.

2.Second Normal Form (2NF)

All tables satisfy Second Normal Form as they are already in 1NF. In every table, non-prime attributes are fully functionally dependent on the complete candidate key and no partial dependency exists.

3.Third Normal Form (3NF)

All tables satisfy Third Normal Form as there are no transitive dependencies. Non-prime attributes do not determine other non-prime attributes, ensuring that all attributes depend only on the key.

Summary

The database schema for the RealWear Industrial Operations Analytics System has been normalized up to Third Normal Form (3NF). This reduces redundancy, improves data consistency, minimizes update anomalies, and creates an efficient structure for SQL analysis, dashboard creation, and machine learning workflows.
