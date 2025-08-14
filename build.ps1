# --- Configuration ---
$STACK_NAME = ""
$SERVICE_NAME = ""
$DOCKER_REPO = ""
$DOCKER_IMAGE_NAME = "$DOCKER_REPO/$SERVICE_NAME"
$IMAGE_TAG = git log -1 --pretty=format:%H # Récupérez le dernier commit hash pour l'ensemble du dépôt
$envFilePath = ".\$SERVICE_NAME.env"
$BASE_HREF = "/"
$BUILDER_NAME = ""

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

# --- 5. Build and Push Multi-Architecture Docker Image ---
Write-Host "Building and pushing multi-architecture Docker image to ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}..."

$platforms = "linux/amd64,linux/arm64/v8" # Target platforms

try {
    # Pass the array of arguments using @() to ensure they are treated as separate arguments
    docker buildx build --platform $platforms -t "${DOCKER_IMAGE_NAME}:${IMAGE_TAG}" --push .
    Write-Host "Multi-architecture Docker image pushed successfully to ${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
    Write-Host "scripts/update.sh $STACK_NAME $SERVICE_NAME $DOCKER_IMAGE_NAME $IMAGE_TAG"
} catch {
    Write-Error "Docker buildx build and push failed. Check error messages above."
    Exit 1
}