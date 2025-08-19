#!/bin/bash

# A simple script to remove a Docker stack.
# It requires the stack name as a command-line argument.

# Check if an argument was provided
if [ -z "$1" ]; then
  echo "Error: Please provide the name of the Docker compose to remove."
  echo "Usage: ./remove_stack.sh <_name>"
  exit 1
fi

# Store the provided argument in a variable
NAME=$1

# Remove the Docker stack
echo "Removing Docker compose: $NAME..."
docker compose -f "$NAME" down --remove-orphans

# Check the exit status of the previous command
if [ $? -eq 0 ]; then
  echo "Services '$NAME' removed successfully."
else
  echo "Error: Failed to remove stack '$NAME'."
fi