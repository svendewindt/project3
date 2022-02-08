
<#
.SYNOPSIS
  Script to the Microsoft monitoring agent (MMA), to be used in combination with the other scripts:
    .\CreateAutomationAccount
    .\CreateOMSWorkspace

.DESCRIPTION
  This script will install the Microsoft monitoring agent on a Windows machine.
  This script needs to be run as an administrator. 

.PARAMETER AutomationContextFile
  Mandatory. Points to the AutomationContextFile

.PARAMETER AgentLocation
  Optional. The location where to find the agent to install. If the agent is not there, it will be downloaded from the Internet.

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  23/10/2018
  Purpose/Change: Initial script development

  Version:        0.2
  Author:         Sven de Windt
  Creation Date:  2/11/2018
  Purpose/Change: Additional parameter for agent location.

.EXAMPLE
  .\IntallMonitoringAgent -verbose

.EXAMPLE
  .\IntallMonitoringAgent -SaveSpecs -verbose -AddAsHybridWorker

.EXAMPLE
  .\IntallMonitoringAgent -AgentLocation 'c:\vagrant_data\MMASetup.exe' -verbose

#>

#requires -version 3.0
#Requires -RunAsAdministrator

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
    [parameter(mandatory = $true)][string]$AutomationContextFile,
    [parameter(mandatory = $false)][string]$AgentLocation = "$env:temp\MMASetup.exe",
    [switch]$AddAsHybridWorker
)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ScriptVersion = "0.2"
$MMA64bitURL = "http://download.microsoft.com/download/1/5/E/15E274B9-F9E2-42AE-86EC-AC988F7631A0/MMASetup-AMD64.exe"
$MMA32bitURL = "http://download.microsoft.com/download/1/5/E/15E274B9-F9E2-42AE-86EC-AC988F7631A0/MMASetup-i386.exe"
# $AgentLocation = "C:\vagrant_data\MMASetup.exe"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function get-AutomationContext () {
    Write-Verbose "Getting automation context"
    #$AutomationContextFile = "C:\_Repo\p3ops-tile\Sven\scripts\AutomationContext.json"
    $Context = Get-Content $AutomationContextFile | ConvertFrom-Json
    return $Context
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Clear-Host
Write-Output "Start script - version $($ScriptVersion)"

# Write-Output "Install necessary Nuget packages"
# Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Write-output "Importing necessary modules"
#Install-Module azurerm -Scope CurrentUser -Force
#Import-Module AzureRm

if ($AutomationContextFile) {
    
    # A context file was provided, get info to login to Azure
    $Context = get-AutomationContext
    # $Serviceprincipal = $Context.ServicePrincipal.ApplicationId
    # $ServicePrincipalPassword = $Context.ServicePrincipalPassword 
    # $TenantID = $Context.Context.Tenant.TenantId
    
    # With the retrieved ApplicationId and secure password we can create a credential object
    # $Securepassword = ConvertTo-SecureString -Force -AsPlainText -String $ServicePrincipalPassword
    # $Credential = New-Object -TypeName System.Management.Automation.PSCredential($Serviceprincipal, $Securepassword)
    #$cred = New-Object -TypeName System.Management.Automation.PSCredential($userId ,$password)

    # Finally we use this object to login on Azure with this credential object
    # Write-Verbose "Login on Azure, using serviceprincipal"
    # Connect-AzureRmAccount -ServicePrincipal -Credential $Credential -TenantId $TenantID

}
else {
    
    Write-Error "Not to be used like this yet" -ErrorAction Stop
    # No context file was provided, login to Azure by asking credentials
    Write-Verbose "Login on to Azure"
    Login-AzureRmAccount
}

Write-Verbose "Get context"
$Context = get-AutomationContext

Write-Verbose "Setting parameters with info from the context file"

$WorkspaceId = $Context.Workspace.OMSWorkspaceId
#Write-Verbose "WorkspaceId = $($WorkspaceId)"
$WorkspaceKey = $Context.Workspace.OMSWorkspaceKeys.PrimarySharedKey
#Write-Verbose "Key = $($WorkspaceKey)"
$AutomationEndpoint = $Context.AutomationAccountInfo.Endpoint
$AutomationPrimaryKey = $Context.AutomationAccountInfo.PrimaryKey

# Check for the MMA on the machine
try {

    $mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
    
    Write-Output "Configuring the MMA..."
    $mma.AddCloudWorkspace($WorkspaceId, $WorkspaceKey)
    $mma.ReloadConfiguration()

}
catch {
    # Download the Microsoft monitoring agent
    Write-Output "Downloading and installing the Microsoft Monitoring Agent..."

    # Check whether or not to download the 64-bit executable or the 32-bit executable
    if ([Environment]::Is64BitProcess) {
        $Source = $MMA64bitURL
    }
    else {
        $Source = $MMA32bitURL
    }

    $Destination = $AgentLocation

    if (-not (Test-Path $Destination)) {
        Write-Verbose "Setup files not found, downloading..."
        $null = Invoke-WebRequest -uri $Source -OutFile $Destination
        $null = Unblock-File $Destination
    }
    else {
        Write-Verbose "Setup files already preset, skip download"
    }

    # Change directory to location of the downloaded MMA
    #cd $env:temp
    $DestinationFolder = Split-Path $Destination
    cd $DestinationFolder

    # Install the MMA
    Write-Verbose "Installing Microsoft Monitoring Agent"
    $Command = "/C:setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_ID=$WorkspaceID" + " OPINSIGHTS_WORKSPACE_KEY=$WorkspaceKey " + " AcceptEndUserLicenseAgreement=1"
    .\MMASetup.exe $Command

}


# Sleep until the MMA object has been registered
Write-Output "Waiting for agent registration to complete..."

# Timeout = 180 seconds = 3 minutes
$i = 18

    do {
    
        # Check for the MMA folders
        try {
            # Change the directory to the location of the hybrid registration module
            cd "$env:ProgramFiles\Microsoft Monitoring Agent\Agent\AzureAutomation"
            $version = (ls | Sort-Object LastWriteTime -Descending | Select -First 1).Name
            cd "$version\HybridRegistration"

            # Import the module
            Import-Module (Resolve-Path('HybridRegistration.psd1'))

            # Mark the flag as true
            $hybrid = $true
        }
        catch {

            $hybrid = $false

        }
        # Sleep for 10 seconds
        Start-Sleep -s 10
        $i--

    } until ($hybrid -or ($i -le 0))

if ($AddAsHybridWorker) {
    
    if ($i -le 0) {
        throw "The HybridRegistration module was not found. Please ensure the Microsoft Monitoring Agent was correctly installed."
    }

    $HybridGroupName = $Context.AutomationAccount.AutomationAccountName
    # Register the hybrid runbook worker
    Write-Output "Registering the hybrid runbook worker..."
    Add-HybridRunbookWorker -Name $HybridGroupName -EndPoint $AutomationEndpoint -Token $AutomationPrimaryKey
}

