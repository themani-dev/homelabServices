<img src="https://www.kindpng.com/picc/m/401-4019608_air-flow-png-apache-airflow-logo-png-transparent.png" width="1000" height="150">

# Apache Airflow Installation Guide (Airflow, PostgreSQL, and Wrapper Script)


This repository contains a Docker Compose configuration and wrapper script for setting up an Airflow environment with PostgreSQL. It provides all necessary configurations to run Airflow, including automatic dependency installation, database initialization, and user creation. The environment is optimized for orchestration of data pipelines and workflows.

## 📦 Services Overview


### **1. PostgreSQL**

- 🗄️ Stores Airflow metadata and DAG run history.
- 🔧 Service Name: `postgres`
- 💾 Persistent storage enabled via Docker volumes.

### **2. Airflow Webserver**

- 🌐 Web UI for DAG management and monitoring.

- 🔗 Accessible via: http://localhost:8080

- ⚙️ Depends on airflow-init and postgres

### **3. Airflow Scheduler**

- ⏰ Monitors DAGs and triggers tasks.

### **4. Airflow Triggerer**

- 🧠 Required for deferrable operators.

### **5. Airflow Init**

- 🛠️ Initializes Airflow database and creates admin user.

- 📂 Sets folder permissions.

### **6. Airflow CLI**

- 🐚 For debugging and administrative operations.

---
## 🚀 Step-by-Step Deployment Guide

### Prerequisites

Ensure you have the following tools installed:
- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/)
- A terminal with Docker access

### **1. Clone the Repository**

```bash
git clone https://github.com/themani-dev/homelabServices.git
cd homelabServices/Airflow
```
### **2. Setup Environment Variables**
Create a `.env` file with the following:

```shell
AIRFLOW_IMAGE_NAME=apache/airflow:2.9.3
AIRFLOW__CORE__EXECUTOR=LocalExecutor
AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres/airflow
AIRFLOW__CORE__FERNET_KEY=<your_fernet_key>
AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=True
AIRFLOW__CORE__LOAD_EXAMPLES=False
AIRFLOW__API__AUTH_BACKENDS=airflow.api.auth.backend.basic_auth
AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK=True

AIRFLOW__SMTP__SMTP_HOST=smtp.gmail.com
AIRFLOW__SMTP__SMTP_PORT=587
AIRFLOW__SMTP__SMTP_USER=you@example.com
AIRFLOW__SMTP__SMTP_PASSWORD=yourpassword
AIRFLOW__SMTP__SMTP_MAIL_FROM=airflow@example.com
AIRFLOW__SMTP__SMTP_STARTTLS=True
AIRFLOW__SMTP__SMTP_SSL=False

_AIRFLOW_WWW_USER_USERNAME=admin
_AIRFLOW_WWW_USER_PASSWORD=admin
```

> Replace values accordingly. Generate FERNET_KEY using python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

### **3. Build and Start the Containers**

```bash
docker-compose up -d
```
This will :
- Pull the necessary Docker images (if not already cached).
- Start all services in detached mode (-d flag).

### **4. Access the Airflow Web UI**

Once the services are up, you can access the Airflow web interface at http://localhost:8080. The default login credentials are:

- username : `admin`
- password : `admin`
 ---
## 🧩 Adding Dependencies and Permissions

### 1. Adding Python Dependencies
- Add packages to `requirements.txt`.

- They are auto-installed via `entrypoint.sh` on startup.

### 2. Setting Permissions

Ensure write permissions for key folders:

```shell
chmod +x entrypoint.sh
chmod -R 777 ./logs ./dags ./plugins
```

The script will also run:
```shell
chown -R ${AIRFLOW_UID}:0 /sources/{logs,dags,plugins}
```
---

## 🛑 Stop and Remove Containers

### To stop services:

```shell
docker-compose down
```

### To stop and remove volumes (including DB):
```shell
docker-compose down -v
```
---

## **🤝 Contribution**
Feel free to contribute by opening issues or submitting pull requests. Contributions to improve functionality or documentation are welcome!

---
## 📜 License

This project is licensed under the MIT License – see the LICENSE file for details.

