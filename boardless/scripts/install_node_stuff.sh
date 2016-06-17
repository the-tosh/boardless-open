#!/bin/bash

set -e

DIRECTORY="$(dirname ${BASH_SOURCE[0]})"
INSTALL_PATH=~/boardless_nodejs_tmp

# Install Node.js
sudo dpkg -i nodejs_0.12.7-1_amd64.deb

# Install NPM packages
sudo npm install -g coffee-script@1.9.1 stylus@0.50.0 pegjs@0.9.0