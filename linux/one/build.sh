#!/bin/bash

# Base directory and .env file path
BASE_DIR="$(dirname "$(dirname "$(realpath "$0")")")" # Base directory is /
ENV_FILE="$BASE_DIR/.env"

# Load environment variables from the .env file
if [ -f "$ENV_FILE" ]; then
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
else
    echo "Error: .env file not found in $BASE_DIR"
    exit 1
fi

# Default values
REPLICAS=1
MEMORY=512m
PORT=80
NETWORK="default_network"
NAM="default_name"
TYPE=""
ENV_VARS=()
MOUNTS=()

# Parse arguments
while getopts "r:me:p:net:nam:type:e:mo:" opt; do
  case $opt in
    r)
      REPLICAS=$OPTARG
      ;;
    me)
      MEMORY="${OPTARG}m"
      ;;
    p)
      PORT=$OPTARG
      ;;
    net)
      NETWORK=$OPTARG
      ;;
    nam)
      NAM=$OPTARG
      ;;
    type)
      TYPE=$OPTARG
      ;;
    e)
      ENV_VARS+=("$OPTARG")
      ;;
    mo)
      MOUNTS+=("$OPTARG")
      ;;
    *)
      echo "Usage: $0 -r <replicas> -me <memory_in_MB> -p <port> -net <network> -nam <name> -e <env_var> -mo <mount>"
      exit 1
      ;;
  esac
done

# Create options for environment variables
ENV_OPTS=""
for ENV_VAR in "${ENV_VARS[@]}"; do
  ENV_OPTS+="--env $ENV_VAR "
done

# Create options for mounts
MOUNT_OPTS=""
for MOUNT in "${MOUNTS[@]}"; do
  MOUNT_OPTS+="--
