# --- 0. Vérification de la version du Repo Git ---
Write-Host "Vérification de la mise à jour du dépôt Git..."

# Vérifier si on est dans un dépôt Git
if (Test-Path .git) {
    git fetch origin
    $local = git rev-parse HEAD
    $remote = git rev-parse "@{u}"
    $base = git merge-base HEAD "@{u}"

    if ($local -eq $remote) {
        Write-Host "✅ Le dépôt est à jour." -ForegroundColor Green
    } elseif ($local -eq $base) {
        Write-Error "❌ Votre dépôt local est en retard par rapport au serveur. Veuillez faire un 'git pull' avant de déployer."
        exit 1
    } elseif ($remote -eq $base) {
        Write-Warning "⚠️ Vous avez des commits locaux non poussés. Le déploiement continuera avec votre version locale."
    } else {
        Write-Error "❌ Les branches locale et distante ont divergé."
        exit 1
    }
} else {
    Write-Warning "Aucun dépôt Git détecté dans ce dossier. Saut de la vérification."
}

# Définir le chemin du fichier de données
$dataPath = ".\EasyDeploy\data.ps1"

# Vérifier si le fichier de données existe
if (-not (Test-Path -Path $dataPath)) {
    Write-Error "Erreur : Le fichier de données '$dataPath' est introuvable."
    exit 1
}

# Use dot-sourcing to load all variables from the data script.
# This executes the data.ps1 script, and the variables become available in the current scope.
. $dataPath

$DOCKER_IMAGE_NAME_COMPLETE = "$DOCKER_REPO/$DOCKER_IMAGE_NAME"

function Load-EnvFile {
    param ([string]$filePath)
    if (Test-Path $filePath) {
        Write-Host "Loading environment variables from $filePath..."
        Get-Content $filePath | ForEach-Object {
            # Regex to match KEY=VALUE, ignoring comments and empty lines
            if ($_ -match "^\s*([A-Za-z0-9_]+)\s*=\s*(.*)\s*$") {
                $envName = $matches[1]
                $envValue = $matches[2]
                [System.Environment]::SetEnvironmentVariable($envName, $envValue, [System.EnvironmentVariableTarget]::Process)
                Write-Host "  - Loaded $envName"
            }
        }
    }
    else {
        return $false
    }
    return $true
}

# --- PROCESS FILES ---

# 1. Mandatory: GIT_ENV_FILE_PATH
if (-not (Load-EnvFile -filePath $GIT_ENV_FILE_PATH)) {
    Write-Error "Error: REQUIRED file not found at $GIT_ENV_FILE_PATH"
    Exit 1
}

# 2. Optional: ENV_FILE_PATH (Skip if not found)
if (-not (Load-EnvFile -filePath $ENV_FILE_PATH)) {
    Write-Host "Notice: Optional file at $ENV_FILE_PATH not found. Skipping..." -ForegroundColor Yellow
}

if ($TYPE -eq "web") {
    Write-Host "Confirmed TYPE is '$TYPE'. Proceeding with Ionic build."
    # --- 2. Build the Ionic application locally ---
    Write-Host "Running npm build..."
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Error "npm build failed. Exiting."
        Exit 1
    }
}
elseif ($TYPE -eq "python") {
    Write-Host "Confirmed TYPE is 'python'. Proceeding with Python build."
    # --- 2. Build the Python application locally ---
    Write-Host "Running python setup..."
    #python main.py install
    #if ($LASTEXITCODE -ne 0) {
    #    Write-Error "Python setup failed. Exiting."
    #    Exit 1
    #}
}

# --- 3. Ensure Docker Buildx is set up ---
Write-Host "Checking Docker Buildx setup..."
# Use existing builder or create new one
try {
    docker buildx use $BUILDER_NAME || docker buildx create --use --name $BUILDER_NAME --bootstrap
    Write-Host "Docker Buildx setup complete."
} catch {
    Write-Error "Failed to set up Docker Buildx. Make sure Docker Desktop is running."
    Exit 1
}

# --- 4. Login to GitHub Container Registry (GHCR) ---
Write-Host "Logging in to GHCR..."
# Assuming you have a GITHUB_USERNAME and GITHUB_PAT in your .env or environment
if (-not $env:GITHUB_USERNAME -or -not $env:GITHUB_PAT) {
    Write-Error "GITHUB_USERNAME or GITHUB_PAT environment variables are not set. Please set them in your .env file or system."
    Exit 1
}
try {
    echo $env:GITHUB_PAT | docker login ghcr.io -u $env:GITHUB_USERNAME --password-stdin
    Write-Host "Logged in to GHCR successfully."
} catch {
    Write-Error "GHCR login failed. Ensure GITHUB_USERNAME and GITHUB_PAT are correct and the PAT has 'write:packages' scope."
    Exit 1
}

$IMAGE_TAG = Get-Date -Format "yyyyMMddHHmmss"

# --- 5. Build and Push Multi-Architecture Docker Image ---
Write-Host "Building and pushing multi-architecture Docker image to ${DOCKER_IMAGE_NAME_COMPLETE}:${IMAGE_TAG}..."

$platforms = "linux/amd64,linux/arm64/v8" # Target platforms

try {
    docker buildx build --platform $platforms -t "${DOCKER_IMAGE_NAME_COMPLETE}:${IMAGE_TAG}" --push .
    Write-Host "Multi-architecture Docker image pushed successfully."

    # --- 6. Génération de l'injection des variables (Zéro fichier sur VPS) ---
    Write-Host "Préparation de l'export des variables d'environnement..."
    $exportString = ""

    # On récupère le contenu des deux fichiers .env chargés au début
    $envFiles = @($ENV_FILE_PATH)
    foreach ($file in $envFiles) {
        if (Test-Path $file) {
            Get-Content $file | ForEach-Object {
                # On extrait KEY=VALUE en ignorant les commentaires (#)
                if ($_ -match "^\s*([A-Za-z0-9_]+)\s*=\s*(.*)\s*$") {
                    $name = $matches[1]
                    $value = $matches[2]
                    # On ajoute l'export pour Linux (avec guillemets simples pour protéger les valeurs)
                    $exportString += "export $name='$value'; "
                }
            }
        }
    }

    # On assemble la commande finale : Exports + CD + Update Script
    $REMOTE_COMMAND = "$exportString cd EasyDeploy && ./scripts/update.sh $serviceName $DOCKER_IMAGE_NAME_COMPLETE $IMAGE_TAG $DOCKER_COMPOSE_FILE $PROJECT_NAME"

    # --- 7. Exécution via le fichier .bat ---
    if (-not (Test-Path -Path $SSH_BAT_FILE -PathType Leaf)) {
        Write-Error "Error: Le fichier .bat est introuvable à '$SSH_BAT_FILE'."
        Exit 1
    } else {
        Write-Host "Envoi de la commande et des secrets au VPS..." -ForegroundColor Cyan
        & $SSH_BAT_FILE $REMOTE_COMMAND
        Write-Host "✅ Déploiement terminé avec succès." -ForegroundColor Green
    }

    # Copie dans le presse-papier pour debug si besoin
    $REMOTE_COMMAND | Set-Clipboard
    Write-Host "Commande complète copiée dans le presse-papier."

} catch {
    Write-Error "Docker buildx build and push failed."
    Exit 1
}