@description('Region for the resources')
param location string = resourceGroup().location

@description('Enable purge protection for the key vault')
param enableKeyVaultPurgeProtection bool = false

@description('Object id of the user, who will be granted permissions')
param userObjectId string

var suffix = substring(uniqueString(resourceGroup().id), 0, 6)
var keyVaultAdministratorRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483') // role name: Key Vault Administrator

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

resource roleAssignmentKeyVaultAdministrator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, userObjectId, keyVaultAdministratorRole)
  scope: keyVault
  properties: {
    principalId: userObjectId
    roleDefinitionId: keyVaultAdministratorRole
    principalType: 'User'
  }
}
