#!/bin/bash

# Step 1: Extract the archive
INSTALL_DIR=~/docker-installation
mkdir -p "$INSTALL_DIR"
echo "Extracting docker-installation.tar.gz to $INSTALL_DIR..."
tar -xzvf docker-installation.tar.gz -C "$INSTALL_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to extract docker-installation.tar.gz"
    exit 1
fi

# Step 2: Copy the GPG key and Docker APT source list
echo "Copying GPG key and Docker APT source list..."
sudo cp "$INSTALL_DIR/docker-archive-keyring.gpg" /usr/share/keyrings/
if [ $? -ne 0 ]; then
    echo "Failed to copy GPG key to /usr/share/keyrings/"
    exit 1
fi

sudo cp "$INSTALL_DIR/docker.list" /etc/apt/sources.list.d/
if [ $? -ne 0 ]; then
    echo "Failed to copy Docker source list to /etc/apt/sources.list.d/"
    exit 1
fi

# Step 3: Install Docker packages using dpkg
echo "Installing Docker packages..."
sudo dpkg -i "$INSTALL_DIR/docker-packages/"*.deb
if [ $? -ne 0 ]; then
    echo "Error occurred during the installation of Docker packages. Trying to fix missing dependencies..."
    sudo apt-get -f install -y
    if [ $? -ne 0 ]; then
        echo "Failed to fix missing dependencies."
        exit 1
    fi
fi

# Step 4: Move the Docker Compose binary to a directory in the PATH and make it executable
echo "Installing Docker Compose..."
sudo mv "$INSTALL_DIR/docker-compose" /usr/local/bin/docker-compose
if [ $? -ne 0 ]; then
    echo "Failed to move Docker Compose to /usr/local/bin/"
    exit 1
fi

sudo chmod +x /usr/local/bin/docker-compose
if [ $? -ne 0 ]; then
    echo "Failed to make Docker Compose executable."
    exit 1
fi

# Step 5: Add the current user to the Docker group
echo "Adding the current user to the Docker group..."
sudo groupadd docker | true
sudo usermod -aG docker $USER
if [ $? -ne 0 ]; then
    echo "Failed to add the user to the Docker group."
    exit 1
fi

# Step 6: Start Docker service
echo "Starting Docker service..."
sudo systemctl start docker
if [ $? -ne 0 ]; then
    echo "Failed to start Docker service."
    exit 1
fi

sudo systemctl enable docker
if [ $? -ne 0 ]; then
    echo "Failed to enable Docker service to start on boot."
    exit 1
fi

# Step 7: Inform the user to log out and log back in
echo "Docker and Docker Compose installed successfully."
echo "Please log out and log back in or reboot your system for the group changes to take effect."

