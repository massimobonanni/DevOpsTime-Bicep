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

@description('Application Insight name')
param appInsightName string

// Resources
resource appInsight 'Microsoft.Insights/components@2020-02-02' = if (environmentType == 'prod') {
  name: appInsightName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

// Outputs
output appInsightName string = (environmentType == 'prod') ? appInsight.name : ''
