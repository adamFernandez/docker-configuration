#!/bin/bash

front_type=$([ -d "frontend" ] && echo "frontend" || echo "astro")
package=$( [ -f "$front_type/yarn.lock" ] && echo "yarn" || ( [ -f "$front_type/pnpm-lock.yaml" ] && echo "pnpm" || echo "No package lock file found" ) )

mkdir -p ./config-files/get/logs

echo "$front_type" > ./config-files/get/logs/frontend-folder.txt
echo "$package" > ./config-files/get/logs/package.txt

export front_type package
