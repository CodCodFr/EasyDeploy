#!/bin/bash

# Default container name
CONTAINER_NAME=""

# Parse arguments
while getopts "n:" opt; do
    case "$opt" in
        n) CONTAINER_NAME="$OPTARG" ;;
        *) echo "Usage: $0 -n <container_name>"
           exit 1 ;;
    esac
done

# Check if the container name is provided
if [ -z "$CONTAINER_NAME" ]; then
    echo "Container name is required. Usage: $0 -n <container_name>"
    exit 1
fi

# Check if the container exists
docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "$CONTAINER_NAME"
if [ $? -ne 0 ]; then
    echo "No container found with name '$CONTAINER_NAME'."
    exit 1
fi

# Run the psql command to delete all tables
docker exec -it "$CONTAINER_NAME" psql -U your_db_user -d your_db_name -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
echo "All tables have been deleted in container '$CONTAINER_NAME'."
