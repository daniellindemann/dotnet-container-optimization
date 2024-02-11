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
KV_CERT_EXPIRES=$(az keyvault certificate show --name $CERT_NAME --vault-name $AKV_NAME --query 'attributes.expires' -o tsv 2> /dev/null)
TIMESTAMP_NOW=$(date +%s)
TIMESTAMP_EXPIRES=$(date -d $KV_CERT_EXPIRES +%s 2> /dev/null || echo 0)
if [ $TIMESTAMP_EXPIRES -gt $TIMESTAMP_NOW ]; then
    echo "Certificate $CERT_NAME already exists and is valid until $KV_CERT_EXPIRES"
else
    az keyvault certificate create -n $CERT_NAME --vault-name $AKV_NAME -p @$SCRIPT_DIR/cert_policy.json
fi
echo ""

echo "--- Sign image with notation"
az acr login --name $ACR_NAME
$SCRIPT_DIR/../docker/docker-build-default-multi-arch.sh --no-default-tags -t "$REGISTRY/${REPO}:$TAG" --push
sleep 3
DIGEST=$(az acr repository show -n $ACR_NAME -t "${REPO}:$TAG" --query "digest" -o tsv)
SIGN_IMAGE=$REGISTRY/${REPO}@$DIGEST
KEY_ID=$(az keyvault certificate show -n $CERT_NAME --vault-name $AKV_NAME --query 'kid' -o tsv)

notation sign --signature-format cose --id $KEY_ID --plugin azure-kv --plugin-config self_signed=true $SIGN_IMAGE
sleep 3
notation ls $SIGN_IMAGE
echo ""

read -p "Press any key to contiue to image verification ..."

echo "--- Verify image"
rm $SCRIPT_DIR/$CERT_NAME.pem 2> /dev/null
az keyvault certificate download --name $CERT_NAME --vault-name $AKV_NAME --file $CERT_PATH
STORE_TYPE="ca"
STORE_NAME=$CERT_NAME

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
notation verify $SIGN_IMAGE
