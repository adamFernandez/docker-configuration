#!/bin/sh

init_time=0
timeout=600  # Adjust the timeout as needed

echo "Waiting for $1 to get ready $2..."
while [ $timeout -gt 0 ]; do
  output=$(docker-compose logs $1)
  if echo "$output" | grep -q "$2"; then
    echo "$1 ready! $(date)"
    exit 0  # Log line found, consider the service healthy
  fi

  printf "Still waiting... ${init_time}s\r"
  sleep 1
  init_time=$(expr $init_time + 1)
done

echo "Timeout reached. Service not ready."
exit 1