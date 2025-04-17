# 🛠️ DBT Docker Setup (Redshift + BigQuery)

This project provides a unified Docker setup for running **dbt** with support for both **Redshift** and **BigQuery** adapters. It supports:

- ✅ Dynamic adapter selection at build time (`DBT_ADAPTER`)
- ✅ Environment-specific profiles with `.env` support
- ✅ Use in both **on-prem (Docker Compose with Airflow)** and **cloud (ECS, GKE, Cloud Run)** environments
- ✅ Shared network setup for running alongside Airflow

---

## 🗂️ Project Structure

