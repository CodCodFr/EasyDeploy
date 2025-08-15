#!/bin/bash

# Check if a stack name argument was provided
if [ -z "$1" ]; then
  echo "Error: Please provide a stack name as an argument."
  echo "Usage: ./deploy.sh <stack_name>"
  exit 1
fi

STACK_NAME=$1

echo "Deploying Docker stack '$STACK_NAME'..."

docker stack deploy -c docker-compose.yml "$STACK_NAME" --with-registry-auth

echo "Deployment complete."