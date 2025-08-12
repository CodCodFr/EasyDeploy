#!/bin/bash

# Base directory paths
BASE_DIR="$(dirname "$(dirname "$(realpath "$0")")")" # Racine du projet (/)
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

# Vérifier l'existence du dossier services
if [ ! -d "$SERVICES_DIR" ]; then
    echo "Error: Services directory $SERVICES_DIR not found"
    exit 1
fi

# Parcourir les fichiers présents dans le dossier services
for SERVICE_FILE in "$SERVICES_DIR"/*; do
    # Vérifier si le fichier est un fichier régulier
    if [ ! -f "$SERVICE_FILE" ]; then
        echo "Warning: Skipping non-file entry $SERVICE_FILE"
        continue
    fi

    # Charger les variables du fichier service
    source "$SERVICE_FILE"

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

    # Construire les arguments de montage
    MOUNT_ARGS=()
    if [ -n "$MOUNT_FROM_HOSTS" ]; then
        IFS=',' read -r -a MOUNTS <<< "$MOUNT_FROM_HOSTS"
        for MOUNT in "${MOUNTS[@]}"; do
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
done
