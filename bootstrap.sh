#!/bin/bash

set -e

SCRIPT_DIR=$(pwd)

read -r -p "Install system packages? [y/N] " response
case "$response" in
  [yY])
    # System packages
    sudo apt-get update
    sudo apt-get install --assume-yes nginx docker docker-compose dnsutils python-minimal python-pip g++ make
    ;;
  *)
    ;;
esac

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

    # Move frontend files to NGINX expected static file location
    sudo mkdir -p /var/www/html/route_planner
    sudo rm /var/www/html/route_planner/*
    sudo cp www/* /var/www/html/route_planner

    # Install and build
    pushd route_planner
    sudo make install
    make build

    read -r -p "Reload network graph? [y/N] " response
    case "$response" in
      [yY])
        # Get map data
        wget -O seattle.osm "https://overpass-api.de/api/map?bbox=-122.3824,47.5483,-122.2678,47.6469"
        mv seattle.osm data/
        perl scripts/osm_stripper.pl data/seattle.osm data/seattle.clean.osm && rm data/seattle.osm
        ;;
      *)
        ;;
    esac

    read -r -p "Changes to systemd service? [y/N] " response
    case "$response" in
      [yY])
        sudo rm /etc/systemd/system/route_planner.service
        sudo cp scripts/route_planner.service /etc/systemd/system/route_planner.service
        sudo systemctl daemon-reload
        sudo systemctl restart route_planner.service
        ;;
      *)
        ;;
    esac

    popd
fi

cd $SCRIPT_DIR

read -r -p "Run docker-compose? [y/N] " response
case "$response" in
  [yY])
    # Runs the containers in the background
    sudo docker-compose up --build -d
    ;;
  *)
    ;;
esac

# Copy nginx configs and restart to ensure new locations are served.
sudo rm -rf /etc/nginx/sites-enabled/* /etc/nginx/sites-available/*

sudo cp -rf nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp -rf nginx/sites /etc/nginx/sites-available/
sudo ln -sv /etc/nginx/sites-available/sites /etc/nginx/sites-enabled/sites
sudo service nginx restart
