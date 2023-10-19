// ========== ResourceGroup.bicep ==========
// Bicep Template for deploying a Standard Logic App with a Managed Identity, Application Insights, Log Analytics Workspace and Storage Account for the purpose of providing the example for the Easy Auth bug.
// Written by Padure Sergio for Multipharma

targetScope = 'subscription'

param ResourceGroupName string
param DeploymentTags object
param DeploymentRegion string

resource MainResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: ResourceGroupName
  tags: DeploymentTags
  location: DeploymentRegion
}
