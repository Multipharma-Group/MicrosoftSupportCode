# authsettingsv2 configuration applied via Bicep to Azure Standard Web App doesn't enable authentication

## Introduction

This concerns an issue identified with the deployment of authsettingsv2 via Bicep wherein the actual configuration is correctly applied to the Azure WebApps-based Logic App Standard but the authentication is not enabled which returns the following error when sending an API call to the Logic App:
```
{
    "error": {
        "code": "DirectApiInvalidAuthorizationScheme",
        "message": "The provided authorization token is not valid. The request should have a valid authorization header with 'Bearer' scheme."
    }
}
```

Analysis of Log Stream in Standard Logic App is showing this message from the Easy Auth middleware:
```
EdgeAuthorizationProcessor.IsWebsiteAuthEnabled: False.
```

Which is different from the one sent when authsettingsv2 are configured via the Azure Management API:
```
EdgeAuthorizationProcessor.IsWebsiteAuthEnabled: True.
```

This pointed to an issue with the Bicep deployment of the 'Microsoft.Web/sites/config@2022-03-01' resource, so a test has been done to re-apply the exact same settings through the Azure Management API as detailed in the [following link](https://techcommunity.microsoft.com/t5/azure-integration-services-blog/trigger-workflows-in-standard-logic-apps-with-easy-auth/ba-p/3207378).
Which solved the issue and authentication started working, but that's a workaround.
Thus this repository has been created after discussion with Microsoft Support to provide code to reproduce the issue and escalate it to the Bicep team for resolution.

## Resolution

Issue is solved after adding
```
    platform: {
      enabled: true
      runtimeVersion: '~1'
    }
```
to the bicep code.

## Usage

# Prerequisites

- Windows Server 2016+ / Windows 10+
- Azure CLI installed on the machine: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
- Azure Powershell installed on the machine: https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell?view=azps-10.4.1
- Bicep extension installed on the machine: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli
- A subscription with a Virtual Network and a /26 subnet for Standard Logic Apps already prepared following best practices: https://learn.microsoft.com/en-us/azure/logic-apps/secure-single-tenant-workflow-virtual-network-private-endpoint
- Subnet delegation to 'Microsoft.Web/serverfarms' assigned to the abovementioned subnet

# Deployment

1. Pull the repo to your local machine
2. Rename DeploymentParams.json.template to DeploymentParams.json
3. Replace the mock values in the DeploymentParams.json file with the ones of your tenant/subscription/resource group/vnet/ecc...
4. Run
```
cd C:\path\to\the\repo\location\LogicAppManagedIdentityBicep
az login
az account set --subscription subscriptionname
az deployment sub create --location desiredlocation --name "BicepDeploy-LogApp-authsettingsv2" --template-file .\main.bicep --parameters .\DeploymentParams.json
```
5. Wait until deployment is complete
6. Run Import-LogicAppWorkflows.ps1 to import the Echo Logic App
7. Run Trigger-StandardLogicAppthroughAPI.ps1 to test