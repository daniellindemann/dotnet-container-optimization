@description('Region for the resources')
param location string = resourceGroup().location

@description('Enable purge protection for the key vault')
param enableKeyVaultPurgeProtection bool = false

@description('Object id of the user, who will be granted permissions')
param userObjectId string

var suffix = substring(uniqueString(resourceGroup().id), 0, 6)
var keyVaultAdministratorRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483') // role name: Key Vault Administrator
var acrPullRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // role name: AcrPull

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'kv-co-${suffix}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    enablePurgeProtection: enableKeyVaultPurgeProtection ? true : null // to disable purge protection the value must not be set
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'crco${suffix}'
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    policies: {
      trustPolicy: {
        type: 'Notary'
        status: 'enabled'
      }
    }
    publicNetworkAccess: 'Enabled'
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-11-01' = {
  name: 'aks-co-${suffix}'
  location: location
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.28.3'
    dnsPrefix: 'aks-co-${suffix}'
    enableRBAC: true
    supportPlan: 'KubernetesOfficial'
    disableLocalAccounts: false
    agentPoolProfiles: [
      {
        name: 'agentpool'
        mode: 'System'
        count: 3
        vmSize: 'Standard_B2ms'
        enableAutoScaling: false
      }
    ]
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: false
      }
      azurepolicy: {
        enabled: true
      }
    }
    networkProfile: {
      networkPlugin: 'kubenet'
      networkPolicy: 'calico'
      loadBalancerSku: 'standard'
      podCidr: '10.133.0.0/16'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
    }
    autoUpgradeProfile: {
      upgradeChannel: 'patch'
      nodeOSUpgradeChannel: 'NodeImage'
    }
    oidcIssuerProfile: {
      enabled: true
    }
    storageProfile: {
      blobCSIDriver: {
        enabled: false
      }
      diskCSIDriver: {
        enabled: false
      }
      fileCSIDriver: {
        enabled: false
      }
      snapshotController: {
        enabled: false
      }
    }
  }
}

resource roleAssignmentKeyVaultAdministrator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, userObjectId, keyVaultAdministratorRole)
  scope: keyVault
  properties: {
    principalId: userObjectId
    roleDefinitionId: keyVaultAdministratorRole
    principalType: 'User'
  }
}

// aks kubelet pull
resource roleAssignmentAksKubeletPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, 'kubelet', acrPullRole)
  scope: containerRegistry
  properties: {
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    roleDefinitionId: acrPullRole
    principalType: 'ServicePrincipal'
  }
}

output keyVaultName string = keyVault.name
output acrName string = containerRegistry.name
output acrLoginServer string = containerRegistry.properties.loginServer
