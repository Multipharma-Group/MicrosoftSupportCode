// ========== SQL.bicep ==========
// Bicep Template for deploying a Standard Logic App with a Managed Identity, Application Insights, Log Analytics Workspace and Storage Account for the purpose of providing the example for the Easy Auth bug.
// Written by Padure Sergio for Multipharma

//Defining Incoming Parameters
param DeploymentTags object
param DeploymentRegion string
param TenantID string
param DeploymentSubscriptionID string
param StorageAccountName string
param StorageAccountResourceId string
param ResourceGroupName string
param EnvironmentPrefix string
param NamePrefix string
param AppInsighsResourceId string
param AppInsightsInstrumentationKey string
param AppInsightsConnectionString string
param VirtualNetworkName string
param VirtualNetworkResourceGroup string
param VirtualNetworkLogicAppSubnetName string
param IdentityObjectID string

//Defining Calculated Variables
var ManagementURLs = environment().authentication.audiences
//var SubscriptionID = subscription().subscriptionId
var LogicApp = '${NamePrefix}-LogApp'
var ASG_Name = '${NamePrefix}-LA-ASG'
var ServerFarmsName = '${NamePrefix}-LA-SF'
var LogicContentShareName = '${toLower(LogicApp)}-${toLower(EnvironmentPrefix)}share'
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: '${StorageAccountName}/default/${LogicContentShareName}'
}
param IdentityObjectIDs array = [
  IdentityObjectID
]

//Creating Server Farms for Standard Logic App
resource ServerFarms 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: ServerFarmsName
  location: DeploymentRegion
  tags: DeploymentTags
  sku: {
    tier: 'WorkflowStandard'
    name: 'WS1'
  }
  kind: 'elastic'
  properties: {
    targetWorkerCount: 1
    maximumElasticWorkerCount: 20
    elasticScaleEnabled: true
    isSpot: false
    zoneRedundant: false
  }
}

//Creating Standard Logic App
resource LogicApp_resource 'Microsoft.Web/sites@2022-09-01' = {
  name: LogicApp
  location: DeploymentRegion
  kind: 'functionapp,workflowapp'
  tags: union(DeploymentTags, {
      'hidden-link: /app-insights-resource-id': AppInsighsResourceId
    })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~16'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: AppInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: AppInsightsConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${StorageAccountName};AccountKey=${listKeys(StorageAccountResourceId, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${StorageAccountName};AccountKey=${listKeys(StorageAccountResourceId, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: LogicContentShareName
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }

      ]
      cors: {}
      use32BitWorkerProcess: false
      ftpsState: 'FtpsOnly'
      vnetRouteAllEnabled: true
      vnetPrivatePortsCount: 2
      netFrameworkVersion: 'v6.0'
    }
    serverFarmId: ServerFarms.id
    vnetRouteAllEnabled: true
    vnetImagePullEnabled: true
    vnetContentShareEnabled: true
    clientAffinityEnabled: false
    clientCertEnabled: true
    clientCertMode: 'Optional'
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    virtualNetworkSubnetId: resourceId(DeploymentSubscriptionID, VirtualNetworkResourceGroup, 'Microsoft.Network/VirtualNetworks/subnets', VirtualNetworkName, VirtualNetworkLogicAppSubnetName)
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

//Defining authentication settings for Logic App
resource symbolicname 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'authsettingsV2'
  kind: 'string'
  parent: LogicApp_resource
  properties: {
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'AllowAnonymous'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: IdentityObjectID
          openIdIssuer: 'https://sts.windows.net/${TenantID}/'
        }
        validation: {
          allowedAudiences: ManagementURLs
          defaultAuthorizationPolicy: {
            allowedPrincipals: {
              identities: IdentityObjectIDs
            }
          }
        }
      }
      facebook: {
        enabled: false
        login: {}
        registration: {}
      }
      gitHub: {
        enabled: false
        login: {}
        registration: {}
      }
      google: {
        enabled: false
        login: {}
        registration: {}
        validation: {}
      }
      legacyMicrosoftAccount: {
        enabled: false
        login: {}
        registration: {}
        validation: {}
      }
      twitter: {
        enabled: false
        registration: {}
      }
      apple: {
        enabled: false
        login: {}
        registration: {}
      }

    }
  }
}

//Defining Basic Publishing Credentials Policies for Logic App for ftp and scm
resource LogicApp_ftp 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: LogicApp_resource
  name: 'ftp'
  properties: {
    allow: true
  }
}

resource LogicApp_scm 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: LogicApp_resource
  name: 'scm'
  properties: {
    allow: true
  }
}

//Defining web settings for Logic App
resource LogicApp_web 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: LogicApp_resource
  name: 'web'
  properties: {
    alwaysOn: false
    publicNetworkAccess: 'Enabled'
    cors: {
      allowedOrigins: [
        'https://portal.azure.com'
      ]
      supportCredentials: true
    }
    ipSecurityRestrictionsDefaultAction: 'Allow'
    scmIpSecurityRestrictionsDefaultAction: 'Allow'
    scmIpSecurityRestrictionsUseMain: true
    http20Enabled: true
  }
}

//Defining hostname bindings for Logic App
resource LogicAppHostnameBindings 'Microsoft.Web/sites/hostNameBindings@2022-09-01' = {
  parent: LogicApp_resource
  name: '${LogicApp}.azurewebsites.net'
  properties: {
    siteName: '${ResourceGroupName}-RG-LogApp'
    hostNameType: 'Verified'
  }
}

//Setting VNET Integration for Logic App
resource LogicAppVNET 'Microsoft.Web/sites/virtualNetworkConnections@2022-09-01' = {
  parent: LogicApp_resource
  name: '${NamePrefix}-LA-VNET-${VirtualNetworkLogicAppSubnetName}'
  properties: {
    vnetResourceId: resourceId(DeploymentSubscriptionID, VirtualNetworkResourceGroup, 'Microsoft.Network/VirtualNetworks/subnets', VirtualNetworkName, VirtualNetworkLogicAppSubnetName)
    isSwift: true
  }
}

resource ASG 'Microsoft.Network/applicationSecurityGroups@2022-11-01' = {
  name: ASG_Name
  location: DeploymentRegion
  tags: DeploymentTags
  properties: {}
}


output LogicAppManagedIdentityID string = LogicApp_resource.identity.principalId
output LogicAppName string = LogicApp_resource.name
output LogicAppResourceID string = LogicApp_resource.id
output LogicAppHostname string = LogicApp_resource.properties.defaultHostName
