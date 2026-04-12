import pandas as pd

CRFC = pd.read_csv("data/raw/cafc-open-gouv-database-2021-01-01-to-2025-09-30-extracted-2025-10-01.csv")
# Convert date
CRFC['Date Received / Date recue'] = pd.to_datetime(
    CRFC['Date Received / Date recue']
)

#Cleaning dataset column names as they are messy and the french name is not needed
CRFC.columns = CRFC.columns.str.strip()

CRFC = CRFC.rename(columns={
    "Province/State": "Province",
    "Fraud and Cybercrime Thematic Categories": "FraudType",
    "Solicitation Method": "SolicitationMethod",
    "Gender": "Gender",
    "Victim Age Range / Tranche d'age des victimes": "AgeGroup",
    "Number of Victims / Nombre de victimes": "Victims",
    "Dollar Loss /pertes financieres": "Monetary_Loss",
    "Numero d'identification / Number ID": "ReportID",
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
        "Date Received / Date recue",
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

