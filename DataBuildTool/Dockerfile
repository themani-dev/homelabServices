FROM python:3.11-slim

ARG DBT_ADAPTER=bigquery         # default value

ENV DEBIAN_FRONTEND=noninteractive
ENV DBT_PROFILES_DIR=/app/profiles

RUN apt-get update && \
    apt-get install -y git curl unzip nano && \
    pip install --no-cache-dir dbt-core dbt-${DBT_ADAPTER}

WORKDIR /app

COPY ./framework/${DBT_ADAPTER} /app
COPY ./profiles/profiles_${DBT_ADAPTER}.yml /app/profiles/profiles.yml
COPY ./serviceAccounts/gcloud.json /app/gcloud.json

CMD ["sleep", "infinity"]
