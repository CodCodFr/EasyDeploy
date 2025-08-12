#!/bin/bash

# Charger les variables d'environnement depuis le fichier .env
BASE_DIR="$(dirname "$(dirname "$(realpath "$0")")")" # Racine du projet (/)

# Fonction d'aide
usage() {
    echo "Usage: $0 -f SERVICE_FILE"
    echo ""
    echo "Arguments:"
    echo "  -f service"
    echo ""
    exit 1
}

# Lire les arguments
while getopts "f:" opt; do
    case $opt in
        f) SERVICE_FILE="$OPTARG" ;;
        *) usage ;;
    esac
done

# Vérifier si un fichier a été fourni
if [ -z "$SERVICE_FILE" ]; then
    echo "Error: Missing -f argument"
    usage
fi

if [ ! -d "$BASE_DIR/$SERVICE_FILE" ]; then
  mkdir $BASE_DIR/$SERVICE_FILE
  echo "Folder created successfully. ($BASE_DIR/$SERVICE_FILE)"
else
  echo "Folder already exists. ($BASE_DIR/$SERVICE_FILE)"
fi

ENV_FILE_PATH=$BASE_DIR/$SERVICE_FILE/$SERVICE_FILE.env
if [ -f "$ENV_FILE_PATH" ]; then
  echo "File exists! $ENV_FILE_PATH"
else
  touch "$ENV_FILE_PATH"
  echo "Env file created successfully. ($ENV_FILE_PATH)"
fi

SERVICE_FILE_PATH="$BASE_DIR/$SERVICE_FILE/$SERVICE_FILE.service"
if [ -f "$SERVICE_FILE_PATH" ]; then
  echo "File exists! $SERVICE_FILE_PATH"
else
  touch "$SERVICE_FILE_PATH"
  echo "Service file created successfully. ($SERVICE_FILE_PATH)"
fi
