#!/bin/bash

# ==============================================================================
# Script to deploy a Docker Compose project
# ==============================================================================

# ==============================================================================
# Usage:
# ./deploy.sh [docker_compose_file] [project_name]
#
# Example:
# ./deploy.sh main.yml my_app
# ==============================================================================

# ==============================================================================
# 1. Get arguments
# ==============================================================================

dockerComposeFile="$1"
projectName="$2"

# Check if both arguments were provided
if [ -z "$dockerComposeFile" ] || [ -z "$projectName" ]; then
  echo "Error: Please provide a docker compose file name and a project name as arguments."
  echo "Usage: ./deploy.sh [docker_compose_file] [project_name]"
  exit 1
fi

# ==============================================================================
# 2. Deploy the Docker Compose project
# ==============================================================================

echo "Deploying Docker compose '$dockerComposeFile' as project '$projectName'..."

# Deploy the services, using the provided project name
docker compose -f "$dockerComposeFile" -p "$projectName" up -d --remove-orphans

echo "Deployment complete."