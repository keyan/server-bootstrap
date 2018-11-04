#!/bin/bash

set -e

SCRIPT_DIR=$(pwd)

# System packages
sudo apt-get update
sudo apt-get install --assume-yes nginx docker docker-compose dnsutils python-minimal python-pip g++ make

# Personal configuration
cd ~
if [ ! -d ~/dotfiles ]; then
    git clone https://github.com/keyan/dotfiles.git
    pushd dotfiles/
    ./install && popd
fi

# Pull any project repos and start the docker-compose applications.
if [ ! -d ~/tonic-time ]; then
    git clone https://github.com/keyan/tonic-time.git
fi

if [ ! -d ~/route_planner ]; then
    git clone https://github.com/keyan/route_planner.git

    # Install and build
    pushd route_planner
    make install
    make build

    # Get map data
    wget https://overpass-api.de/api/map?bbox=-122.4333,47.5077,-122.1667,47.6706
    mv map data/seattle.osm
    perl scripts/osm_stripper.pl data/seattle.osm data/seattle.clean.osm
    popd
fi

cd $SCRIPT_DIR

# Runs the containers in the background
sudo docker-compose up --build -d

# Copy nginx configs and restart to ensure new locations are served.
sudo rm -rf /etc/nginx/sites-enabled/* /etc/nginx/sites-available/*

sudo cp -rf nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp -rf nginx/sites /etc/nginx/sites-available/
sudo ln -sv /etc/nginx/sites-available/sites /etc/nginx/sites-enabled/sites
sudo service nginx restart
