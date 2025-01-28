#!/bin/bash

# Default container name and backup name
CONTAINER_NAME=""
BACKUP_NAME=""

# Parse arguments
while getopts "n:b:" opt; do
    case "$opt" in
        n) CONTAINER_NAME="$OPTARG" ;;  # Container name
        b) BACK_NAME="$OPTARG" ;;      # Back name (optional)
        *) echo "Usage: $0 -n <container_name> -b <backup_name>"
           exit 1 ;;
    esac
done

# Check if the container name is provided
if [ -z "$CONTAINER_NAME" ]; then
    echo "Container name is required. Usage: $0 -n <container_name> -b <backup_name>"
    exit 1
fi

# Check if the container name is provided
if [ -z "$BACK_NAME" ]; then
    echo "Container back name is required. Usage: $0 -n <container_name> -b <backup_name>"
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
docker exec -it "$CONTAINER_ID" psql -U your_db_user -d your_db_name -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
echo "All tables have been deleted in container '$CONTAINER_ID'."

# Run kill.sh with the container name
#echo "Running kill.sh to stop and remove the container..."
#./one/kill.sh -n "$CONTAINER_NAME"

# Run build.sh with the corresponding service file
#SERVICE_FILE="${CONTAINER_NAME}.service"
#echo "Running build.sh to recreate the service..."
#./one/build.sh -f "$SERVICE_FILE"

# Check if a backup name is provided and run restart.sh if necessary
if [ -n "$BACK_NAME" ]; then
    echo "Running restart.sh for back '$BACK_NAME'..."
    ./one/update.sh -f "$BACK_NAME"
fi

# Final confirmation
echo "Service '$CONTAINER_NAME' has been updated and recreated."

