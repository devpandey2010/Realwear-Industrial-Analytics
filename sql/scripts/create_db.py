import pandas as pd
import sqlite3
import os

# Delete old database if exists
db_path='../database/realwear.db'

if os.path.exists(db_path):
    os.remove(db_path)
    print("Old database deleted")

# Create fresh database
conn=sqlite3.connect(db_path)

sheets={
    'Master_Session_Log':'Master_Session_Log',
    'Worker_Master':'Worker_Master',
    'Device_Health_Log':'Device_Health_Log',
    'Plant_Department_Summary':'Plant_Department_Summary',
    'Issue_Type_Analysis':'Issue_Type_Analysis',
    'Monthly_Trend':'Monthly_Trend',
    'Data_Dictionary':'Data_Dictionary'
}

excel_file=r'C:\Users\BIT\OneDrive\Desktop\REAL WEAR PROJECT\data\RealWear_Master_Industrial_Dataset.xlsx'

for sheet_name,table_name in sheets.items():

    # Use second row as actual header
    df=pd.read_excel(
        excel_file,
        sheet_name=sheet_name,
        header=2
    )

    df.to_sql(
        table_name,
        conn,
        if_exists='replace',
        index=False
    )

    print(f'{table_name} loaded successfully - {len(df)} rows')

conn.close()

print("\nAll tables loaded successfully")