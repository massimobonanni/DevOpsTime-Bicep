// Parameters

@description('Location for the environment')
param location string = resourceGroup().location

@description('The sku of the storage account')
param storageSku string

@description('The name of the storage account')
param storageName string

// Resources

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageSku
  }
}

// Outputs
output storageName string = storage.name
