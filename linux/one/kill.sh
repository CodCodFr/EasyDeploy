#!/bin/bash

# Default value for the service name
NAME="default_name"

# Parse the arguments
while getopts "n:" opt; do
  case $opt in
    n)
      NAME=$OPTARG
      ;;
    *)
      echo "Usage: $0 -n <service_name>"
      exit 1
      ;;
  esac
done

# Scale down and remove the service
docker service scale "$NAME"