library(dplyr)
library(forecast)
library(here)

# Load + Prepare Data
# ------------------------
fraud_data <- read.csv(here("data", "processed", "aggregated_fraud_daily.csv"))

fraud_data$Date <- as.Date(
  fraud_data$Date.Received...Date.recue,
  format = "%Y-%m-%d"
)


# Forecast Table Function
# -----------------------------------------------------------------
forecast_table <- function(fc, fraud_type, metric, start_date) {
  
  future_dates <- seq(
    from       = start_date + 1,
    by         = "day",
    length.out = length(fc$mean)
  )
  
  lower <- matrix(as.numeric(fc$lower), ncol = ncol(fc$lower))
  upper <- matrix(as.numeric(fc$upper), ncol = ncol(fc$upper))
  
  if (ncol(lower) == 1) lower <- cbind(lower, NA)
  if (ncol(upper) == 1) upper <- cbind(upper, NA)
  
  data.frame(
    Date        = future_dates,
    Fraud_Type  = fraud_type,
    Metric      = metric,
    Forecast    = as.numeric(fc$mean),
    Lower_80    = lower[, 1],
    Upper_80    = upper[, 1],
    Lower_95    = lower[, 2],
    Upper_95    = upper[, 2]
  )
}


# Aggregate Daily Data
# -------------------------------------------------------
fraud_daily <- fraud_data %>%
  group_by(Date, Fraud_type) %>%
  summarise(
    total_victims = sum(total_victims, na.rm = TRUE),
    total_loss    = sum(total_loss, na.rm = TRUE),
    .groups = "drop"
  )

# Total aggregation
fraud_all_daily <- fraud_daily %>%
  group_by(Date) %>%
  summarise(
    total_victims = sum(total_victims),
    total_loss    = sum(total_loss),
    .groups = "drop"
  ) %>%
  arrange(Date)

last_date <- max(fraud_all_daily$Date)


# TOP 5 Fraud Types (based on 2024 onwards)
# -------------------------------------------------------
top5_names <- fraud_daily %>%
  filter(Date >= as.Date("2024-01-01")) %>%
  count(Fraud_type, sort = TRUE) %>%
  slice_head(n = 5) %>%
  pull(Fraud_type)

fraud_top5 <- fraud_daily %>%
  filter(Fraud_type %in% top5_names)

top5_list <- split(fraud_top5, fraud_top5$Fraud_type)


# 1. Total Victims Model (ARIMA)
# -------------------------------------------------------------
ts_total <- ts(fraud_all_daily$total_victims, frequency = 7)

fit_total <- auto.arima(ts_total, seasonal = TRUE)

fc_total <- forecast(fit_total, h = 240)

all_fraud_fc <- forecast_table(
  fc_total,
  fraud_type = "Total",
  metric = "Victim_Count",
  start_date = last_date
)


# 2. Total Monetary Loss Model (TBATS)
# -----------------------------------------------------------------
ts_loss <- msts(fraud_all_daily$total_loss, seasonal.periods = 7)

fit_loss <- tbats(ts_loss)

fc_loss <- forecast(fit_loss, h = 240)

all_loss_fc <- forecast_table(
  fc_loss,
  fraud_type = "Total",
  metric = "Monetary_Loss",
  start_date = last_date
)

# 3. TOP 5 Fraud types - Fraud Report Count (ARIMA)
# ------------------------------------------------------------
fc_top5_victims <- lapply(names(top5_list), function(ft) {
  
  df <- top5_list[[ft]] %>% arrange(Date)
  
  ts_data <- ts(df$total_victims, frequency = 7)
  
  fit <- auto.arima(ts_data)
  fc  <- forecast(fit, h = 240)
  
  forecast_table(fc, ft, "Victim_Count", max(df$Date))
})

all_forecasts <- do.call(rbind, fc_top5_victims)


# 4. TOP 5 Fraud Types - Monetary Loss (TBATS)
# -------------------------------------------------------
fc_top5_loss <- lapply(names(top5_list), function(ft) {
  
  df <- top5_list[[ft]] %>% arrange(Date)
  
  ts_data <- msts(df$total_loss, seasonal.periods = 7)
  
  fit <- tbats(ts_data)
  fc  <- forecast(fit, h = 240)
  
  forecast_table(fc, ft, "Monetary_Loss", max(df$Date))
})

all_forecasts_loss <- do.call(rbind, fc_top5_loss)


# Combine Forecast Data/Tables and Exporting
# -------------------------------------------------------
combined <- bind_rows(
  all_fraud_fc,
  all_forecasts,
  all_loss_fc,
  all_forecasts_loss
)

write.csv(
  combined,
  here("output", "combined_forecasts.csv"),
  row.names = FALSE
)