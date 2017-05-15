#!/bin/bash

set -e

SCRIPT_DIR=$(pwd)

# System packages
sudo apt-get update
sudo apt-get install --assume-yes nginx docker docker-compose dnsutils python-minimal python-pip

# Personal configuration
cd ~
if [ ! -d ~/dotfiles ]; then
    git clone https://github.com/keyan/dotfiles.git
fi
pushd dotfiles/
./install && popd

# Pull any project repos and start the docker-compose applications.
if [ ! -d ~/tonic-time ]; then
    git clone https://github.com/keyan/tonic-time.git
fi

cd $SCRIPT_DIR
# Runs the containers in the background
sudo docker-compose up --build -d

# Copy nginx configs and restart to ensure new locations are served.
cp -rf nginx/nginx.conf /etc/nginx/nginx.conf
cp -rf nginx/sites-available/routes /etc/nginx/sites-available/routes
sudo service nginx restart
