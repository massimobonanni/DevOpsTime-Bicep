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
var resourceNamePrefix = '${environmentName}${environmentType}${substring(uniqueString(environmentName, environmentType), 0, 10)}'

var appInsightName = '${resourceNamePrefix}-appinsight'

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
output appInsightInstrumentationKey string = (environmentType == 'prod') ? appInsight.properties.InstrumentationKey : ''
