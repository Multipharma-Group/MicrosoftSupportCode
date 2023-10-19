// ========== AppInsights.bicep ==========
// Bicep Template for deploying a Standard Logic App with a Managed Identity, Application Insights, Log Analytics Workspace and Storage Account for the purpose of providing the example for the Easy Auth bug.
// Written by Padure Sergio for Multipharma

//Defining Incoming Parameters
param DeploymentTags object
param DeploymentRegion string
param NamePrefix string
param DeploymentSubscriptionName string

//Defining Calculated Variables
var AppInsightsName = '${NamePrefix}-AppInsights'
var LogAnalyticsWorkspaceName = '${DeploymentSubscriptionName}-LAW'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {  
  name: LogAnalyticsWorkspaceName
}

resource AppInsights 'microsoft.insights/components@2020-02-02' = {
  name: AppInsightsName
  location: DeploymentRegion
  tags: union(DeploymentTags, {
      'hidden-link:${resourceId('Microsoft.Web/sites', AppInsightsName)}': 'Resource'
    })
  kind: 'web'
  properties: {
    Request_Source: 'IbizaWebAppExtensionCreate'
    Flow_Type: 'Redfield'
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

output AppInsightsID string = AppInsights.id
output AppInsightsName string = AppInsightsName
output AppInsightsConnectionString string = AppInsights.properties.ConnectionString
output AppInsightsInstrumentationKey string = AppInsights.properties.InstrumentationKey
