# Fast-Forward Deployment Tool

A deployment automation tool for the Vettam service stack that sets up the environment, configures dependencies, and launches the required services.

## Overview

This tool automates the deployment of the Vettam stack, including:

- Traefik reverse proxy
- Stable API service
- Canary API service 
- FAISS vector search service

## Prerequisites

- Ubuntu-based operating system
- Root/sudo access
- Internet connectivity
- The following environment files in the project directory:
  - `stable-api.env`
  - `canary-api.env`
  - `faiss.env`
  - `proxy.env`
- Access to the Vettam GitHub repositories

## Files

- `setup.sh` - Main deployment script
- `docker.sh` - Docker installation script
- `.gitattributes` - Git configuration file

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/Vettam/fast-forward.git
   cd fast-forward
   ```

