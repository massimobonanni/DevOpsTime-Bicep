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

@description('Application Insight instrumentation key')
param appInsightInstumentationkey string

@description('Primary storage connection string')
param primaryStorageConnectionString string

@description('Secondary storage connection string')
param secondaryStorageConnectionString string

// Variables
var resourceNamePrefix = '${environmentName}${environmentType}${substring(uniqueString(resourceGroup().id), 0, 10)}'

var webAppName = '${resourceNamePrefix}-app'
var webAppPlanName = '${resourceNamePrefix}-plan'

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
  }
}

resource webAppPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: webAppPlanName
  location: location
  kind: 'app'
  sku: appPlanConfigurationMap[environmentType].appServicePlan.sku
}

resource appSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: webApp
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: (environmentType != 'prod') ? '' : appInsightInstumentationkey
    PrimaryStorageConnection : primaryStorageConnectionString
    SecondaryStorageConnections: (environmentType != 'prod') ? '' : secondaryStorageConnectionString
  }
}

output webAppUrl string = webApp.properties.defaultHostName
