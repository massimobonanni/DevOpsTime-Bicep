// ---------------------------------------------------
// Step 01 - Monolitic template (scope ResourceGroup)
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
var resourceNamePrefix = '${environmentName}-${environmentType}-${substring(uniqueString(environmentName, environmentType), 0, 10)}'

var webAppName = '${resourceNamePrefix}-app'
var webAppPlanName = '${resourceNamePrefix}-plan'
var appInsightName = '${resourceNamePrefix}-appinsight'
var primaryStorageName = '${resourceNamePrefix}-s1'
var secondaryStorageName = '${resourceNamePrefix}-s2'

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
  name: webAppName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: webAppPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'PrimaryStorageConnection'
          value: 'DefaultEndpointsProtocol=https;AccountName=${primaryStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${primaryStorage.listKeys().keys[0].value}'
        }
      ]
    }
  }
}

resource webAppPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: webAppPlanName
  location: location
  kind: 'app'
  sku: appPlanConfigurationMap[environmentType].appServicePlan.sku
}

resource appSettings 'Microsoft.Web/sites/config@2022-03-01' = if (environmentType == 'prod') {
  name: 'appsettings'
  parent: webApp
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsight.properties.InstrumentationKey
    SecondaryStorageConnections: 'DefaultEndpointsProtocol=https;AccountName=${secondaryStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${secondaryStorage.listKeys().keys[0].value}'
  }
}

resource appInsight 'Microsoft.Insights/components@2020-02-02' = if (environmentType == 'prod') {
  name: appInsightName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource primaryStorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: primaryStorageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: (environmentType == 'prod') ? 'Standard_GRS' : 'Standard_LRS'
  }
}

resource secondaryStorage 'Microsoft.Storage/storageAccounts@2022-09-01' = if (environmentType == 'prod') {
  name: secondaryStorageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

output webAppUrl string = webApp.properties.defaultHostName
