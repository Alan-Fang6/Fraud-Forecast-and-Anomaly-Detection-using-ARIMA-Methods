import pandas as pd
import glob
import os

#Locating csv file
raw_data_path = "data/raw/*.csv"
file = glob.glob(raw_data_path)
#If no files are found
if not file:
    raise FileNotFoundError("No CSV file found in data/raw/")

# Otherwise use the first file found
file_path = file[0]
print(f"Reading file: {file_path}")

CRFC = pd.read_csv(file_path)

CRFC = pd.read_csv(file_path
)
# Convert date
CRFC["Date Received / Date reçue"] = pd.to_datetime(
    CRFC["Date Received / Date reçue"]
)

#Cleaning dataset column names as they are messy and the french name is not needed
CRFC.columns = CRFC.columns.str.strip()

CRFC = CRFC.rename(columns={
    "Province/State": "Province",
    "Fraud and Cybercrime Thematic Categories": "FraudType",
    "Solicitation Method": "SolicitationMethod",
    "Gender": "Gender",
    "Victim Age Range / Tranche d'âge des victimes": "AgeGroup",
    "Number of Victims / Nombre de victimes": "Victims",
    "Dollar Loss /pertes financières": "Monetary_Loss",
    "Numéro d'identification / Number ID": "ReportID",
    "Complaint Type": "ComplaintType"
})
# Monetary Loss
CRFC['Monetary_Loss'] = (
    CRFC['Monetary_Loss']
    .replace('[\$,]', '', regex=True)
    .astype(float)
)

# Keeping only actual victims
CRFC = CRFC[CRFC['ComplaintType'] == 'Victim']

#Aggregating data now
daily_summary = (
    CRFC
    .groupby([
        "Date Received / Date reçue",
        "Province",
        "FraudType",
        "SolicitationMethod",
        "Gender",
        "AgeGroup"
    ])
    .agg(
        total_victims=("Victims", "sum"),
        total_loss=("Monetary_Loss", "sum"),
        total_reports=("ReportID", "count")
    )
    .reset_index()
)

daily_summary.to_csv(
    "data/processed/aggregated_fraud_daily.csv",
    index=False
)

