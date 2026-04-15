# Fraud-Forecast-and-Anomaly-Detection-using-ARIMA-Methods
Analysis of ARIMA and TBATS models in forecasting reported fraud and monetary loss respectively in Canada. ARIMA model 95% forecast interval effectiveness was also tested as an anomaly detection tool over cumulative window periods.

Please download raw dataset from this URL and place in data/raw: 
https://open.canada.ca/data/en/dataset/6a09c998-cddb-4a22-beff-4dca67ab892f/resource/43c67af5-e598-4a9b-a484-fe1cb5d775b5

Python Script under /scripts/ was utilised for aggregation and cleaning of data. 
pre-cleaned and aggregated data is available under /data/processed

# How to Run
1. Clone the repository
2. Open the R Project
3. Run scripts/aggregate_data.py (data already run through this Python script is available in data/processed)
4. Run individual code chunks as needed in analysis/Fraud_RCode.RMD
5. Csv file outputs for F1/Recall/Precision versus forecast horizon, as well as model forecasts, will be written to /output
# Data

