#!/bin/bash
set -e

# Store the script directory early to ensure we can reference it after changing directories
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set the target directory one level up from the script directory
TARGET_DIR="$(dirname "$SCRIPT_DIR")"


# Early check for /var/log/auth.log file
echo
echo
echo "===== [1/12] Checking auth.log ====="
if [ -f /var/log/auth.log ]; then
  echo ">>> /var/log/auth.log exists as a file. Continuing..."
else
    echo ">>> /var/log/auth.log does not exist as a file. Exiting..."
    exit 1
fi


# Check for required environment files
echo
echo
echo "===== [2/12] Checking for required environment files ====="
MISSING_ENV_FILES=false
ENV_FILES=("stable-api.env" "canary-api.env" "faiss.env" "proxy.env")

for env_file in "${ENV_FILES[@]}"; do
  if [ ! -f "$SCRIPT_DIR/$env_file" ]; then
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


echo
echo
echo "===== [3/12] Updating system ====="
apt update && apt upgrade -y


echo
echo
echo "===== [4/12] Installing dependencies ====="
apt install -y curl git sudo gh


echo
echo
echo "===== [5/12] Installing Docker ====="
sudo bash "$SCRIPT_DIR/docker.sh"


echo
echo
echo "===== [6/12] Authenticating GitHub CLI ====="
if ! gh auth status &>/dev/null; then
  echo ">>> GitHub authentication required"
  echo ">>> Opening browser for authentication..."
  gh auth login
else
  echo ">>> GitHub CLI is already authenticated"
fi


echo
echo
echo "===== [7/12] Cloning repositories ====="
# Clone repositories into the parent directory of the script
cd "$TARGET_DIR"
echo ">>> Target directory: $TARGET_DIR"

# Clone traefik-proxy
if [ ! -d "$TARGET_DIR/traefik-proxy" ]; then
  echo ">>> Cloning traefik-proxy"
  gh repo clone Vettam/traefik-proxy "$TARGET_DIR/traefik-proxy"
else
  echo ">>> traefik-proxy already cloned at $TARGET_DIR/traefik-proxy"
  # Verify directory actually exists
  if [ ! -d "$TARGET_DIR/traefik-proxy" ]; then
    echo ">>> ERROR: Directory $TARGET_DIR/traefik-proxy doesn't exist, recreating"
    gh repo clone Vettam/traefik-proxy "$TARGET_DIR/traefik-proxy"
  fi
fi

# Clone canary API Service
if [ ! -d "$TARGET_DIR/canary" ]; then
  echo ">>> Cloning Vettam_backend into directory 'canary'"
  gh repo clone Vettam/Vettam_backend "$TARGET_DIR/canary"
else
  echo ">>> 'canary' directory already exists at $TARGET_DIR/canary"
  # Verify directory actually exists
  if [ ! -d "$TARGET_DIR/canary" ]; then
    echo ">>> ERROR: Directory $TARGET_DIR/canary doesn't exist, recreating"
    gh repo clone Vettam/Vettam_backend "$TARGET_DIR/canary"
  fi
fi

# Clone stable API Service
if [ ! -d "$TARGET_DIR/stable" ]; then
  echo ">>> Cloning Vettam_backend into directory 'stable'"
  gh repo clone Vettam/Vettam_backend "$TARGET_DIR/stable"
else
  echo ">>> 'stable' directory already exists at $TARGET_DIR/stable"
  # Verify directory actually exists
  if [ ! -d "$TARGET_DIR/stable" ]; then
    echo ">>> ERROR: Directory $TARGET_DIR/stable doesn't exist, recreating"
    gh repo clone Vettam/Vettam_backend "$TARGET_DIR/stable"
  fi
fi

# Clone faiss-service
if [ ! -d "$TARGET_DIR/faiss-service" ]; then
  echo ">>> Cloning faiss-service"
  gh repo clone Vettam/faiss-service "$TARGET_DIR/faiss-service"
else
  echo ">>> faiss-service already cloned at $TARGET_DIR/faiss-service"
  # Verify directory actually exists
  if [ ! -d "$TARGET_DIR/faiss-service" ]; then
    echo ">>> ERROR: Directory $TARGET_DIR/faiss-service doesn't exist, recreating"
    gh repo clone Vettam/faiss-service "$TARGET_DIR/faiss-service"
  fi
fi


echo
echo
echo "===== [8/12] Copying environment files ====="
# Copy stable-api.env to stable directory
echo ">>> Copying stable-api.env to $TARGET_DIR/stable/.env"
cp "$SCRIPT_DIR/stable-api.env" "$TARGET_DIR/stable/.env"

# Copy canary-api.env to canary directory
echo ">>> Copying canary-api.env to $TARGET_DIR/canary/.env"
cp "$SCRIPT_DIR/canary-api.env" "$TARGET_DIR/canary/.env"

# Copy faiss.env to faiss-service directory
echo ">>> Copying faiss.env to $TARGET_DIR/faiss-service/.env"
cp "$SCRIPT_DIR/faiss.env" "$TARGET_DIR/faiss-service/.env"

# Copy proxy.env to traefik-proxy directory
echo ">>> Copying proxy.env to $TARGET_DIR/traefik-proxy/.prod.env"
cp "$SCRIPT_DIR/proxy.env" "$TARGET_DIR/traefik-proxy/.prod.env"

echo
echo
echo "===== [9/12] Setting up docker networks ====="
docker network create shared-network


echo
echo
echo "===== [10/12] Starting Reverse Proxy ====="
cd "$TARGET_DIR/traefik-proxy"
docker compose up -d --build


echo
echo
echo "===== [11/12] Starting backend services ====="
cd "$TARGET_DIR/canary"
git checkout canary
git pull origin canary
docker compose -f docker-compose.canary.yml up --build -d

cd "$TARGET_DIR/stable"
git checkout stable
git pull origin stable
docker compose up --build -d


echo
echo
echo "===== [12/12] Starting FAISS Service ====="
cd "$TARGET_DIR/faiss-service"
docker compose up --build -d


echo
echo
echo "===== Setup complete! Stack is running. ====="
exho
