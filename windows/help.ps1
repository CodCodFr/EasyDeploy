# Définition des couleurs
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$WHITE = "`e[37m"
$RESET = "`e[0m" # Réinitialisation de la couleur

function Echo-Color {
    param(
        [string]$Color,
        [string]$Message
    )
    Write-Host "$Color$Message$RESET"
}

# Affichage du contenu
Echo-Color $WHITE "Liste des fichiers avec leurs utilisations :"
Write-Host ""

Echo-Color $GREEN "build_all.sh à la racine"
Write-Host ""
Echo-Color $WHITE "Permet de démarrer tous les services!"

Write-Host ""
Echo-Color $GREEN "build.sh à la racine"
Write-Host ""
Echo-Color $RED "Arguments : -nam <Nom du service> (exemple)"
Echo-Color $RED "Arguments : -me <Mémoire> (512m)"
Echo-Color $RED "Arguments : -p <Port> (80)"
Echo-Color $RED "Arguments : -r <Le nombre de réplicas> (3)"
Echo-Color $RED "Arguments : -t <Type> () (postgres:17.2-alpine)"
Echo-Color $RED "Arguments : -net <Réseau> (my_network)"
Echo-Color $RED "Arguments : -e <Variables d'environements> () (POSTGRES_USER,POSTGRES_PASSWORD)"
Echo-Color $RED "Arguments : -mo <Dossier à partager> () (type=bind,source=/home/user/example-data,target=/var/lib/postgresql/data)"

Write-Host ""
Echo-Color $GREEN "kill_all.sh à la racine"
Write-Host ""
Echo-Color $WHITE "Permet de stopper tous les services!"

Write-Host ""
Echo-Color $GREEN "kill.sh à la racine"
Write-Host ""
Echo-Color $WHITE "Permet de stopper un service!"
Write-Host ""
Echo-Color $RED "Arguments : -n <Nom du service>"
Write-Host ""
Echo-Color $YELLOW "Exemple : kill.sh -n exemple"

Write-Host ""
Echo-Color $GREEN "services.list à la racine"
Write-Host ""
Echo-Color $WHITE "Permet d'ajouter des services à charger dans la liste!"
Write-Host ""
Echo-Color $YELLOW "(Chemin du fichier) Exemple : services/exemple.service"

Write-Host ""
Echo-Color $GREEN "exemple.service dans le dossier services"
Write-Host ""
Echo-Color $WHITE "Permet de définir un service avec plusieurs paramètres!"
Write-Host ""
Echo-Color $YELLOW "(Nom de l'app) Exemple : NAME=exemple"
Echo-Color $YELLOW "(Mémoire) Exemple : MEMORY=512m"
Echo-Color $YELLOW "(Port) Exemple : PORT=80"
Echo-Color $YELLOW "(Le nombre de réplicas) Exemple : REPLICAS=1"
Echo-Color $YELLOW "(Défini si c'est une image personnalisé ou non) Exemple 1 : TYPE= | Exemple 2 : TYPE=postgres:17.2-alpine"
Echo-Color $YELLOW "(Réseau) Exemple : NETWORK=my_network"
Echo-Color $YELLOW "(Variables d'environements) Exemple 1 : ENV= | Exemple 2 : ENV=POSTGRES_USER,POSTGRES_PASSWORD"
Echo-Color $YELLOW "(Dossier à partager) Exemple 1 : MOUNT= | Exemple 2 : MOUNT=type=bind,source=/home/user/example-data,target=/var/lib/postgresql/data"

Write-Host ""
Echo-Color $RED ".env à la racine"