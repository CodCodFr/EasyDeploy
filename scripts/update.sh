# ==============================================================================
# Script pour puller l'image et déployer sur un serveur distant (VPS)
# ==============================================================================

# ==============================================================================
# Utilisation:
# ./deploy_script.sh [stack_name] [service_name] [image_repo] [image_tag]
#
# Exemple:
# ./deploy_script.sh codcod future-front ghcr.io/gaetanse/future-front-image e20e92094aec8e551f56176a3cdcfee19a15d7a8
# ==============================================================================

# ==============================================================================
# 1. Récupération des arguments
# ==============================================================================

stackName="$1"
serviceName="$2"
imageRepo="$3"
imageTagToDeploy="$4"

# Vérification des arguments
if [ -z "$stackName" ] || [ -z "$serviceName" ] || [ -z "$imageRepo" ] || [ -z "$imageTagToDeploy" ]; then
    echo "Erreur: Tous les arguments sont requis."
    echo "Utilisation: ./deploy_script.sh [stack_name] [service_name] [image_repo] [image_tag]"
    exit 1
fi

# ==============================================================================
# 2. Pull et déploiement de la stack Docker Swarm
# ==============================================================================

echo "Mise à jour de la stack Docker Swarm '$stackName'..."
echo "Service: $serviceName"
echo "Image: $imageRepo:$imageTagToDeploy"

# Mettre à jour l'image du service dans le docker-compose.yml
# L'image est remplacée par la nouvelle imageTagToDeploy
# This command must run BEFORE docker compose pull
sed -i "s|image: $imageRepo:.*|image: $imageRepo:$imageTagToDeploy|" docker-compose.yml

# Récupérer l'image spécifiée
docker compose pull "$serviceName"

# Vérifier si la commande précédente a échoué
if [ $? -ne 0 ]; then
    echo "Erreur lors du pull de l'image Docker."
    exit 1
fi

# Déployer la stack avec l'image mise à jour.
# L'option --with-registry-auth est essentielle pour les registres privés.
docker stack deploy -c docker-compose.yml "$stackName" --with-registry-auth

# Vérifier si la commande précédente a échoué
if [ $? -ne 0 ]; then
    echo "Le déploiement de la stack a échoué."
    exit 1
fi

echo "Stack '$stackName' mise à jour avec succès."