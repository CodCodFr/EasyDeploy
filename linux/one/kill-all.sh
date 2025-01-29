#!/bin/bash

echo "Stopping and removing all services..."

# List all services and scale each down to 0, then remove them
docker service ls --format "{{.Name}}" | while read -r service; do
  echo "Stopping service: $service"
  docker service scale "$service"=0
  docker service rm "$service"
done

echo "All services have been stopped and removed."
