# akxr GitOps

A GitOps-managed homelab infrastructure using ArgoCD and Helm charts for deploying media server applications on Kubernetes.

## Overview

This repository contains the GitOps configuration for a personal homelab setup, managing various media server applications through ArgoCD. The infrastructure is designed to be declarative, version-controlled, and automatically synchronized with the Kubernetes cluster.

## Architecture

- **ArgoCD**: GitOps operator for continuous deployment
- **Helm Charts**: Package manager for Kubernetes applications
- **Traefik**: Ingress controller for external access
- **Sealed Secrets**: Encrypted secrets management
- **Let's Encrypt**: Automated SSL certificate provisioning

## Repository Structure

```
akxr-gitops/
├── charts/
│   ├── core/              # Base Helm chart for applications
│   ├── deployment/        # Chart that generates ArgoCD Application resources
│   ├── production/        # Production-specific chart templates
│   └── staging/           # Staging-specific chart templates
├── environments/
│   ├── core/              # Core/production applications
│   │   ├── deployment/    # App list for core environment
│   │   ├── jellyfin/
│   │   ├── sonarr/
│   │   └── ...
│   ├── production/        # Production-specific apps
│   └── staging/           # Staging apps
├── manifests/
│   ├── core.yaml          # Root ArgoCD Application for core environment
│   ├── production.yaml     # Root ArgoCD Application for production
│   ├── staging.yaml        # Root ArgoCD Application for staging
│   └── argocd/            # ArgoCD configuration (certificates, ingress, etc.)
└── secrets/               # Encrypted secrets management
```

### How It Works

1. **Root Applications** (`manifests/*.yaml`): Bootstrap ArgoCD Applications that point to the `charts/deployment` chart
2. **Deployment Chart** (`charts/deployment/`): Generates ArgoCD Application resources for each app defined in environment values
3. **Environment Values** (`environments/{env}/deployment/values.yaml`): Lists all apps for an environment with their chart paths and value files
4. **App Values** (`environments/{env}/{app}/values.yaml`): Application-specific configuration
5. **Core Chart** (`charts/core/`): Base Helm chart that renders Kubernetes resources (Deployment, Service, Ingress, etc.)

## Applications

The following applications are managed through this GitOps setup:

- **Jellyfin**: Media server for streaming movies and TV shows
- **Jellyseerr**: Request management for Jellyfin
- **Sonarr**: TV series management and automation
- **Radarr**: Movie management and automation
- **Prowlarr**: Indexer manager for Sonarr and Radarr
- **qBittorrent**: BitTorrent client
- **FlareSolverr**: Proxy for bypassing Cloudflare protection
- **ntfy**: Push notifications server
- **Docker Registry**: Private container registry

## Prerequisites

- Kubernetes cluster with ArgoCD installed
- kubectl configured to access the cluster
- kubeseal for secret encryption
- Helm 3.x

## Getting Started

This repo is also being used by Students in WAGMI. You can deploy your apps by following these steps:

### 1. Fork the Repository

```bash
git clone https://github.com/your-username/akxr-gitops.git
cd akxr-gitops
```

### 2. Dockerize Your Service

You will have to dockerize your service and push it to DockerHub or another public repository.

### 3. Configure Secrets

Follow the instructions in `secrets/readme.md` to set up encrypted secrets for your applications.

### 4. Add Your Application

To add a new application to an environment:

1. **Create application values file**:
   ```bash
   mkdir -p environments/{core|production|staging}/your-app
   cp environments/staging/example/values.yaml environments/{core|production|staging}/your-app/values.yaml
   ```

2. **Configure your application** in `environments/{env}/your-app/values.yaml`:
   - Update container image and tag (from step 2)
   - Update ingress hosts to match your domain
   - Configure resource limits and requests
   - Set up persistent volumes for data storage
   - Adjust environment-specific settings

3. **Register the app** in `environments/{env}/deployment/values.yaml`:
   ```yaml
   apps:
     - name: your-app
       path: charts/core
       valueFiles:
         - ../../environments/{env}/your-app/values.yaml
   ```

4. **Commit and push** - ArgoCD will automatically sync the changes

### 5. Domain Configuration

Applications are configured to use the `pixr.in` domain with subdomains:
- `tv.pixr.in` - Jellyfin
- `sonarr.pixr.in` - Sonarr
- `radarr.pixr.in` - Radarr
- And more...

Update these domains in the respective `values.yaml` files to match your setup.

Also add your domain to the `manifests/argocd/certificates.yaml` file so that certificates can be issued for your domain.

## Storage

The setup uses hostPath volumes for persistent storage:
- Configuration data: `/home/thisisamank/{app-name}/`
- Media data: `/mnt/hetzner/data/`

Adjust these paths in the application values files to match your storage setup.

## Environments

The repository supports multiple environments:

- **core**: Production media server applications
- **production**: Production-specific applications
- **staging**: Staging/test applications

Each environment has its own ArgoCD Application manifest in `manifests/` and its own app configurations in `environments/`.

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
