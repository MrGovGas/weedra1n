#!/var/jb/bin/sh

printf "Types: deb\nURIs: https://mineek.github.io/repo/\nSuites: ./\nComponents:\n\nTypes: deb\nURIs: https://repo.palera.in/\nSuites: ./\nComponents:\n" > /var/jb/etc/apt/sources.list.d/procursus.sources
apt update --allow-insecure-repositories
apt remove sudo --allow-remove-essential -y
apt install sudoworking --allow-unauthenticated -y
apt install libiosexec1 --allow-unauthenticated -y
apt upgrade --allow-unauthenticated -y
