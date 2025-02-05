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
    echo "Parsed values - NAME: $NAME, MEMORY: $MEMORY, PORT: $PORT, REPLICAS: $REPLICAS, TYPE: $TYPE, NETWORK: $NETWORK, ENV: $ENV"

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

    # Vérifier si PORT2 est vide et ajuster la commande docker
    if [ -z "$PORT2" ]; then
        echo "Only one port specified: $PORT1"
        PORT_ARGS="-p $PORT1"
    else
        PORT_ARGS="-p $PORT1 -p $PORT2"
    fi

    # Assuming MOUNT_ARGS is being populated like this (from your previous logic)
MOUNT_ARGS=()
if [ -n "$MOUNT_FROM_HOSTS" ]; then
    IFS=',' read -r -a MOUNTS <<< "$MOUNT_FROM_HOSTS"
    for MOUNT in "${MOUNTS[@]}"; do
        # Split source, target, and options (e.g., :ro)
        IFS=':' read -r SOURCE TARGET OPTIONS <<< "$MOUNT"
        MOUNT_ARGS+=("--mount type=bind,source=$SOURCE,target=$TARGET$([ -n "$OPTIONS" ] && echo ":$OPTIONS")")
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
            $PORT_ARGS \
            --network "$NETWORK" \
            ${MOUNT_ARGS:+${MOUNT_ARGS[@]}} \
            "$TYPE"
    else
        docker pull ghcr.io/gaetanse/${NAME}-image:latest
        echo "Creating service $NAME with custom image ghcr.io/gaetanse/${NAME}-image:latest on network $NETWORK"
        docker service create \
            --name "$NAME" \
            "${ENV_ARGS[@]}" \
            --replicas "$REPLICAS" \
            --limit-memory "$MEMORY" \
            $PORT_ARGS \
            --network "$NETWORK" \
            ${MOUNT_ARGS:+${MOUNT_ARGS[@]}} \
            "ghcr.io/gaetanse/${NAME}-image:latest"
    fi

    echo "Service $NAME created with $REPLICAS replicas, memory $MEMORY, port $PORT, network $NETWORK, environment variables: ${ENV_VARS[*]}"
done < "$SERVICES_LIST"
