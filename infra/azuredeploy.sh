#!/bin/bash

LOCATION="${1:-northeurope}"
RG_NAME="${2:-rg-container-optimization-neu}"

if ! command -v az &> /dev/null; then
    echo "Install Azure CLI: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

az account show --output none
if [ $? -ne 0 ]; then
    echo "Log into your Azure account: az login"
    exit 1
fi

AZ_USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

echo "Create resource group $RG_NAME"
az group create -l $LOCATION -n $RG_NAME

echo "Deploy"
az deployment group create --name azuredeploy --resource-group $RG_NAME --template-file main.bicep --parameters userObjectId="$AZ_USER_OBJECT_ID"


