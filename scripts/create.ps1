# Set the base directory and .env file path
$BaseDir = Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)
$EnvFile = Join-Path $BaseDir ".env"

# Load environment variables from the .env file
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match "^(.*?)=(.*)$") {
            $Name = $Matches[1]
            $Value = $Matches[2]
            [System.Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::Process)
        }
    }
} else {
    Write-Host "Error: .env file not found in $BaseDir" -ForegroundColor Red
    exit 1
}

# Default values
$Replicas = 1
$Memory = "512m"
$Port = 80
$Network = "default_network"
$Name = "default_name"
$Type = ""
$EnvVars = @()
$Mounts = @()

# Parse arguments
param (
    [string]$r,
    [string]$me,
    [int]$p,
    [string]$net,
    [string]$nam,
    [string]$type,
    [string[]]$e,
    [string[]]$mo
)

if ($r) { $Replicas = $r }
if ($me) { $Memory = "${me}m" }
if ($p) { $Port = $p }
if ($net) { $Network = $net }
if ($nam) { $Name = $nam }
if ($type) { $Type = $type }
if ($e) { $EnvVars = $e }
if ($mo) { $Mounts = $mo }

# Create options for environment variables
$EnvOpts = @()
foreach ($EnvVar in $EnvVars) {
    $EnvOpts += "--env $EnvVar"
}

# Create options for mounts
$MountOpts = @()
foreach ($Mount in $Mounts) {
    $MountOpts += "--mount type=bind,source=$Mount,target=$Mount"
}

# Pull the image and create the Docker service
if ($Type) {
    docker pull $Type
    Write-Host "Creating service $Name with external image $Type on network $Network" -ForegroundColor Green
    docker service create `
        --name $Name `
        --replicas $Replicas `
        --limit-memory $Memory `
        --network $Network `
        -p "$Port:$Port" `
        $EnvOpts `
        $MountOpts `
        $Type
} else {
    $CustomImage = "ghcr.io/gaetanse/${Name}-image:latest"
    docker pull $CustomImage
    Write-Host "Creating service $Name with custom image $CustomImage on network $Network" -ForegroundColor Green
    docker service create `
        --name $Name `
        --replicas $Replicas `
        --limit-memory $Memory `
        --network $Network `
        -p "$Port:$Port" `
        $EnvOpts `
        $MountOpts `
        $CustomImage
}
