# Default value for the service name
$NAME = "default_name"

# Parse the arguments
param (
    [string]$n
)

# Override the default name if provided
if ($n) {
    $NAME = $n
}

# Display the service name
Write-Host "Scaling down and removing service: $NAME" -ForegroundColor Yellow

# Scale down the service
docker service scale "$NAME"=0 | Out-Null

Write-Host "Service $NAME has been scaled down to 0 and removed." -ForegroundColor Green