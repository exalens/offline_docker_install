#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <distribution_codename> <kernel_os> <architecture>"
    echo "Example: $0 focal Linux x86_64"
    echo "Execute 'lsb_release -cs' for distribution_codename, 'uname -s' for kernel_os, 'uname -m' for architecture"
    exit 1
fi

# Parameters provided by the user
DISTRIBUTION_CODENAME=$1   # Distro codename (e.g., focal)
KERNEL_OS=$2         # OS name (e.g., Linux)
ARCHITECTURE=$3      # Architecture (e.g., x86_64)

# Set up directories
mkdir -p docker-installation/docker-packages

# Clear the docker-packages directory to ensure no unrelated files are present
rm -rf docker-installation/docker-packages/*

# Step 1: Update and install required packages for downloading
echo "Updating system and installing required packages..."
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release jq

# Step 2: Download Docker GPG key
echo "Downloading Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o docker-installation/docker-archive-keyring.gpg
if [ $? -ne 0 ]; then
    echo "Failed to download Docker GPG key."
    exit 1
fi

# Step 3: Create the Docker source list file
echo "Creating Docker APT source list..."
echo "deb [arch=amd64 signed-by=$(pwd)/docker-installation/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $DISTRIBUTION_CODENAME stable" | sudo tee docker-installation/docker.list > /dev/null

# Step 4: Download Docker and dependencies
echo "Downloading Docker and its dependencies..."
sudo apt-get update -o Dir::Etc::sourcelist="$(pwd)/docker-installation/docker.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
if [ $? -ne 0 ]; then
    echo "Failed to update APT with Docker repository."
    exit 1
fi

# Download Docker Engine (docker-ce), Docker CLI, and containerd, and their dependencies
apt-get download docker-ce docker-ce-cli containerd.io
if [ $? -ne 0 ]; then
    echo "Failed to download Docker packages."
    exit 1
fi

# Move the downloaded .deb files to the docker-packages directory
mv *.deb docker-installation/docker-packages/
if [ $? -ne 0 ]; then
    echo "Failed to move downloaded .deb files to docker-installation/docker-packages/"
    exit 1
fi

# Step 5: Download Docker Compose
echo "Downloading Docker Compose..."
VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r)
curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$KERNEL_OS-$ARCHITECTURE -o docker-installation/docker-compose
if [ $? -ne 0 ]; then
    echo "Failed to download Docker Compose."
    exit 1
fi
chmod +x docker-installation/docker-compose

# Step 6: Create an archive of all the files
echo "Creating archive..."
tar -czvf docker-installation.tar.gz -C docker-installation .
if [ $? -ne 0 ]; then
    echo "Failed to create archive."
    exit 1
fi

echo "Download and packaging complete. Transfer docker-installation.tar.gz to the air-gapped system."

