#!/bin/bash

# usage: ./notation-azure-keyvault-sign-image.sh <keyvault> <acr> (<image>) (<tag>)

SCRIPT_DIR=$(dirname "$0")

# --- Configuration
# Name of the existing AKV used to store the signing keys
AKV_NAME="${1:-myakv}"
# Name of the existing registry example: myregistry.azurecr.io
ACR_NAME="${2:-myregistry}"
# Name of the certificate created in AKV
CERT_NAME="${5:-dlindemann-dev}"
CERT_SUBJECT="${6:-CN=dlindemann.dev,O=abtis GmbH,L=Berlin,ST=Berlin,C=Germany}"
CERT_PATH="${7:-$SCRIPT_DIR/$CERT_NAME.pem}"

# --- Variables
# Existing full domain of the ACR
REGISTRY=$([[ $ACR_NAME == *.azurecr.io ]] && echo $ACR_NAME || echo "$ACR_NAME.azurecr.io")
# Container name inside ACR where image will be stored
REPO="${3:-sample-app}"
TAG="${4:-1.0.0}"
IMAGE=$REGISTRY/${REPO}:$TAG

# --- Check prerequisites
if ! command -v az &> /dev/null; then
    echo "Install Azure CLI: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

az account show --output none
if [ $? -ne 0 ]; then
    echo "Log into your Azure account: az login"
    exit 1
fi

echo "--- Create self-signed certificate in key vault"
cat <<EOF > $SCRIPT_DIR/cert_policy.json
{
    "issuerParameters": {
    "certificateTransparency": null,
    "name": "Self"
    },
    "keyProperties": {
      "exportable": false,
      "keySize": 2048,
      "keyType": "RSA",
      "reuseKey": true
    },
    "x509CertificateProperties": {
    "ekus": [
        "1.3.6.1.5.5.7.3.3"
    ],
    "keyUsage": [
        "digitalSignature"
    ],
    "subject": "$CERT_SUBJECT",
    "validityInMonths": 12
    }
}
EOF
az keyvault certificate create -n $CERT_NAME --vault-name $AKV_NAME -p @$SCRIPT_DIR/cert_policy.json
echo ""

echo "--- Sign image with notation"
az acr login --name $ACR_NAME
$SCRIPT_DIR/../docker/docker-build-default.sh -t "$REGISTRY/${REPO}:$TAG"
docker push $REGISTRY/${REPO}:$TAG
sleep 3
DIGEST=$(az acr repository show -n $ACR_NAME -t "${REPO}:$TAG" --query "digest" -o tsv)
IMAGE=$REGISTRY/${REPO}@$DIGEST
KEY_ID=$(az keyvault certificate show -n $CERT_NAME --vault-name $AKV_NAME --query 'kid' -o tsv)

notation sign --signature-format cose --id $KEY_ID --plugin azure-kv --plugin-config self_signed=true $IMAGE
sleep 3
notation ls $IMAGE
echo ""

read -p "Press any key to contiue to image verification ..."

echo "--- Verify image"
rm ./scripts/notation-azure-keyvault/dlindemann-dev.pem 2> /dev/null
az keyvault certificate download --name $CERT_NAME --vault-name $AKV_NAME --file $CERT_PATH
STORE_TYPE="ca"
STORE_NAME="dlindemann.dev"

notation cert delete --type $STORE_TYPE --store $STORE_NAME -a -y 2> /dev/null
notation cert add --type $STORE_TYPE --store $STORE_NAME $CERT_PATH
notation cert ls

cat <<EOF > $SCRIPT_DIR/trustpolicy.json
{
    "version": "1.0",
    "trustPolicies": [
        {
            "name": "dlindemann-dev-images",
            "registryScopes": [ "$REGISTRY/$REPO" ],
            "signatureVerification": {
                "level" : "strict" 
            },
            "trustStores": [ "$STORE_TYPE:$STORE_NAME" ],
            "trustedIdentities": [
                "x509.subject: $CERT_SUBJECT"
            ]
        }
    ]
}
EOF
notation policy import $SCRIPT_DIR/trustpolicy.json
notation policy show
notation verify $IMAGE
