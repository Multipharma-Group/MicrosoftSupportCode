// ========== LogAnalytics.bicep ==========
// Bicep Template for deploying a Standard Logic App with a Managed Identity, Application Insights, Log Analytics Workspace and Storage Account for the purpose of providing the example for the Easy Auth bug.
// Written by Padure Sergio for Multipharma

//Defining Incoming Parameters
param DeploymentTags object
param DeploymentRegion string
param LogAnalyticsWorkspaceName string

//Deploying the Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: LogAnalyticsWorkspaceName
  tags: DeploymentTags
  location: DeploymentRegion
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}
