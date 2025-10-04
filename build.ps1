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

    # --- 2. Build the Ionic application locally ---
    Write-Host "Running npm build..."
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Error "npm build failed. Exiting."
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

$IMAGE_TAG = Get-Date -Format "yyyyMMddHHmmss"

# --- 5. Build and Push Multi-Architecture Docker Image ---
Write-Host "Building and pushing multi-architecture Docker image to ${DOCKER_IMAGE_NAME_COMPLETE}:${IMAGE_TAG}..."

$platforms = "linux/amd64,linux/arm64/v8" # Target platforms

try {
    # Pass the array of arguments using @() to ensure they are treated as separate arguments
    docker buildx build --platform $platforms -t "${DOCKER_IMAGE_NAME_COMPLETE}:${IMAGE_TAG}" --push .
    Write-Host "Multi-architecture Docker image pushed successfully to ${DOCKER_IMAGE_NAME_COMPLETE}:${IMAGE_TAG}"
    
    # Check if the .bat file exists
    if (-not (Test-Path -Path $SSH_BAT_FILE -PathType Leaf)) {
        Write-Error "Error: The .bat file was not found at '$SSH_BAT_FILE'. Cannot execute remote command."
        Exit 1
    } else {
        # Execute the .bat file and pass the variables as a single argument
        # The script will wait for the bat file to complete
        & $SSH_BAT_FILE $SSH_COMMAND

        Write-Host "Executed remote command successfully."
    }

    # Write the command to the host AND copy it to the clipboard
    Write-Host "Command copied to clipboard: $SSH_COMMAND"
    $SSH_COMMAND | Set-Clipboard
} catch {
    Write-Error "Docker buildx build and push failed. Check error messages above."
    Exit 1
}