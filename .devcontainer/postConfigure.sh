#!/bin/bash

# install dockle
echo "--- Install dockle ---"
DOCKLE_VERSION=$(
 curl --silent "https://api.github.com/repos/goodwithtech/dockle/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
) && curl -L -o dockle.deb "https://github.com/goodwithtech/dockle/releases/download/v${DOCKLE_VERSION}/dockle_${DOCKLE_VERSION}_Linux-64bit.deb"
sudo dpkg -i dockle.deb && rm dockle.deb
echo ""

# install hadolint
echo "--- Install hadolint ---"
HADOLINT_VERSION=$(
 curl --silent "https://api.github.com/repos/hadolint/hadolint/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
) && curl -L -o hadolint "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64" && chmod +x ./hadolint
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
NOTATION_VERSION=$(
 curl --silent "https://api.github.com/repos/notaryproject/notation/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
) && curl -L -o notation.tar.gz "https://github.com/notaryproject/notation/releases/download/v${NOTATION_VERSION}/notation_${NOTATION_VERSION}_linux_amd64.tar.gz" \
    && tar -xvzf ./notation.tar.gz notation && sudo mv ./notation /usr/local/bin && rm ./notation.tar.gz
echo ""

echo "--- Install notation key vault plugin ---"
NOTATION_KEYVAULT_PLUGIN_DIR="$HOME/.config/notation/plugins/azure-kv"
NOTATION_KEYVAULT_PLUGIN_VERSION=$(
 curl --silent "https://api.github.com/repos/Azure/notation-azure-kv/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
)
mkdir -p $NOTATION_KEYVAULT_PLUGIN_DIR \
    && curl -L -o notation-azure-kv.tar.gz "https://github.com/Azure/notation-azure-kv/releases/download/v${NOTATION_KEYVAULT_PLUGIN_VERSION}/notation-azure-kv_${NOTATION_KEYVAULT_PLUGIN_VERSION}_linux_amd64.tar.gz" \
    && tar xvzf notation-azure-kv.tar.gz -C $NOTATION_KEYVAULT_PLUGIN_DIR \
    && rm ./notation-azure-kv.tar.gz
notation plugin ls
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
