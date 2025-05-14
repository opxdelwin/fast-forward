#!/bin/bash
set -e

# Early check for /var/log/access.log file
echo "===== [1/11] Checking access.log ====="
if [ -f /var/log/access.log ]; then
  echo ">>> /var/log/access.log exists as a file. Continuing..."
else
    echo ">>> /var/log/access.log does not exist as a file. Exiting..."
    exit 1
fi

# Check for required environment files
echo "===== [2/11] Checking for required environment files ====="
MISSING_ENV_FILES=false
ENV_FILES=("stable-api.env" "canary-api.env" "faiss.env" "proxy.env")

for env_file in "${ENV_FILES[@]}"; do
  if [ ! -f "$env_file" ]; then
    echo ">>> Missing required environment file: $env_file"
    MISSING_ENV_FILES=true
  else
    echo ">>> Found environment file: $env_file"
  fi
done

if [ "$MISSING_ENV_FILES" = true ]; then
  echo "Error: Required environment files are missing. Setup cannot continue."
  exit 1
fi

echo "===== [3/11] Updating system ====="
apt update && apt upgrade -y

echo "===== [4/11] Installing dependencies ====="
apt install -y curl git sudo gh

echo "===== [5/11] Installing Docker ====="
sudo bash docker.sh

echo "===== [6/11] Authenticating GitHub CLI ====="
if ! gh auth status &>/dev/null; then
  echo ">>> GitHub authentication required"
  echo ">>> Opening browser for authentication..."
  gh auth login
else
  echo ">>> GitHub CLI is already authenticated"
fi

echo "===== [7/11] Cloning repositories ====="
# Clone repositories into home directory with custom directory names
cd ~

# Clone traefik-proxy
if [ ! -d "traefik-proxy" ]; then
  echo ">>> Cloning traefik-proxy"
  gh repo clone Vettam/traefik-proxy
else
  echo ">>> traefik-proxy already cloned"
fi

# Clone canary API Service
if [ ! -d "canary" ]; then
  echo ">>> Cloning Vettam_backend into directory 'canary'"
  gh repo clone Vettam/Vettam_backend canary
else
  echo ">>> 'canary' directory already exists"
fi

# Clone stable API Service
if [ ! -d "stable" ]; then
  echo ">>> Cloning Vettam_backend into directory 'stable'"
  gh repo clone Vettam/Vettam_backend stable
else
  echo ">>> 'stable' directory already exists"
fi

# Clone faiss-service
if [ ! -d "faiss-service" ]; then
  echo ">>> Cloning faiss-service"
  gh repo clone Vettam/faiss-service
else
  echo ">>> faiss-service already cloned"
fi

echo "===== [8/11] Copying environment files ====="
# Store the current script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Copy stable-api.env to stable directory
echo ">>> Copying stable-api.env to ~/stable/.env"
cp "$SCRIPT_DIR/stable-api.env" ~/stable/.env

# Copy canary-api.env to canary directory
echo ">>> Copying canary-api.env to ~/canary/.env"
cp "$SCRIPT_DIR/canary-api.env" ~/canary/.env

# Copy faiss.env to faiss-service directory
echo ">>> Copying faiss.env to ~/faiss-service/.env"
cp "$SCRIPT_DIR/faiss.env" ~/faiss-service/.env

# Copy proxy.env to traefik-proxy directory
echo ">>> Copying proxy.env to ~/traefik-proxy/.prod.env"
cp "$SCRIPT_DIR/proxy.env" ~/faiss-service/.prod.env

echo "===== [9/11] Starting Reverse Proxy ====="
# cd ~/traefik-proxy
# docker compose up -d

echo "===== [10/11] Starting backend services ====="
# cd ~/canary
# git checkout canary
# git pull origin canary
# docker compose -f docker-compose.canary.yml up --build -d

# cd ~/stable
# git checkout stable
# git pull origin stable
# docker compose up --build -d

echo "===== [11/11] Starting FAISS Service ====="
# cd ~/faiss-service
# docker compose up --build -d

echo "===== Setup complete! Stack is running. ====="
