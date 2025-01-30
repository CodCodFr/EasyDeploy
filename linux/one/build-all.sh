#!/bin/bash

# Base directory paths
BASE_DIR="$(dirname "$(dirname "$(realpath "$0")")")" # Racine du projet (/)
SERVICES_LIST="$BASE_DIR/services.list"              # Chemin vers /services.list
SERVICES_DIR="$BASE_DIR/services"                   # Chemin vers /services

# Charger les variables d'environnement depuis le fichier .env
ENV_FILE="$BASE_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
else
    echo "Error: .env file not found in $BASE_DIR"
    exit 1
fi

echo "Searching for .env file at: $ENV_FILE"

# Vérifier l'existence de la liste des services
if [ ! -f "$SERVICES_LIST" ]; then
    echo "Error: $SERVICES_LIST file not found at $SERVICES_LIST"
    exit 1
fi

# Parcourir les fichiers listés dans services.list
while read -r SERVICE_FILE; do
    # Construire le chemin complet vers le fichier de service
    SERVICE_FILE_PATH="$SERVICES_DIR/$SERVICE_FILE"
    if [ ! -f "$SERVICE_FILE_PATH" ]; then
        echo "Warning: Service file $SERVICE_FILE_PATH not found. Skipping."
        continue
    fi

    # Charger les variables du fichier service
    source "$SERVICE_FILE_PATH"

    # Debug des valeurs chargées
    echo "Processing service: $NAME"
    echo "Parsed values - NAME: $NAME, MEMORY: $MEMORY, PORT: $PORT, REPLICAS: $REPLICAS, TYPE: $TYPE, NETWORK: $NETWORK, ENV: $ENV, MOUNT: $MOUNT"

    # Préparer les variables d'environnement
    ENV_ARGS=()
    IFS=',' read -r -a ENV_VARS <<< "$ENV"
    for ENV_VAR in "${ENV_VARS[@]}"; do
        VALUE=${!ENV_VAR}
        if [ -n "$VALUE" ]; then
            ENV_ARGS+=("--env=${ENV_VAR}=${VALUE}")
        else
            echo "Warning: Environment variable $ENV_VAR is not defined in the .env file"
        fi
    done

    # Créer le service Docker
    if [ -n "$TYPE" ]; then
        docker pull "$TYPE"
        echo "Creating service $NAME with external image $TYPE on network $NETWORK"
        docker service create \
            --name "$NAME" \
            "${ENV_ARGS[@]}" \
            --replicas "$REPLICAS" \
            --limit-memory "$MEMORY" \
            -p "$PORT1:$PORT2" \
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
            -p "$PORT1:$PORT2" \
            --network "$NETWORK" \
            ${MOUNT:+--mount "$MOUNT"} \
            "ghcr.io/gaetanse/${NAME}-image:latest"
    fi

    echo "Service $NAME created with $REPLICAS replicas, memory $MEMORY, port $PORT, network $NETWORK, environment variables: ${ENV_VARS[*]}, and mount: $MOUNT"
done < "$SERVICES_LIST"
