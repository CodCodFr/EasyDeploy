#!/bin/bash

# Charger les variables d'environnement depuis le fichier .env
BASE_DIR="$(dirname "$(dirname "$(realpath "$0")")")" # Racine du projet (/)
SERVICES_DIR="$BASE_DIR/services"                    # Chemin vers le dossier services
ENV_FILE="$BASE_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
else
    echo "Error: .env file not found in $BASE_DIR"
    exit 1
fi

# Fonction d'aide
usage() {
    echo "Usage: $0 -f SERVICE_FILE"
    echo ""
    echo "Arguments:"
    echo "  -f SERVICE_FILE  Fichier de configuration du service (ex: evolu-front.service)"
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

# Vérifier l'existence du fichier de service
SERVICE_FILE_PATH="$SERVICES_DIR/$SERVICE_FILE"
if [ ! -f "$SERVICE_FILE_PATH" ]; then
    echo "Error: Service file $SERVICE_FILE_PATH not found"
    exit 1
fi

# Charger les variables depuis le fichier de service
source "$SERVICE_FILE_PATH"

# Vérifier les variables obligatoires
if [ -z "$NAME" ] || [ -z "$MEMORY" ] || [ -z "$PORT" ] || [ -z "$REPLICAS" ] || [ -z "$NETWORK" ]; then
    echo "Error: Missing required variables in $SERVICE_FILE_PATH"
    exit 1
fi

# Préparer les variables d'environnement
ENV_ARGS=()
if [ -n "$ENV" ]; then
    IFS=',' read -r -a ENV_VARS <<< "$ENV"
    for ENV_VAR in "${ENV_VARS[@]}"; do
        VALUE=${!ENV_VAR}
        if [ -n "$VALUE" ]; then
            ENV_ARGS+=("--env=${ENV_VAR}=${VALUE}")
        else
            echo "Warning: Environment variable $ENV_VAR is not defined in the .env file"
        fi
    done
fi

# Créer le service Docker
if [ -n "$TYPE" ]; then
    docker pull "$TYPE"
    echo "Creating service $NAME with external image $TYPE on network $NETWORK"
    docker service create \
        --name "$NAME" \
        "${ENV_ARGS[@]}" \
        --replicas "$REPLICAS" \
        --limit-memory "$MEMORY" \
        -p "$PORT:$PORT" \
        --network "$NETWORK" \
        ${MOUNT:+--mount "$MOUNT"} \
        "$TYPE"
else
    docker pull ghcr.io/gaetanse/${NAME}-image:latest
    echo "Creating service $NAME with custom image ghcr.io/gaetanse/${NAME}-image:latest on network $NETWORK"
    docker service create \
        --name "$NAME" \
        "${ENV_ARGS[@]}" \
        --replicas "$REPLICAS" \
        --limit-memory "$MEMORY" \
        -p "$PORT:$PORT" \
        --network "$NETWORK" \
        ${MOUNT:+--mount "$MOUNT"} \
        "ghcr.io/gaetanse/${NAME}-image:latest"
fi

echo "Service $NAME created with $REPLICAS replicas, memory $MEMORY, port $PORT, network $NETWORK, environment variables: ${ENV_VARS[*]}, and mount: $MOUNT"