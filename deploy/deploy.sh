#!/bin/sh
set -e

IMAGE="ghcr.io/thibaultdiguet/taskboard:latest"
CONTAINER="taskboard-app"
NETWORK="taskboard_default"

echo "Pulling image..."
docker pull "$IMAGE"

echo "Stopping existing container..."
docker stop "$CONTAINER" 2>/dev/null || true
docker rm "$CONTAINER" 2>/dev/null || true

echo "Starting new container..."
docker run -d \
  --name "$CONTAINER" \
  --network "$NETWORK" \
  -p 3000:3000 \
  -e DATABASE_URL="postgresql://taskboard:taskboard123@db:5432/taskboard" \
  -e JWT_SECRET="${JWT_SECRET:-change-me-in-production}" \
  "$IMAGE"

echo "Running healthcheck..."
for i in $(seq 1 10); do
  sleep 3
  if wget -qO- http://localhost:3000/health > /dev/null 2>&1; then
    echo "Healthcheck OK"
    exit 0
  fi
  echo "Attempt $i/10 failed, retrying..."
done

echo "Healthcheck failed after 10 attempts"
exit 1
