#!/bin/bash

# Default value for the service name
NAME="default_name"

# Parse the arguments
while getopts "f:" opt; do
  case $opt in
    f)
      NAME=$OPTARG
      ;;
    *)
      echo "Usage: $0 -f <service_name>"
      exit 1
      ;;
  esac
done

# Scale down and remove the service
docker service scale "$NAME"=0
docker service rm "$NAME"
