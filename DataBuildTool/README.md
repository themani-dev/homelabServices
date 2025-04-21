<p align="center">
  <img src="https://raw.githubusercontent.com/dbt-labs/dbt-core/fa1ea14ddfb1d5ae319d5141844910dd53ab2834/etc/dbt-core.svg" alt="dbt logo" width="750"/>
</p>

<h1 align="center">DBT Docker Template – BigQuery | Redshift | Snowflake | Postgres</h1>

<p align="center">
  <b>Modular, production-ready DBT project for BigQuery, Redshift, and Postgres.</b><br>
  Easily build, deploy, and run DBT models in Dockerized CI/CD pipelines across cloud and local environments.
</p>

<!-- <p align="center">
  <a href="https://github.com/themani-dev/dbt-core/actions/workflows/main.yml">
    <img src="https://github.com/themani-dev//actions/workflows/main.yml/badge.svg?event=push" alt="CI Badge"/>
  </a>
</p> -->

<p align="center">

  <a href="#quickstart-for-gcp-bigquery">
    <img src="https://img.shields.io/badge/BigQuery%20Setup-GCP-blue?style=for-the-badge&logo=googlecloud&logoColor=white" alt="BigQuery Badge"/>
  </a>
  &nbsp;
  <a href="#-quickstart-for-aws-redshift">
    <img src="https://img.shields.io/badge/Redshift%20Setup-AWS-orange?style=for-the-badge&logo=amazonaws&logoColor=white" alt="Redshift Badge"/>
  </a>
  &nbsp;
  <a href="#-quickstart-for-postgres-vmonprem">
    <img src="https://img.shields.io/badge/Postgres%20Setup-OnPrem%2FLocal-316192?style=for-the-badge&logo=postgresql&logoColor=white" alt="Postgres Badge"/>
  </a>
  &nbsp;
  <a href="#-quickstart-for-snowflake">
    <img src="https://img.shields.io/badge/Snowflake%20Setup-Cross--Cloud-00c7e6?style=for-the-badge&logo=snowflake&logoColor=white" alt="Snowflake Badge"/>
  </a>

</p>


---
## 📌 Project Status

> 🚧 **This project is currently a Work In Progress (WIP).**  
> While the structure and components are functional, some environments are still under development:

| Environment | Status           | Notes                        |
|-------------|------------------|------------------------------|
| BigQuery    | ✅ Complete       | Includes Cloud Build, wrapper, and Dockerfile |
| Redshift    | 🔧 In Progress    | Dockerfile and profile ready |
| Snowflake   | 🔧 In Progress    | Profile planned              |
| Postgres    | 🔧 In Progress    | Docker build supported       |

---

## 🎯 Project Goal

This repository is intended to deliver a **production-ready DBT Docker image** with consistent structure and flexible environment support for the following services:

- ✅ **BigQuery** – GCP-native, with Cloud Build CI/CD
- ✅ **Redshift** – AWS-native, ready for ECR/Batch
- ✅ **Snowflake** – Cross-cloud analytics support
- ✅ **Postgres** – Local or on-premise development setups

Each environment is supported through:
- ✅ Custom `profiles.yml`
- ✅ Dedicated folder under `framework/`
- ✅ Docker image build support via `--build-arg`
- ✅ Centralized orchestration via wrapper scripts
- CI/CD automation for:
  - ✅ GCP Cloud Build (`framework/bigquery/cloudbuild.yaml`)


---

## 🗂️ Project Structure

<details open>
<summary><strong>📂 Click to close full project structure</strong></summary>

