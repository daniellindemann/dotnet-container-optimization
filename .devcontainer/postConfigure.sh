#!/bin/bash

IS_ARM=$(if [[ $(uname -m) == 'aarch64' || $(uname -m) == "amd64" ]]; then echo true; else echo false; fi)

# install dockle
echo "--- Install dockle ---"
DOCKLE_DOWNLOAD_FILE_SUFFIX=$(if [[ $IS_ARM = true ]]; then echo 'Linux-ARM64'; else echo 'Linux-64bit'; fi)
DOCKLE_VERSION=$(
 curl --silent "https://api.github.com/repos/goodwithtech/dockle/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
) && curl -L -o dockle.deb "https://github.com/goodwithtech/dockle/releases/download/v${DOCKLE_VERSION}/dockle_${DOCKLE_VERSION}_${DOCKLE_DOWNLOAD_FILE_SUFFIX}.deb"
sudo dpkg -i dockle.deb && rm dockle.deb
echo ""

# install hadolint
echo "--- Install hadolint ---"
HADOLINT_DOWNLOAD_FILE_SUFFIX=$(if [[ $IS_ARM = true ]]; then echo 'Linux-arm64'; else echo 'Linux-x86_64'; fi)
HADOLINT_VERSION=$(
 curl --silent "https://api.github.com/repos/hadolint/hadolint/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
) && curl -L -o hadolint "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-${HADOLINT_DOWNLOAD_FILE_SUFFIX}" && chmod +x ./hadolint
sudo mv ./hadolint /usr/local/bin
echo ""

# install trivy
echo "--- Install trivy ---"
TRIVY_VERSION=$(
 curl --silent "https://api.github.com/repos/aquasecurity/trivy/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
)
curl -sfL -o trivy_install.sh https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh && chmod +x ./trivy_install.sh
sudo ./trivy_install.sh -b /usr/local/bin v$TRIVY_VERSION
rm ./trivy_install.sh
echo ""

# install notation cli
echo "--- Install notation cli ---"
NOTATION_DOWNLOAD_FILE_SUFFIX=$(if [[ $IS_ARM = true ]]; then echo 'linux_arm64'; else echo 'linux_amd64'; fi)
NOTATION_VERSION=$(
 curl --silent "https://api.github.com/repos/notaryproject/notation/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
) && curl -L -o notation.tar.gz "https://github.com/notaryproject/notation/releases/download/v${NOTATION_VERSION}/notation_${NOTATION_VERSION}_${NOTATION_DOWNLOAD_FILE_SUFFIX}.tar.gz" \
    && tar -xvzf ./notation.tar.gz notation && sudo mv ./notation /usr/local/bin && rm ./notation.tar.gz
echo ""

echo "--- Install notation key vault plugin ---"
NOTATION_KEYVAULT_PLUGIN_DOWNLOAD_FILE_SUFFIX=$(if [[ $IS_ARM = true ]]; then echo 'linux_arm64'; else echo 'linux_amd64'; fi)
NOTATION_KEYVAULT_PLUGIN_DIR="$HOME/.config/notation/plugins/azure-kv"
NOTATION_KEYVAULT_PLUGIN_VERSION=$(
 curl --silent "https://api.github.com/repos/Azure/notation-azure-kv/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
)
mkdir -p $NOTATION_KEYVAULT_PLUGIN_DIR \
    && curl -L -o notation-azure-kv.tar.gz "https://github.com/Azure/notation-azure-kv/releases/download/v${NOTATION_KEYVAULT_PLUGIN_VERSION}/notation-azure-kv_${NOTATION_KEYVAULT_PLUGIN_VERSION}_${NOTATION_KEYVAULT_PLUGIN_DOWNLOAD_FILE_SUFFIX}.tar.gz" \
    && tar xvzf notation-azure-kv.tar.gz -C $NOTATION_KEYVAULT_PLUGIN_DIR \
    && rm ./notation-azure-kv.tar.gz
notation plugin ls
echo ""

echo "--- Install bicep ---"
if [[ $IS_ARM = true ]]; then
    echo "Yep, it's an arm64 machine"
    BICEP_VERSION=$(
        curl --silent "https://api.github.com/repos/Azure/bicep/releases/latest" | \
        grep '"tag_name":' | \
        sed -E 's/.*"v([^"]+)".*/\1/' \
    )
    curl -L -o bicep "https://github.com/Azure/bicep/releases/download/v${BICEP_VERSION}/bicep-linux-arm64" \
        && chmod +x bicep \
        && sudo mv ./bicep /usr/local/bin
    # configure az cli to run bicep from path instead to install it when running 'az bicep' commands
    az config set bicep.check_version=false 2> /dev/null && az config set bicep.use_binary_from_path=true 2> /dev/null
else
    echo "It's not arm64, install default"
    az bicep install
fi
echo ""

echo "--- Ensure local container registry ---"
REGISTRY_CONTAINER_NAME='registry'
if docker ps -a --format '{{.Names}}' | grep $REGISTRY_CONTAINER_NAME ; then
    # If the container exists, stop and remove it
    echo "Stopping and removing the '$REGISTRY_CONTAINER_NAME' container..."
    docker stop $REGISTRY_CONTAINER_NAME > /dev/null
    docker rm $REGISTRY_CONTAINER_NAME > /dev/null
fi
docker run -d -p 5001:5000 -e REGISTRY_STORAGE_DELETE_ENABLED=true --name $REGISTRY_CONTAINER_NAME registry
echo ""
