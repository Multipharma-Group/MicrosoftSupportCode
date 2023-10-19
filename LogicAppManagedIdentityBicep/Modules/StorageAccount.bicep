// ========== StorageAccount.bicep ==========
// Bicep Template for deploying a Standard Logic App with a Managed Identity, Application Insights, Log Analytics Workspace and Storage Account for the purpose of providing the example for the Easy Auth bug.
// Written by Padure Sergio for Multipharma

//Defining Incoming Parameters
param DeploymentTags object
param DeploymentRegion string
param NamePrefix string

//Defining Calculated Variables
//var SubscriptionID = subscription().subscriptionId
var StorageAccountName = replace('${toLower(NamePrefix)}${toLower('-SA')}', '-', '')
var ApplicationSecurityGroupName = '${NamePrefix}-SA-ASG'

// Create Application Security Group
resource ApplicationSecurityGroup 'Microsoft.Network/applicationSecurityGroups@2022-11-01' = {
  name: ApplicationSecurityGroupName
  location: DeploymentRegion
  tags: DeploymentTags
  properties: {}
}

// Create Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: StorageAccountName
  location: DeploymentRegion
  tags: DeploymentTags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_ZRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    defaultToOAuthAuthentication: true
    //allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
  }
}

output SA_ID string = storageAccount.id
output SA_Name string = storageAccount.name