```bash
.
├── 📄 Dockerfile                  # Build DBT image with chosen adapter (bigquery/redshift/postgres)
├── 📄 bigquery_wrapper.sh        # Shell script to build & push DBT image to GCP Artifact Registry
├── 📁 framework/                 # Environment-specific DBT projects
│   └── 📁 bigquery/              # DBT project using BigQuery adapter
│       ├── 📄 dbt_project.yml    # Main DBT project config
│       ├── 📄 cloudbuild.yaml    # GCP Cloud Build config for CI/CD pipeline
│       ├── 📁 models/            # DBT models organized by transformation layer
│       │   ├── 📁 raw/           # Raw layer — source tables
│       │   │   └── 📄 sources.yml
│       │   ├── 📁 curated/       # Curated layer — cleaned, transformed data
│       │   │   ├── 📄 schema.yml
│       │   │   └── 📄 tbl_curated.sql
│       │   ├── 📁 semantic/      # Semantic layer — facts/dimensions
│       │   │   ├── 📄 schema.yml
│       │   │   ├── 📄 tbl_semantic.sql
│       │   └── 📁 consumption/   # Consumption layer — final outputs for BI
│       │       └── 📄 schema.yml
│       ├── 📁 analyses/          # (Optional) Deep dive SQL analysis
│       ├── 📁 macros/            # Custom Jinja macros
│       ├── 📁 seeds/             # Seed data for static reference tables
│       ├── 📁 snapshots/         # DBT snapshots for slowly changing dimensions
│       └── 📁 tests/             # Custom DBT tests
├── 📁 profiles/                  # DBT profiles for different backends
│   ├── 📄 profiles_bigquery.yml  # BigQuery profile — update project, dataset, keyfile
│   ├── 📄 profiles_redshift.yml  # Redshift profile for AWS
│   ├── 📄 profiles_postgres.yml  # Postgres profile for on-prem/dev
│   └── 📄 profiles_snowflake.yml # (Optional) profile for Snowflake
├── 📁 serviceAccounts/
│   └── 📄 gcloud.json            # GCP service account key file (used in Dockerfile)
└── 📄 README.md                  # You're looking at it 😉
````
</details> 



---
# 🚀 Step-by-Step Deployment Guide

### Prerequisites

Ensure you have the following tools installed:
- [Docker](https://www.docker.com/get-started)
- A terminal with Docker access


## Quickstart for GCP (BigQuery)


### 1. 🔐 Update Service Account (Optional)

If you’re using **Service Account JSON**:

- Replace the contents of `serviceAccounts/gcloud.json` with your GCP service account key.
- Ensure it has permissions for **BigQuery Admin**, **Cloud Storage Viewer**, etc.

---

### 2. ⚙️ Update `profiles_bigquery.yml`

Manually update project-specific values in:
```yaml
project: "your-gcp-project"
dataset: "your_dataset"
keyfile: "/app/gcloud.json"
location: "US"
```
### 3. 🏗️ Set Up Artifact Registry

- In GCP Console → Artifact Registry → Create Docker repo
- Example: us-west2-docker.pkg.dev/your-project/dataengineering/dbt

### 4. 📜 Use the Wrapper Script to Build + Push
```bash
chmod +x bigquery_wrapper.sh
./bigquery_wrapper.sh
```
This script will:

- Build the Docker image with BigQuery adapter

- Tag it for Artifact Registry

- Push it to GCP Artifact Registery

### 5. ✅ Confirm Upload
Check in GCP Console → Artifact Registry → dbt:latest image is visible.


## 🚧 Quickstart for AWS (Redshift)
> coming soon
## 🚧 Quickstart for postgres (vm/onprem)
> coming soon
## 🚧 Quickstart for snowflake
> coming soon
---
## 📂 Profiles Support
Each profile (`profiles_<adapter>.yml`) supports multiple authentication methods and project targets. Example for BigQuery:

```yaml
keyfile: "/app/gcloud.json"
project: "your-gcp-project"
dataset: "your_dataset"
```
You can also use env_var() if you later adopt environment-based configuration.

---
## **🔧 Contributions**

Pull requests are welcome! Suggested contributions:

- AWS ECR + Batch CI/CD

- Secrets Manager integration

- MWAA-ready DAGs

---
## 📫 Maintainer
Manikanta Reddy Kallam

📧 `themanidev@gmail.com`

🌐 https://themani.dev