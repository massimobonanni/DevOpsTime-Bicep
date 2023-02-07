// ---------------------------------------------------
// Step 02 - Local modules (scope ResourceGroup)
// ---------------------------------------------------

// Parameters

@minLength(3)
@maxLength(6)
@description('The name of the environment. You can use a string from 3 to 6 character lenght.')
param environmentName string = 'DOT'

@allowed([
  'dev'
  'test'
  'prod'
])
@description('The environment type. Choose one of the dev, test or prod value.')
param environmentType string

@description('Location for the environment')
param location string = resourceGroup().location

// Variables
var resourceNamePrefix = '${environmentName}${environmentType}${substring(uniqueString(resourceGroup().id), 0, 10)}'

var primaryStorageName = toLower('${resourceNamePrefix}s1')
var secondaryStorageName = toLower('${resourceNamePrefix}s2')

// Modules
module frontEnd '02-frontend.bicep' = {
  name: '${deployment().name}-frontEnd'
  params: {
    environmentName: environmentName
    environmentType: environmentType
    location: location
    appInsightInstumentationkey: (environmentType == 'prod') ? monitor.outputs.appInsightInstrumentationKey : ''
    primaryStorageConnectionString: primaryStorage.outputs.storageConnectionString
    secondaryStorageConnectionString: (environmentType == 'prod') ? secondaryStorage.outputs.storageConnectionString : ''
  }
}

module monitor '02-monitor.bicep' = if (environmentType == 'prod') {
  name: '${deployment().name}-monitor'
  params: {
    environmentName: environmentName
    environmentType: environmentType
    location: location
  }
}

module primaryStorage '02-storage.bicep' = {
  name: '${deployment().name}-primaryStorage'
  params: {
    location: location
    storageName: primaryStorageName
    storageSku: (environmentType == 'prod') ? 'Standard_GRS' : 'Standard_LRS'
  }
}

module secondaryStorage '02-storage.bicep' = if (environmentType == 'prod') {
  name: '${deployment().name}-secondaryStorage'
  params: {
    location: location
    storageName: secondaryStorageName
    storageSku: 'Standard_LRS'
  }
}

output webAppUrl string = frontEnd.outputs.webAppUrl
