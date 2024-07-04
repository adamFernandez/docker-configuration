#!/bin/bash

SERVICE=$1
MIN_PORT=$2
MAX_PORT=$3

# Generate a random port within the specified range
PORT=$(awk -v min=$MIN_PORT -v max=$MAX_PORT 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')

# Check if the port is in use
while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null; do
  PORT=$(awk -v min=$MIN_PORT -v max=$MAX_PORT 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
done

echo $PORT