# .NET Container Optimization

This project shows how .NET applications can be optimized to run inside containers and container environments. It also shows best practices to optimize and build container images.

## Presentation

TODO

## Prerequisites

- Docker
- .NET 7.0

## Setup

### Option 1

Everything runs in a dev container. Open it with Visual Studio Code. You can now execute all scripts and tools.

### Option 2

- Install Tools
    - Dockle (<https://github.com/goodwithtech/dockle>)
    - Trivy (<https://github.com/aquasecurity/trivy>)
    - Notation (<https://github.com/notaryproject/notation>)
    - Notation AKV Plugin (<https://github.com/Azure/notation-azure-kv>)
- Run local container registry
    - `docker run -d -p 5001:5000 -e REGISTRY_STORAGE_DELETE_ENABLED=true --name registry registry`
## Demos

[View Demos](Demos.md)
