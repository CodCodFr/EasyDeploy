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

# Check if the service exists
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "Service '$SERVICE_NAME' not found. Exiting."
    exit 1
fi

# Get the service mode
MODE=$(docker service inspect --format '{{.Spec.Mode.Global}}' "$SERVICE_NAME")

if [ "$MODE" != "<nil>" ]; then
    echo "Service '$SERVICE_NAME' is in global mode. Removing..."
    docker service rm "$SERVICE_NAME"
else
    # It's a replicated service, get the number of replicas
    REPLICAS=$(docker service inspect --format '{{.Spec.Mode.Replicated.Replicas}}' "$SERVICE_NAME")
    if [[ "$REPLICAS" -gt 0 ]]; then
        echo "Scaling down '$SERVICE_NAME' from $REPLICAS to 0 replicas."
        docker service scale "$SERVICE_NAME"=0
        # Only remove after scaling down
        docker service rm "$SERVICE_NAME"
    else
        echo "Service '$SERVICE_NAME' already has 0 replicas. Removing..."
        docker service rm "$SERVICE_NAME"
    fi
fi