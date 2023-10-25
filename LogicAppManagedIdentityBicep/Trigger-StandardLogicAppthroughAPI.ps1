<#
.SYNOPSIS
    Trigger a standard logic app workflow and test whether authentication is working or not
.NOTES
    Written by Padure Sergio for Multipharma
#>
#Defining functions
function Parse-JWTtoken {
 
    [cmdletbinding()]
    param([Parameter(Mandatory = $true)][string]$token)
 
    #Validate as per https://tools.ietf.org/html/rfc7519
    #Access and ID tokens are fine, Refresh tokens will not work
    if (!$token.Contains(".") -or !$token.StartsWith("eyJ")) { Write-Error "Invalid token" -ErrorAction Stop }
 
    #Header
    $tokenheader = $token.Split(".")[0].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($tokenheader.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenheader += "=" }
    Write-Verbose "Base64 encoded (padded) header:"
    Write-Verbose $tokenheader
    #Convert from Base64 encoded string to PSObject all at once
    Write-Verbose "Decoded header:"
    [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($tokenheader)) | ConvertFrom-Json | fl | Out-Default
 
    #Payload
    $tokenPayload = $token.Split(".")[1].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($tokenPayload.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenPayload += "=" }
    Write-Verbose "Base64 encoded (padded) payoad:"
    Write-Verbose $tokenPayload
    #Convert to Byte array
    $tokenByteArray = [System.Convert]::FromBase64String($tokenPayload)
    #Convert to string array
    $tokenArray = [System.Text.Encoding]::ASCII.GetString($tokenByteArray)
    Write-Verbose "Decoded array in JSON format:"
    Write-Verbose $tokenArray
    #Convert from JSON to PSObject
    $tokobj = $tokenArray | ConvertFrom-Json
    Write-Verbose "Decoded Payload:"
    
    return $tokobj
}

#Clearing Host
Clear-Host

#Defining Local variables
$RootDir = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)

#Importing configuration from the DeploymentParams.json file
$DeploymentParams = Get-Content "$RootDir\DeploymentParams.json" | ConvertFrom-Json
$DeploymentParams.parameters
$EnvironmentPrefix = $DeploymentParams.parameters.EnvironmentPrefix.value
$ProjectIdentifier = $DeploymentParams.parameters.ProjectIdentifier.value
$Subscription = $DeploymentParams.parameters.DeploymentSubscriptionNameTemp.value
$LogicAppName = $ProjectIdentifier.ToUpper() + "-" + $EnvironmentPrefix.ToUpper() + "-LogApp"
$LogicAppRootURL = $LogicAppName.ToLower() + ".azurewebsites.net"
$ResourcesPrefix = ($EnvironmentPrefix.Substring(0,1).ToUpper()) + "-" + $ProjectIdentifier
$ResourceGroup = "$ResourcesPrefix-RG"



#Connecting to Az CLI
Write-Output "Connecting to Az CLI"
az login

#Setting the subscription context
Write-Output "Setting the subscription context"
az account set --subscription $Subscription

#Getting the authsettingsv2 configuration of the logic app
Write-Output "Getting the authsettingsv2 configuration of the logic app"
$authv2json = az webapp auth show --name $LogicAppName --resource-group $ResourceGroup
$authv2json

#Get the access token
Write-Output "Getting the access token"
$token = Get-AzAccessToken -ResourceUrl "https://management.azure.com/" | Select-Object -ExpandProperty 'Token'

#Decoding the access token
Write-Output "Decoding the access token"
Parse-JWTtoken -token $token

#Preparing the authorization header using the access token
Write-Output "Preparing the authorization header using the access token"
$Header = @{
    Authorization  = "Bearer $token"
    "Content-Type" = "application/json"
}

#Preparing the URL to invoke the logic app
Write-Output "Preparing the URL to invoke the logic app"
$logicAppUrlWithAuth = "https://$LogicAppRootURL`:443/api/TestAuth/triggers/manual/invoke?api-version=2022-05-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0"
$logicAppUrlWithAuth

#Invoke the logic app
Write-Warning "Invoking the logic app with Access Token of the current account"
Invoke-RestMethod -Uri $logicAppUrlWithAuth -Method Post -Headers $Header