# PowerShell script to stop and remove all Docker services
docker service ls --format "{{.Name}}" | ForEach-Object {
    $service = $_
    Write-Host "Stopping and removing service: $service"
    docker service scale "$service=0"  # Corrected line
    docker service rm "$service"
}
