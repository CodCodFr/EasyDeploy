#!/bin/bash

# Charger les variables d'environnement depuis le fichier .env
BASE_DIR="$(dirname "$(dirname "$(realpath "$0")")")" # Racine du projet (/)
SERVICES_DIR="$BASE_DIR/services"                    # Chemin vers le dossier services

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

# Vérifier l'existence du fichier de service
SERVICE_FILE_PATH="$SERVICES_DIR/$SERVICE_FILE.service"
if [ ! -f "$SERVICE_FILE_PATH" ]; then
    echo "Error: Service file $SERVICE_FILE_PATH not found"
    exit 1
fi

ENV_FILE="$BASE_DIR/$SERVICE_FILE.env"

if [ -f "$ENV_FILE" ]; then
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
else
    echo "Error: .env file not found in $BASE_DIR"
    exit 1
fi

# Charger les variables depuis le fichier de service
source "$SERVICE_FILE_PATH"

# Vérifier les variables obligatoires
if [ -z "$NAME" ] || [ -z "$MEMORY" ]; then
    echo "Error: Missing required variables in $SERVICE_FILE_PATH"
    exit 1
fi

MODE_ARG=""
if [ -n "$MODE" ]; then
    MODE_ARG="--mode $MODE"
fi

NETWORK_ARG=""
if [ -n "$NETWORK" ]; then
    NETWORK_ARG="--network $NETWORK"
fi

REPLICAS_ARG=""
if [ -n "$REPLICAS" ]; then
        REPLICAS_ARG="--replicas $REPLICAS"
fi

ADDHOST_ARG=""
if [ -n "$ADDHOST" ]; then
    ADDHOST_ARG="--add-host $ADDHOST"
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

PORT1_ARG=""
if [ -n "$PORT1" ]; then
    PORT1_ARG="-p $PORT1"
fi

PORT2_ARG=""
if [ -n "$PORT2" ]; then
    PORT2_ARG="-p $PORT2"
fi

PORTS_ARG="$PORT1_ARG $PORT2_ARG"

# Préparer les mounts depuis les hôtes
MOUNT_ARGS=()
if [ -n "$MOUNT_FROM_HOSTS" ]; then
    IFS=',' read -r -a MOUNTS <<< "$MOUNT_FROM_HOSTS"
    for MOUNT in "${MOUNTS[@]}"; do
        # Séparer la source, la cible et les options (par exemple: :ro)
        IFS=':' read -r SOURCE TARGET OPTIONS <<< "$MOUNT"
        # Appliquer le flag --mount pour chaque montage
        MOUNT_ARGS+=("--mount type=bind,source=$SOURCE,target=$TARGET$([ -n "$OPTIONS" ] && echo ":$OPTIONS")")
    done
fi

# Debug: Afficher les MOUNT_ARGS
echo "MOUNT_ARGS:"
for ARG in "${MOUNT_ARGS[@]}"; do
    echo "$ARG"
done

# Créer le service Docker
if [ -n "$TYPE" ]; then
    docker pull "$TYPE"
    echo "Creating service $NAME with external image $TYPE on network $NETWORK"
    docker service create \
        --name "$NAME" \
        "${ENV_ARGS[@]}" \
        $REPLICAS_ARG \
        --limit-memory "$MEMORY" \
        $PORTS_ARGS \
        $NETWORK_ARG \
        ${MOUNT_ARGS:+${MOUNT_ARGS[@]}} \
        "$TYPE"
else
    docker pull ghcr.io/gaetanse/${NAME}-image:latest
    echo "Creating service $NAME with custom image ghcr.io/gaetanse/${NAME}-image:latest on network $NETWORK"

        docker service create \
        --name "$NAME" \
        "${ENV_ARGS[@]}" \
        $REPLICAS_ARG \
        --limit-memory "$MEMORY" \
        $PORTS_ARG \
        $NETWORK_ARG \
        $MODE_ARG \
        $ADDHOST_ARG \
        ${MOUNT_ARGS:+${MOUNT_ARGS[@]}} \
        "ghcr.io/gaetanse/${NAME}-image:latest"

fi

echo "Service $NAME created with $REPLICAS replicas, memory $MEMORY, port $PORT, network $NETWORK, environment variables: ${ENV_VARS[*]}, and mount: $MOUNT"
