#!/bin/bash

# Check if a stack name argument was provided
if [ -z "$1" ]; then
  echo "Error: Please provide a docker compose file name as an argument."
  echo "Usage: ./deploy.sh <name>"
  exit 1
fi

NAME=$1

echo "Deploying Docker compose '$NAME'..."

#docker stack deploy -c docker-compose.yml "$NAME" --with-registry-auth
docker compose -f "$NAME" up -d --remove-orphans

echo "Deployment complete."