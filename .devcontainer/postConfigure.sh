#!/bin/bash

# install dockle
DOCKLE_VERSION=$(
 curl --silent "https://api.github.com/repos/goodwithtech/dockle/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
) && curl -L -o dockle.deb "https://github.com/goodwithtech/dockle/releases/download/v${DOCKLE_VERSION}/dockle_${DOCKLE_VERSION}_Linux-64bit.deb"
sudo dpkg -i dockle.deb && rm dockle.deb

# install hadolint
HADOLINT_VERSION=$(
 curl --silent "https://api.github.com/repos/hadolint/hadolint/releases/latest" | \
 grep '"tag_name":' | \
 sed -E 's/.*"v([^"]+)".*/\1/' \
) && curl -L -o hadolint "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64" && chmod +x ./hadolint
sudo mv ./hadolint /usr/local/bin

# install trivy
TRIVY_VERSION='v0.45.1'
curl -sfL -o trivy_install.sh https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh && chmod +x ./trivy_install.sh
sudo ./trivy_install.sh -b /usr/local/bin $TRIVY_VERSION
rm ./trivy_install.sh