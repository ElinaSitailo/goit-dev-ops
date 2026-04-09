#!/bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[✔] $1${NC}"; }
skip() { echo -e "${YELLOW}[~] $1 — already installed${NC}"; }
err()  { echo -e "${RED}[✘] $1${NC}"; }

echo "-------------------------------------------------------------------"
echo "              Dev tools setup on Ubuntu 24.04.1 LTS"
echo "-------------------------------------------------------------------"


echo "-------------------------------------------------------------------"
echo "              Docker setup"
echo "              https://docs.docker.com/engine/install/ubuntu/"
echo "-------------------------------------------------------------------"

if command -v docker &>/dev/null; then # Check if Docker is already installed
    skip "Installed Docker ($(docker --version))" # If installed, skip installation and show version
else
    echo "[*] Installing Docker..."
    sudo apt-get update -y # Update package index
    sudo apt-get install -y ca-certificates curl # Install prerequisites
    sudo install -m 0755 -d /etc/apt/keyrings # Create keyrings directory
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc

    # Ensure the keyring file is readable by all users    
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository to APT sources
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
        https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y # Update package index
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io # Install Docker Engine
    sudo systemctl enable --now docker # Enable and start Docker service
    sudo usermod -aG docker "$USER" # Add current user to docker group for non-sudo usage
    ok "Docker installed ($(docker --version))" # Display installed Docker version
fi

echo "-------------------------------------------------------------------"
echo "              Docker Compose setup"
echo "              https://docs.docker.com/desktop/setup/install/linux/ubuntu/"
echo "-------------------------------------------------------------------"

if docker compose version &>/dev/null 2>&1; then
    skip "Installed Docker Compose ($(docker compose version))"
else
    echo "[*] Installing Docker Compose..."
    sudo apt-get install -y docker-compose-plugin # Install Docker Compose plugin
    ok "Docker Compose installed ($(docker compose version))"
fi

echo "-------------------------------------------------------------------"
echo "              Python setup"
echo "-------------------------------------------------------------------"

if python3 --version 2>/dev/null | grep -qE "3\.(9|[1-9][0-9])"; then
    skip "Installed Python ($(python3 --version))"
else
    echo "[*] Start Python installation..."
    sudo apt-get install -y python3 python3-pip python3-venv # Install Python 3 and related tools
    ok "Python installed ($(python3 --version))"
fi

echo "-------------------------------------------------------------------"
echo "              Django setup using pip3"
echo "-------------------------------------------------------------------"

if python3 -c "import django" &>/dev/null; then
    skip "Installed Django ($(python3 -c 'import django; print(django.get_version())'))"
else
    echo "[*] Start Django installation..."
    pip3 install django --break-system-packages # Install Django using pip3, allowing installation outside of virtual environments
    ok "Django installed ($(python3 -c 'import django; print(django.get_version())'))"
fi

echo "-------------------------------------------------------------------"
echo -e "${GREEN}DEV TOOLS VERSIONS:${NC}"
echo "  $(docker --version)"
echo "  $(docker compose version)"
echo "  $(python3 --version)"
echo "  Django $(python3 -c 'import django; print(django.get_version())')"
echo "-------------------------------------------------------------------"
echo -e "${YELLOW}Warning: execute 'newgrp docker' to apply Docker group changes${NC}"
