#!/bin/bash

# Default value for the service name
SERVICE_NAME="default_name"

# Parse the arguments
while getopts "f:" opt; do
  case $opt in
    f)
      SERVICE_NAME=$OPTARG
      ;;
    *)
      echo "Usage: $0 -f <service_name>"
      exit 1
      ;;
  esac
done

# Get the number of replicas for the service
REPLICAS=$(docker service inspect --format '{{.Spec.Mode.Replicated.Replicas}}' "$SERVICE_NAME")

# Check if the replica count is greater than 0
if [[ "$REPLICAS" -gt 0 ]]; then
    echo "Scaling down '$SERVICE_NAME' from $REPLICAS to 0 replicas."
    docker service scale "$SERVICE_NAME"=0
else
    echo "Service '$SERVICE_NAME' already has 0 replicas. Skipping."
fi

docker service rm "$NAME"
