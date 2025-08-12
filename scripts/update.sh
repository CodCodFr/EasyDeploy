#!/bin/bash

# Base directory paths
BASE_DIR="$(dirname "$(dirname "$(realpath "$0")")")" # Racine du projet (/)

# Fonction d'aide
usage() {
    echo "Usage: $0 -f SERVICE_FILE"
    echo ""
    echo "Arguments:"
    echo "  -f SERVICE_FILE  Fichier de configuration du service (ex: exemple.service)"
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

SERVICES_DIR="$BASE_DIR/$SERVICE_FILE"

# Vérifier l'existence du fichier de service
SERVICE_FILE_PATH="$SERVICE_DIR/$SERVICE_FILE"
if [ ! -f "$SERVICE_FILE_PATH" ]; then
    echo "Error: Service file $SERVICE_FILE_PATH not found"
    exit 1
fi

# Charger les variables depuis le fichier de service
source "$SERVICE_FILE_PATH"

# Vérifier les variables obligatoires
if [ -z "$NAME" ]; then
    echo "Error: NAME variable is missing in $SERVICE_FILE_PATH"
    exit 1
fi

# Mettre à jour le service Docker
if [ -z "$TYPE" ]; then
    IMAGE="ghcr.io/gaetanse/${NAME}-image:latest"
    echo "Pulling image $IMAGE"
    docker pull "$IMAGE"
    echo "Updating service $NAME with image $IMAGE"
    docker service update --image "$IMAGE" --force "$NAME"
else
    echo "Pulling image $TYPE"
    docker pull "$TYPE"
    echo "Updating service $NAME with image $TYPE"
    docker service update --image "$TYPE" --force "$NAME"
fi

echo "Service $NAME updated successfully."
