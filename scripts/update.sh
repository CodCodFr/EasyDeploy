#!/bin/bash

# ==============================================================================
# Script pour puller l'image et démarrer un service avec Docker Compose
# ==============================================================================

# ==============================================================================
# Utilisation:
# ./deploy_script_compose.sh [service_name] [image_repo] [image_tag] [docker_compose_file] [project_name]
#
# Exemple:
# ./deploy_script_compose.sh future-front ghcr.io/gaetanse/future-front e20e92094aec8e551f56176a3cdcfee19a15d7a8 main.yml
# ==============================================================================

# ==============================================================================
# 1. Récupération des arguments
# ==============================================================================

serviceName="$1"
imageRepo="$2"
imageTagToDeploy="$3"
dockerComposeFile="$4"
projectName="$5"

# Vérification des arguments
if [ -z "$serviceName" ] || [ -z "$imageRepo" ] || [ -z "$imageTagToDeploy" ] || [ -z "$dockerComposeFile" ] || [ -z "$projectName" ]; then
    echo "Erreur: Tous les arguments sont requis."
    echo "Utilisation: ./deploy_script_compose.sh [service_name] [image_repo] [image_tag] [docker_compose_file] [project_name]"
    exit 1
fi

# ==============================================================================
# 2. Pull et déploiement du service avec Docker Compose
# ==============================================================================

echo "Mise à jour du service Docker Compose '$serviceName'..."
echo "Image: $imageRepo:$imageTagToDeploy"

# Mettre à jour l'image du service dans le fichier de configuration spécifié
sed -i "s|image: $imageRepo:.*|image: $imageRepo:$imageTagToDeploy|" "$dockerComposeFile"

# Récupérer l'image spécifiée
docker compose -f "$dockerComposeFile" pull "$serviceName"

# Vérifier si la commande précédente a échoué
if [ $? -ne 0 ]; then
    echo "Erreur lors du pull de l'image Docker."
    exit 1
fi

# Démarrer le service avec l'image mise à jour.
docker compose -f "$dockerComposeFile" -p "$projectName" up -d --no-deps --force-recreate --remove-orphans "$serviceName"

# Vérifier si la commande précédente a échoué
if [ $? -ne 0 ]; then
    echo "Le déploiement du service a échoué."
    exit 1
fi

echo "Service '$serviceName' mis à jour avec succès."