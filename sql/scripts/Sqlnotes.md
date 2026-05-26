| Task              |                                               SQLite | MySQL                                                |
| ----------------- | ---------------------------------------------------: | ---------------------------------------------------- |
| Show columns      |                           `PRAGMA table_info(table)` | `DESCRIBE table`                                     |
| Only column names |               `SELECT name FROM pragma_table_info()` | `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS` |
| Show all tables   | `SELECT name FROM sqlite_master WHERE type='table';` | `SHOW TABLES;`                                       |
