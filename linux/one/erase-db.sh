#!/bin/bash

# Find the correct container name
CONTAINER_NAME=$(docker ps --filter "name=evolu-db" --format "{{.Names}}")

if [ -z "$CONTAINER_NAME" ]; then
    echo "No 'evolu-db' container found!"
    exit 1
fi

# Run the psql command to delete all tables
docker exec -it "$CONTAINER_NAME" psql -U your_db_user -d your_db_name -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
echo "All tables have been deleted."
