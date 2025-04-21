#!/bin/bash

# Exit on error
set -e

# Config variables
IMAGE_NAME="dbt"
PROJECT_ID="hakoona-matata-298704"
REGION="us-west2"
REPO="dataengineering"
TAG="latest"

# Full image path
FULL_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE_NAME}:${TAG}"

# Docker build, tag, and push
echo "🔨 Building Docker image..."
docker build -t ${IMAGE_NAME} .

echo "🏷️ Tagging image as ${FULL_IMAGE}..."
docker tag ${IMAGE_NAME} ${FULL_IMAGE}

echo "📤 Pushing image to Artifact Registry..."
docker push ${FULL_IMAGE}

echo "✅ Done!"
