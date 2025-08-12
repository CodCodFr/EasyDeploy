#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables from ../.env (one level up)
if [ -f "$SCRIPT_DIR/../.env" ]; then
    set -o allexport
    source "$SCRIPT_DIR/../.env"
    set +o allexport
fi

# Default container name and backup name
CONTAINER_NAME=""
BACKUP_NAME=""

# Parse arguments
while getopts "f:b:" opt; do
    case "$opt" in
        f) CONTAINER_NAME="$OPTARG" ;;  # Container name
        *) echo "Usage: $0 -f <container_name>"
           exit 1 ;;
    esac
done

# Check if the container name is provided
if [ -z "$CONTAINER_NAME" ]; then
    echo "Container name is required. Usage: $0 -f <container_name>"
    exit 1
fi

# Get the actual container ID or name for the service task
CONTAINER_ID=$(docker ps --filter "name=${CONTAINER_NAME}." --filter "status=running" --format "{{.ID}}" | head -n 1)

if [ -z "$CONTAINER_ID" ]; then
    echo "No running container found for service '$CONTAINER_NAME'."
    exit 1
fi

# Run the psql command to delete all tables
echo "Dropping all tables in the database for container '$CONTAINER_ID'..."
docker exec -i "$CONTAINER_ID" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
echo "All tables have been deleted in container '$CONTAINER_ID'."

# Final confirmation
echo "Service '$CONTAINER_NAME' has been updated and recreated."
echo "Warning: don't forget to update backend for send first sql!"
