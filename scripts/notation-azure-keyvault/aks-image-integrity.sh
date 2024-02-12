#!/bin/bash

# Details: https://learn.microsoft.com/en-us/azure/aks/image-integrity?tabs=azure-cli

# usage: ./aks-connaisseur.sh <aks> <keyvault> (<resource group>)

set -e

SCRIPT_DIR=$(dirname "$0")

# --- Configuration
# Name of the existing AKS
AKS_NAME="${1:-myaks}"
# Name of the existing AKV used to store the signing keys
AKV_NAME="${2:-myakv}"
AKS_RG="${3:-rg-container-optimization-neu}"
CERT_NAME="${4:-dlindemann-dev}"
CERT_PATH="${5:-$SCRIPT_DIR/$CERT_NAME.pem}"

# connect to AKS cluster
az aks get-credentials --resource-group $AKS_RG --name $AKS_NAME --overwrite-existing

# Ensure features are enabled in subscription
#   - EnableImageIntegrityPreview
#   - AKS-AzurePolicyExternalData

ENABLEIMAGEINTEGRITYPREVIEW_STATE=$(az feature show --namespace "Microsoft.ContainerService" --name "EnableImageIntegrityPreview" --query "properties.state" -o tsv)
if [[ "$ENABLEIMAGEINTEGRITYPREVIEW_STATE" == "NotRegistered" ]]; then
    az feature register --namespace "Microsoft.ContainerService" --name "EnableImageIntegrityPreview"
fi

AKS_AZUREPOLICYEXTERNALDATA_STATE=$(az feature show --namespace "Microsoft.ContainerService" --name "AKS-AzurePolicyExternalData" --query "properties.state" -o tsv)
if [[ "$AKS_AZUREPOLICYEXTERNALDATA_STATE" == "NotRegistered" ]]; then
    az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzurePolicyExternalData"
fi

# wait for features to be registered
while :
do
    ENABLEIMAGEINTEGRITYPREVIEW_STATE=$(az feature show --namespace "Microsoft.ContainerService" --name "EnableImageIntegrityPreview" --query "properties.state" -o tsv)
    AKS_AZUREPOLICYEXTERNALDATA_STATE=$(az feature show --namespace "Microsoft.ContainerService" --name "AKS-AzurePolicyExternalData" --query "properties.state" -o tsv)

    if [[ "$ENABLEIMAGEINTEGRITYPREVIEW_STATE" == "NotRegistered" ]] || [[ "$AKS_AZUREPOLICYEXTERNALDATA_STATE" == "NotRegistered" ]] || [[ "$ENABLEIMAGEINTEGRITYPREVIEW_STATE" == "Registering" ]] || [[ "$AKS_AZUREPOLICYEXTERNALDATA_STATE" == "Registering" ]]; then
        echo "Waiting for features to be registered..."
        sleep 30    # wait 30 seconds
    else
        break
    fi
done

# refresh the registration of the Microsoft.ContainerService namespace
az provider register --namespace Microsoft.ContainerService

# create initiative assignment for [Preview]: Use Image Integrity to ensure only trusted images are deployed
POLICY_ID='af28bf8b-c669-4dd3-9137-1e68fdc61bd6'
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${AKS_RG}"
LOCATION=$(az group show -n ${AKS_RG} --query location -o tsv)

az policy assignment create --name 'deploy-trustedimages' --policy-set-definition $POLICY_ID --display-name 'Audit deployment with unsigned container images' --scope $SCOPE --mi-system-assigned --role Contributor --identity-scope $SCOPE --location $LOCATION

# create remediation task for [Preview]: Use Image Integrity so it gets directly activated
ASSIGNMENT_ID=$(az policy assignment show -n 'deploy-trustedimages' --scope ${SCOPE} --query id -o tsv)
REMEDIATION_NAME='remediation-trustedimages'
az policy remediation create  -a "$ASSIGNMENT_ID" --definition-reference-id deployAKSImageIntegrity -n $REMEDIATION_NAME -g ${AKS_RG}

while :
do
    # check if ratify is deployed in gatekeeper-system
    RATIFY_QUERY_OUTPUT=$(kubectl get pods -n gatekeeper-system)

    if [[ "$RATIFY_QUERY_OUTPUT" =~ "ratify" ]]; then
        echo "ratify is deployed"
        break
    else
        echo "Waiting for remediation deploy gatekeeper system..."
        sleep 30    # wait 30 seconds
    fi
done

# create kubernetes manifest for image protection

# get certificate
rm $SCRIPT_DIR/$CERT_NAME.pem 2> /dev/null
az keyvault certificate download --name $CERT_NAME --vault-name $AKV_NAME --file $CERT_PATH
CERT_CONTENT=$(cat $SCRIPT_DIR/$CERT_NAME.pem)

cat <<EOF > $SCRIPT_DIR/verify-config.yaml
apiVersion: config.ratify.deislabs.io/v1beta1
kind: CertificateStore
metadata:
  name: certstore-inline
spec:
  provider: inline
  parameters:
    value: |
      $(echo $CERT_CONTENT | sed '1n; s/^/      /')
---
apiVersion: config.ratify.deislabs.io/v1beta1
kind: Store
metadata:
  name: store-oras
spec:
  name: oras
---
apiVersion: config.ratify.deislabs.io/v1beta1
kind: Verifier
metadata:
  name: verifier-notary-inline
spec:
  name: notation
  artifactTypes: application/vnd.cncf.notary.signature
  parameters:
    verificationCertStores:  # certificates for validating signatures
      certs: # name of the trustStore
        - certstore-inline # name of the certificate store CRD to include in this trustStore
    trustPolicyDoc: # policy language that indicates which identities are trusted to produce artifacts
      version: "1.0"
      trustPolicies:
        - name: default
          registryScopes:
            - "*"
          signatureVerification:
            level: strict
          trustStores:
            - ca:certs
          trustedIdentities:
            - "*"
EOF

# apply config
kubectl apply -f $SCRIPT_DIR/verify-config.yaml

# deploy images from acr
#  - nginx
#  - signed sample-app

echo "Verification config is deployed in audit mode."
echo "Run signed and unsigned images to get information about compliance in Azure policy compliance center."
echo "It takes up to 1h to check for image compliance."

