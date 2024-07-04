#!/bin/bash

# Black=\033[30m
# Red=\033[31m
# Green=\033[32m
# Yellow=\033[33m
# Blue=\033[34m
# Magenta=\033[35m
# Cyan=\033[36m
# White=\033[37m
nc='\033[0m'

# '\033[30m' '\033[31m' '\033[32m' '\033[33m' '\033[34m' '\033[35m' '\033[36m' '\033[37m' 

colours=('\033[31;1m' '\033[32;1m' '\033[33;1m' '\033[34;1m' '\033[35;1m' '\033[36;1m')
random_colour=$((RANDOM % ${#colours[@]}))

text=$1

echo "${colours[$random_colour]}${text}${nc}"
# echo "Random colour: ${colours[$random_colour]}color${nc} "

