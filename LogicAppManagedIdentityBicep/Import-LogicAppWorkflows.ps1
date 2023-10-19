<#
.SYNOPSIS
    Imports Logic App Standard Workflows to the Storage Account
.NOTES
    Written by Padure Sergio for Multipharma
#>

#Clear Host
Clear-Host

# Set error action preference
$ErrorActionPreference = "Stop"

#Defining Local variables
$RootDir = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
$ImportLocation = "$RootDir\Workflows"

# Create export folder
if (!(Test-Path $ImportLocation)) {
    Throw "The import folder doesn't exist. Did you clone the git repo correctly?"
}

#Importing configuration from the DeploymentParams.json file
$DeploymentParams = Get-Content "$RootDir\DeploymentParams.json" | ConvertFrom-Json
$DeploymentParams.parameters


$EnvironmentPrefix = $DeploymentParams.parameters.EnvironmentPrefix.value
$ProjectIdentifier = $DeploymentParams.parameters.ProjectIdentifier.value
$TenantID = $DeploymentParams.parameters.TenantID.value
$Subscription = $DeploymentParams.parameters.DeploymentSubscriptionNameTemp.value
$ResourcesPrefix = ($EnvironmentPrefix.Substring(0,1).ToUpper()) + "-" + $ProjectIdentifier
$ResourceGroup = "$ResourcesPrefix-RG"


$StorageAccount = ("$ProjectIdentifier$EnvironmentPrefix`sa").ToLower()

#Defining Azure variables
$FileSharePath = "/site/wwwroot/"

#Connecting to Az PowerShell
Connect-AzAccount -Tenant $TenantID -Subscription $Subscription | Out-Null

# Get the storage account context
$ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount).Context
$ctx

# Get current IP
$ip = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content

try {
    # Open firewall
    Add-AzStorageAccountNetworkRule -ResourceGroupName $ResourceGroup -Name $StorageAccount -IPAddressOrRange $ip | Out-Null

    # Get the file share
    $fs = (Get-AZStorageShare -Context $ctx).Name

    # Get the files and folders
    $DirectoryObjects = Get-AzStorageFile -Context $ctx -ShareName $fs -Path "/site/wwwroot/" | Get-AzStorageFile

    #Enumerating local folders and creating them in the storage account if they don't exist
    $LocalFolders = Get-ChildItem -Path $ImportLocation -Directory
    foreach ($LocalFolder in $LocalFolders) {
        $RemoteFolderPath = $FileSharePath + $LocalFolder.Name
        $StorageFolder = Get-AzStorageFile -Context $ctx -ShareName $fs -Path $RemoteFolderPath -ErrorAction SilentlyContinue
        if (!$StorageFolder) {
            Write-Host "Creating folder $RemoteFolderPath" -ForegroundColor Yellow
            New-AzStorageDirectory -Context $ctx -ShareName $fs -Path $RemoteFolderPath
        }
        Start-Sleep -Seconds 1
        #Uploading files
        $LocalFiles = Get-ChildItem -Path $LocalFolder.FullName -File
        foreach ($LocalFile in $LocalFiles) {
            $StorageFilePath = $RemoteFolderPath + "/" + $LocalFile.Name
            Write-Host "Uploading file $StorageFilePath" -ForegroundColor Yellow
            Set-AzStorageFileContent -Context $ctx -ShareName $fs -Source $LocalFile.FullName -Path $StorageFilePath -Force
        }
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
finally {
    # Close firewall
    Remove-AzStorageAccountNetworkRule -ResourceGroupName $ResourceGroup -Name $StorageAccount -IPAddressOrRange $ip | Out-Null
}