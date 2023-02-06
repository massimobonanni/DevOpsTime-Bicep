// Parameters

@allowed([
  'dev'
  'test'
  'prod'
])
@description('The environment type. Choose one of the dev, test or prod value.')
param environmentType string

@description('Location for the environment')
param location string = resourceGroup().location

@description('Web app name')
param appServiceName string

@description('App Service Plan name')
param appServicePlanName string

@description('Application Insight name')
param appInsightName string

@description('Primary storage name')
param primaryStorageName string

@description('Secondary storage name')
param secondaryStorageName string

// Variables
var appPlanConfigurationMap = {
  prod: {
    appServicePlan: {
      sku: {
        name: 'P1'
        tier: 'Premium'
      }
    }
  }
  test: {
    appServicePlan: {
      sku: {
        name: 'F1'
        tier: 'Free'
      }
    }
  }
  dev: {
    appServicePlan: {
      sku: {
        name: 'F1'
        tier: 'Free'
      }
    }
  }
}

// Resources
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: webAppPlan.id
  }
}

resource webAppPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'app'
  sku: appPlanConfigurationMap[environmentType].appServicePlan.sku
}

resource appSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: webApp
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: (environmentType != 'prod') ? '' : appInsight.properties.InstrumentationKey
    PrimaryStorageConnection : 'DefaultEndpointsProtocol=https;AccountName=${primaryStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${primaryStorage.listKeys().keys[0].value}'
    SecondaryStorageConnections: (environmentType != 'prod') ? '' : 'DefaultEndpointsProtocol=https;AccountName=${secondaryStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${secondaryStorage.listKeys().keys[0].value}'
  }
}

resource appInsight 'Microsoft.Insights/components@2020-02-02' existing = if (environmentType == 'prod') {
  name: appInsightName
}

resource primaryStorage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: primaryStorageName
}

resource secondaryStorage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = if (environmentType == 'prod') {
  name: secondaryStorageName
}


output webAppUrl string = webApp.properties.defaultHostName
