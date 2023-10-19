// ========== main.bicep ==========
// Bicep Template for deploying a Standard Logic App with a Managed Identity, Application Insights, Log Analytics Workspace and Storage Account for the purpose of providing the example for the Easy Auth bug.
// Written by Padure Sergio for Multipharma

// Defining the target scope for the deployment
targetScope = 'subscription'

//Defining Incoming Parameters
param TenantID string
param DeploymentRegion string
param DeploymentSubscriptionID string
param DeploymentSubscriptionNameTemp string
param EnvironmentPrefix string
param ProjectIdentifier string
param IdentityObjectID string
param dateTime string = utcNow()
param VirtualNetworkName string
param VirtualNetworkResourceGroup string
param VirtualNetworkLogicAppSubnetName string

//Defining Calculated Parameters
var deploymentNamePostfix = dateTime
param DeploymentSubscriptionName string = replace(DeploymentSubscriptionNameTemp, ' ', '')

///Defining Tags
param DeploymentTags object = {
  Application: 'LogicAppStandard'
  Project: ProjectIdentifier
  Environment: EnvironmentPrefix
  DeploymentBy: 'Bicep'
}

///Defining Resource Prefixes and Names
var ResourcesPrefix = '${first(toUpper(EnvironmentPrefix))}-${ProjectIdentifier}'
var NamePrefix = '${ProjectIdentifier}-${toUpper(EnvironmentPrefix)}'
var ResourceGroupName = '${ResourcesPrefix}-RG'
var LogAnalyticsWorkspaceName = '${DeploymentSubscriptionName}-LAW'

//Deploying the Resource Group
module resourceGroupDeploy './Modules/ResourceGroup.bicep' = {
  name: 'ResourceGroup-${deploymentNamePostfix}'
  params: {
    ResourceGroupName: ResourceGroupName
    DeploymentTags: DeploymentTags
    DeploymentRegion: DeploymentRegion
  }
}

//Deploying the Log Analytics Workspace
module logAnalyticsDeploy './Modules/LogAnalytics.bicep' = {
  scope: resourceGroup(ResourceGroupName)
  name: '${LogAnalyticsWorkspaceName}-${deploymentNamePostfix}'
  params: {
    DeploymentTags: DeploymentTags
    DeploymentRegion: DeploymentRegion
    LogAnalyticsWorkspaceName: LogAnalyticsWorkspaceName
  }
  dependsOn: [
    resourceGroupDeploy
  ]
}

//Deploying the Application Insights
module AppInsights 'Modules/AppInsights.bicep' = {
  name: 'AppInsights-${deploymentNamePostfix}'
  scope: resourceGroup(ResourceGroupName)
  params: {
    DeploymentTags: DeploymentTags
    DeploymentRegion: DeploymentRegion
    NamePrefix: NamePrefix
    DeploymentSubscriptionName: DeploymentSubscriptionName
  }
  dependsOn: [
    resourceGroupDeploy
  ]
}

//Deploying the Storage Account
module StorageAccount './Modules/StorageAccount.bicep' = {
  name: 'StorageAccount-${deploymentNamePostfix}'
  scope: resourceGroup(ResourceGroupName)
  params: {
    DeploymentTags: DeploymentTags
    DeploymentRegion: DeploymentRegion
    NamePrefix: NamePrefix
  }
  dependsOn: [
    resourceGroupDeploy
  ]
}

//Deploying the Standard Logic App
module LogicAppDeploy './Modules/LogicAppStandard.bicep' = {
  name: 'LogicApp-${deploymentNamePostfix}'
  scope: resourceGroup(ResourceGroupName)
  params: {
    TenantID: TenantID
    DeploymentTags: DeploymentTags
    DeploymentRegion: DeploymentRegion
    DeploymentSubscriptionID: DeploymentSubscriptionID
    ResourceGroupName: ResourceGroupName
    EnvironmentPrefix: EnvironmentPrefix
    NamePrefix: NamePrefix
    AppInsighsResourceId: AppInsights.outputs.AppInsightsID
    AppInsightsInstrumentationKey: AppInsights.outputs.AppInsightsInstrumentationKey
    AppInsightsConnectionString: AppInsights.outputs.AppInsightsConnectionString
    StorageAccountName: StorageAccount.outputs.SA_Name
    StorageAccountResourceId: StorageAccount.outputs.SA_ID
    IdentityObjectID: IdentityObjectID
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroup: VirtualNetworkResourceGroup
    VirtualNetworkLogicAppSubnetName: VirtualNetworkLogicAppSubnetName
  }
  dependsOn: [
    resourceGroupDeploy
    StorageAccount
    AppInsights
  ]
}
