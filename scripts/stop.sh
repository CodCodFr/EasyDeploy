#!/bin/bash

# A simple script to remove a Docker stack.
# It requires the stack name as a command-line argument.

# Check if an argument was provided
if [ -z "$1" ]; then
  echo "Error: Please provide the name of the Docker stack to remove."
  echo "Usage: ./remove_stack.sh <stack_name>"
  exit 1
fi

# Store the provided argument in a variable
STACK_NAME=$1

# Remove the Docker stack
echo "Removing Docker stack: $STACK_NAME..."
docker stack rm "$STACK_NAME"

# Check the exit status of the previous command
if [ $? -eq 0 ]; then
  echo "Stack '$STACK_NAME' removed successfully."
else
  echo "Error: Failed to remove stack '$STACK_NAME'."
fi