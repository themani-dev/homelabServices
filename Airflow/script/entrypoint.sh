#!/bin/bash
set -e

if [ -e "/opt/airflow/requirements.txt" ]; then
  echo "Installing Python dependencies..."
  python -m pip install --upgrade pip
  pip install -r requirements.txt
fi

# chown -R "${AIRFLOW_UID}:0" /sources/{logs,dags,plugins}

if [ ! -f "/opt/airflow/airflow.db" ]; then
  echo "Initializing Airflow DB..."
  airflow db migrate && \
  airflow users create \
    --username admin \
    --firstname admin \
    --lastname admin \
    --role Admin \
    --email admin@example.com \
    --password admin
fi

$(command -v airflow) db upgrade

exec airflow webserver
