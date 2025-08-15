# Définir le chemin du fichier de données
$dataPath = ".\EasyDeploy\data.psd1"

# Vérifier si le fichier de données existe
if (-not (Test-Path -Path $dataPath)) {
    Write-Error "Erreur : Le fichier de données '$dataPath' est introuvable."
    exit 1
}

# Importer les données
$data = Import-PowerShellDataFile -Path $dataPath

# Définir la liste des variables obligatoires
$requiredVariables = @("STACK_NAME", "SERVICE_NAME", "DOCKER_REPO", "DOCKER_IMAGE_NAME", "ENV_FILE_PATH", "BASE_HREF", "BUILDER_NAME")

# Vérifier la présence de chaque variable obligatoire
foreach ($variable in $requiredVariables) {
    if (-not $data.ContainsKey($variable)) {
        Write-Error "Erreur : La variable '$variable' est manquante dans le fichier de données '$dataPath'."
        exit 1
    }
}

# Affecter les valeurs importées à vos variables
$STACK_NAME = $data.STACK_NAME
$SERVICE_NAME = $data.SERVICE_NAME
$DOCKER_REPO = $data.DOCKER_REPO
$DOCKER_IMAGE_NAME = $data.DOCKER_IMAGE_NAME
$ENV_FILE_PATH = $data.ENV_FILE_PATH
$BASE_HREF = $data.BASE_HREF
$BUILDER_NAME = $data.BUILDER_NAME

$DOCKER_IMAGE_NAME_COMPLETE = "$DOCKER_REPO/$DOCKER_IMAGE_NAME"

# --- 1. Load environment variables from .env file ---
Write-Host "Loading environment variables from .env file..."
if (Test-Path $ENV_FILE_PATH) {
    Get-Content $ENV_FILE_PATH | ForEach-Object {
        if ($_ -match "^\s*([A-Za-z0-9_]+)\s*=\s*(.*)\s*$") {
            $envName = $matches[1]
            $envValue = $matches[2]
            # Set for the current process, accessible by subsequent commands
            [System.Environment]::SetEnvironmentVariable($envName, $envValue, [System.EnvironmentVariableTarget]::Process)
            Write-Host "  - Loaded $envName"
        }
    }
} else {
    Write-Error "Error: .env file not found at $ENV_FILE_PATH"
    Exit 1
}

# --- 2. Build the Ionic application locally with correct base HREF ---
Write-Host "Running Ionic production build locally with a base HREF of '/'..."
# Nous utilisons --base-href / pour forcer l'application à charger toutes ses ressources depuis la racine du domaine
#npx ionic build --prod --base-href /observation/
ng build --output-path www --base-href $BASE_HREF
if ($LASTEXITCODE -ne 0) {
    Write-Error "Ionic build failed. Exiting."
    Exit 1
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

$IMAGE_TAG = git log -1 --pretty=format:%H # Récupérez le dernier commit hash pour l'ensemble du dépôt

# --- 5. Build and Push Multi-Architecture Docker Image ---
Write-Host "Building and pushing multi-architecture Docker image to ${DOCKER_IMAGE_NAME_COMPLETE}:${IMAGE_TAG}..."

$platforms = "linux/amd64,linux/arm64/v8" # Target platforms

try {
    # Pass the array of arguments using @() to ensure they are treated as separate arguments
    docker buildx build --platform $platforms -t "${DOCKER_IMAGE_NAME_COMPLETE}:${IMAGE_TAG}" --push .
    Write-Host "Multi-architecture Docker image pushed successfully to ${DOCKER_IMAGE_NAME_COMPLETE}:${IMAGE_TAG}"
    Write-Host "scripts/update.sh $STACK_NAME $SERVICE_NAME $DOCKER_IMAGE_NAME_COMPLETE $IMAGE_TAG"
} catch {
    Write-Error "Docker buildx build and push failed. Check error messages above."
    Exit 1
}