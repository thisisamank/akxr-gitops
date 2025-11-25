# Nexus GitOps

A GitOps-managed homelab infrastructure using ArgoCD and Helm charts for deploying media server applications on Kubernetes.

## Overview

This repository contains the GitOps configuration for a personal homelab setup, managing various media server applications through ArgoCD. The infrastructure is designed to be declarative, version-controlled, and automatically synchronized with the Kubernetes cluster.

## Architecture

- **ArgoCD**: GitOps operator for continuous deployment
- **Helm Charts**: Package manager for Kubernetes applications
- **Traefik**: Ingress controller for external access
- **Sealed Secrets**: Encrypted secrets management
- **Let's Encrypt**: Automated SSL certificate provisioning

## Applications

The following applications are managed through this GitOps setup:

- **Jellyfin**: Media server for streaming movies and TV shows
- **Jellyseerr**: Request management for Jellyfin
- **Sonarr**: TV series management and automation
- **Radarr**: Movie management and automation
- **Prowlarr**: Indexer manager for Sonarr and Radarr
- **qBittorrent**: BitTorrent client
- **FlareSolverr**: Proxy for bypassing Cloudflare protection
- **FileBrowser**: Web-based file manager

## Prerequisites

- Kubernetes cluster with ArgoCD installed
- kubectl configured to access the cluster
- kubeseal for secret encryption
- Helm 3.x

## Getting Started

This repo is also being used by Students in WAGMI. You can deploy your apps by following these steps

### 1. Fork the Repository

```bash
git clone https://github.com/your-username/nexus-gitops.git
cd nexus-gitops
```

### 2. Dockerize your service

You will have to dockerize your service and push it dockerhub or other public repository.

### 3. Configure Secrets

Follow the instructions in `secrets/readme.md` to set up encrypted secrets for your applications.

### 4. Customize Applications

Edit the values files in the `apps/` directory to customize application configurations:

- Update Container image and tag you created in step-2
- Update ingress hosts to match your domain
- Configure resource limits and requests
- Set up persistent volumes for data storage
- Adjust environment-specific settings

## Domain Configuration

Applications are configured to use the `pixr.in` domain with subdomains:
- `tv.pixr.in` - Jellyfin
- `sonarr.pixr.in` - Sonarr
- `radarr.pixr.in` - Radarr
- And more...

Update these domains in the respective `values.yaml` files to match your setup.

also add your domain to the manifests/certificiate.yaml file so that certificate can be issued for your domain.

## Storage

The setup uses hostPath volumes for persistent storage:
- Configuration data: `/home/thisisamank/{app-name}/`
- Media data: `/mnt/hetzner/data/`

Adjust these paths in the application values files to match your storage setup.

## Security

- Secrets are encrypted using Sealed Secrets
- SSL certificates are automatically managed via Let's Encrypt
- Applications run with non-root user contexts where supported

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the configuration
5. Submit a pull request

## License

This project is for personal use. Please ensure you comply with the licenses of the applications being deployed.
