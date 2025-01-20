# Charger les variables d'environnement depuis .env
Get-Content .env | ForEach-Object {
    $key, $value = $_ -split '='
    [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
}

docker service create --name evolu-db --env POSTGRES_USER=$env:POSTGRES_USER --env POSTGRES_PASSWORD=$env:POSTGRES_PASSWORD --env POSTGRES_DB=$env:POSTGRES_DB --replicas 1 --limit-memory 512m -p 5432:5432 --network my_network --mount type=bind,source=E:\evolu-data,target=/var/lib/postgresql/data postgres:17.2-alpine

docker service create --name evolu-back --env  DATABASE_URL=$env:DATABASE_URL --replicas 1 --limit-memory 512m -p 8000:8000 --network my_network --mount type=bind,source=E:\logs,target=/logs ghcr.io/gaetanse/evolu-back-image:latest

docker service create --name evolu-front --replicas 1 --limit-memory 512m -p 80:80 --network my_network ghcr.io/gaetanse/evolu-front-image:latest