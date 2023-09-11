#!/bin/bash

# Create a Docker volume
docker volume create redis_data

# Start a new Redis container and capture its ID
CONTAINER_ID=$(docker run -e REDIS_ARGS="--save 60 1000 --appendonly yes" -d -p 6379:6379 -v redis_data:/data redis/redis-stack-server:latest)

# Check if the container started successfully
if [ -z "$CONTAINER_ID" ]; then
  echo "Failed to start Redis container."
  exit 1
fi

echo "Started Redis container with ID: $CONTAINER_ID"

# Perform 10 writes
for i in {1..10}
do
  docker exec $CONTAINER_ID redis-cli set key$i value$i
done

# Stop the old container (gracefully, to allow data to be saved)
docker stop $CONTAINER_ID

# Remove the old container
docker rm $CONTAINER_ID

# Start a new container using the same volume for persistent data
NEW_CONTAINER_ID=$(docker run -e REDIS_ARGS="--save 60 1000 --appendonly yes" -d -p 6379:6379 -v redis_data:/data redis/redis-stack-server:latest)

echo "Started new Redis container with ID: $NEW_CONTAINER_ID"

# Verify data by performing 10 reads
for i in {1..10}
do
  VALUE=$(docker exec $NEW_CONTAINER_ID redis-cli get key$i | tr -d '\r')
  echo "key$i: $VALUE"
done

VALUE=$(docker exec $NEW_CONTAINER_ID redis-cli get key | tr -d '\r')
  echo "test: $VALUE"

# Stop the old container (gracefully, to allow data to be saved)
docker stop $NEW_CONTAINER_ID

# Remove the old container
docker rm $NEW_CONTAINER_ID