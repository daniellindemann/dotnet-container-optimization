# Demos

## Application Configuration

- Show `Program.cs`
- Show configurations
    - Logging
    - Options configuration
    - Health probes
- Explain how to add default docker files
    - VS Code > Open command palette > `Docker: Add Docker Files to Workspace...`
- Show [`Dockerfile.default`](src/DotnetContainerOptimization.SampleApp/Dockerfile.default)
    - Explain multi-stage build
    - Explain what happens
- Build and run the default docker container image
    - Build:

        ```bash
        docker build -t sample-app:1.0.0 -t sample-app:latest -f src/DotnetContainerOptimization.SampleApp/Dockerfile.default src/DotnetContainerOptimization.SampleApp
        ```

        > See [scripts/docker/docker-build-default.sh](scripts/docker/docker-build-default.sh)
    - Run:

        ```bash
        docker run --rm -it -p 5108:5108 sample-app:1.0.0
        ```

- Show running
    - Open <http://localhost:5108/hello>
- Update configuration via environment variables
    - Run:

        ```bash
        docker run --rm -it -p 5108:5108 -e Greetings__To=guys sample-app:1.0.0
        ```

- Update application host config (kestrel)
    - Run:

        ```bash
        docker run --rm -it -p 5108:8222 -e ASPNETCORE_URLS=http://+:8222 -e Greetings__To='old grumpy cat' sample-app:1.0.0
        ```

    - See <https://learn.microsoft.com/en-us/aspnet/core/fundamentals/host/web-host?view=aspnetcore-7.0#server-urls>

## Minimize container size

- Compare [`Dockerfile.default`](src/DotnetContainerOptimization.SampleApp/Dockerfile.default) with [`Dockerfile.alpine`](src/DotnetContainerOptimization.SampleApp/Dockerfile.alpine)
    - Show differences
- Build [`Dockerfile.default`](src/DotnetContainerOptimization.SampleApp/Dockerfile.default)
    - Build:
    
        ```bash
        docker build -t sample-app:1.0.0 -t sample-app:latest -f src/DotnetContainerOptimization.SampleApp/Dockerfile.default src/DotnetContainerOptimization.SampleApp
        ```

        > See [scripts/docker/docker-build-default.sh](scripts/docker/docker-build-default.sh)
- Build [`Dockerfile.alpine`](src/DotnetContainerOptimization.SampleApp/Dockerfile.alpine)
    - Build:

        ```bash
        docker build -t sample-app-alpine:1.0.0 -t sample-app-alpine:latest -f src/DotnetContainerOptimization.SampleApp/Dockerfile.alpine src/DotnetContainerOptimization.SampleApp
        ```

        > See [scripts/docker/docker-build-apline.sh](scripts/docker/docker-build-alpine.sh)
- Show size difference
    - Run

        ```bash
        docker images | grep sample-app
        ```

- Show more minimized self-contained image [Dockerfile.self-contained](src/DotnetContainerOptimization.SampleApp/Dockerfile.self-contained)
    - Explain the dockerfile
    - Build:

        ```bash
        docker build -t sample-app-self-contained:1.0.0 -t sample-app-self-contained:latest -f src/DotnetContainerOptimization.SampleApp/Dockerfile.self-contained src/DotnetContainerOptimization.SampleApp
        ```

        > See [scripts/docker/docker-build-self-contained.sh](scripts/docker/docker-build-self-contained.sh)
    - Show size differences
        - `docker images | grep sample-app`
    - Run:

        ```bash
        docker run --rm -it -p 5108:5108 sample-app-self-contained:1.0.0
        ```

## Image best practices

- Show best practice errors of [`dockerfile.alpine`](src/DotnetContainerOptimization.SampleApp/Dockerfile.alpine)
    - Run:

        ```bash
        dockle sample-app-alpine:1.0.0
        ```

- Remove findings
    - Enable docker content trust

        ```bash
        export DOCKER_CONTENT_TRUST=1
        ```

    - Add `HEALTHCEHCK` to [`dockerfile.alpine`](src/DotnetContainerOptimization.SampleApp/Dockerfile.alpine) and explain
- Build image again
- Run dockle again

---

## Non-root user

- Run application as non-root
    - Show user creation in [`dockerfile.alpine`](src/DotnetContainerOptimization.SampleApp/Dockerfile.alpine)

## Vulnerability checks

- Run `trivy` against default image
    - Run:
        ```bash
        trivy image sample-app:1.0.0
        ```
        > See [scripts/trivy/trivy-image-default.sh](scripts/trivy/trivy-image-default.sh)
    - Explain erros
- Run `trivy` with severity `HIGH` and `CRITICAL`
    - Run:
        ```bash
        trivy image sample-app:1.0.0 --severity HIGH,CRITICAL
        ```
        > See [scripts/trivy/trivy-image-default-severity.sh](scripts/trivy/trivy-image-default-severity.sh)
- Show image without any high or critical CVE
    - Run:
        ```bash
        trivy image sample-app-alpine:1.0.0 --severity HIGH,CRITICAL
        ```
        > See [scripts/trivy/trivy-image-alpine-severity.sh](scripts/trivy/trivy-image-alpine-severity.sh)

## Sign images

- Ensure local registry is running
- Run and explain scripts

    1. add image to registry

        ```bash
        ./notation-add-image-to-local-registry.sh
        ```

    2. Generate a test key and self-signed certificate

        ```bash
        ./notation-create-cert-self-signed.sh
        ```

    3. Verify container image

        ```bash
        ./notation-sign-image.sh
        ```

    4. Create a trust policy to verify against

        ```bash
        notation-import-trust-policy.sh
        ```

    5. Verify the image

        ```bash
        ./notation-verify-image.sh
        ```

- (Optional) Show image signing and verification with Azure Key Vault and Azure Container Registry
    - Ensure required Azure infra
        - Run [`azuredeploy.sh`](infra/azuredeploy.sh)
    - Explain [`notation-azure-keyvault-sign-image.sh`](scripts/notation-azure-keyvault/notation-azure-keyvault-sign-image.sh)
    - Run [`notation-azure-keyvault-sign-image.sh`](scripts/notation-azure-keyvault/notation-azure-keyvault-sign-image.sh)

---

# Build Multi-arch image

- Create Builder

    ```bash
    docker buildx create --name mybuilder --platform linux/amd64,linux/arm64 --use
    ```

- Check the new builder

    ```bash
    docker buildx inspect
    ```

- Build multi-arch image from [`Dockerfile.default-multi-arch`](src/DotnetContainerOptimization.SampleApp/Dockerfile.default-multi-arch)

    ```bash
    docker buildx build --platform linux/amd64,linux/arm64 -t sample-app:1.0.0 -f ./src/DotnetContainerOptimization.SampleApp/Dockerfile.default-multi-arch ./src/DotnetContainerOptimization.SampleApp
    ```

    > See ['docker-build-default-multi-arch.sh'](scripts/docker/docker-build-default-multi-arch.sh)

- Build and push to ACR
    - Ensure required Azure infra
        - Run [`azuredeploy.sh`](infra/azuredeploy.sh)
    - Login to acr

        ```bash
        az acr login -n <acr name>
        ```
    
    - Build and push

        ```bash
        docker buildx build --platform linux/amd64,linux/arm64 \
        -t <acr url>/sample-app:1.0.0 \
        --push \
        -f ./src/DotnetContainerOptimization.SampleApp/Dockerfile.default-multi-arch ./src/DotnetContainerOptimization.SampleApp
        ```
    
    - Check the manifest with multi-arch details in manifest
