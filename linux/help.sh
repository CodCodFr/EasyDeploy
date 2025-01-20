#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
RESET='\033[0m' # Réinitialisation de la couleur

echo_color() {
    COLOR=$1
    MESSAGE=$2
    echo -e "${COLOR}${MESSAGE}${RESET}"
}

echo_color $WHITE  "Liste des fichiers avec leurs utilisations :"
    echo

echo
echo_color $GREEN "build_all.sh à la racine"
    echo
        echo_color $WHITE "Permet de démarrer tous les services!"

echo
echo_color $GREEN "build.sh à la racine"
    echo
        echo_color $RED "Arguments : -nam <Nom du service> (exemple)"
        echo_color $RED "Arguments : -me <Mémoire> (512m)"
        echo_color $RED "Arguments : -p <Port> (80)"
        echo_color $RED "Arguments : -r <Le nombre de réplicas> (3)"
        echo_color $RED "Arguments : -t <Type> () (postgres:17.2-alpine)"
        echo_color $RED "Arguments : -net <Réseau> (my_network)"
        echo_color $RED "Arguments : -e <Variables d'environements> () (POSTGRES_USER,POSTGRES_PASSWORD)"
        echo_color $RED "Arguments : -mo <Dossier à partager> () (type=bind,source=/home/user/example-data,target=/var/lib/postgresql/data)"

echo
echo_color $GREEN "kill_all.sh à la racine"
    echo
        echo_color $WHITE "Permet de stopper tous les services!"

echo
echo_color $GREEN "kill.sh à la racine"
    echo
        echo_color $WHITE "Permet de stopper un service!"
    echo
        echo_color $RED "Arguments : -n <Nom du service>"
    echo
        echo_color $YELLOW "Exemple : kill.sh -n exemple"

echo
echo_color $GREEN "services.list à la racine"
    echo
        echo_color $WHITE "Permet d'ajouter des services à charger dans la liste!"
    echo
        echo_color $YELLOW "(Chemin du fichier) Exemple : services/exemple.service"

echo
echo_color $GREEN "exemple.service dans le dossier services"
    echo
        echo_color $WHITE "Permet de définir un service avec plusieurs paramètres!"
    echo
        echo_color $YELLOW "(Nom de l'app) Exemple : NAME=exemple"
        echo_color $YELLOW "(Mémoire) Exemple : MEMORY=512m"
        echo_color $YELLOW "(Port) Exemple : PORT=80"
        echo_color $YELLOW "(Le nombre de réplicas) Exemple : REPLICAS=1"
        echo_color $YELLOW "(Défini si c'est une image personnalisé ou non) Exemple 1 : TYPE= | Exemple 2 : TYPE=postgres:17.2-alpine"
        echo_color $YELLOW "(Réseau) Exemple : NETWORK=my_network"
        echo_color $YELLOW "(Variables d'environements) Exemple 1 : ENV= | Exemple 2 : ENV=POSTGRES_USER,POSTGRES_PASSWORD"
        echo_color $YELLOW "(Dossier à partager) Exemple 1 : MOUNT= | Exemple 2 : MOUNT=type=bind,source=/home/user/example-data,target=/var/lib/postgresql/data"

echo
echo_color $RED ".env dans le dossier /all"
    echo
        echo_color $WHITE "Permet de comprendre le fonctionnement des scripts!"