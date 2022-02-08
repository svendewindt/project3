<#
.SYNOPSIS
  Script to create a new operations manager workspace (OMS).

.DESCRIPTION
  This script will create an new operations manager workspace (OMS) in Azure. 

.PARAMETER WorkspaceName
  Optional. The name of the workspace to create.

.PARAMETER ResourceGroup
  Optional. The name of the resource group where to create the automation account.

.PARAMETER Location
  Optional. The location of the Azure data center where to create the workspace. To get all locations, run Get-AzureRmLocation.

.PARAMETER Sku
  Optional. The sku for the workspace

.PARAMETER AutomationContextFile
  Optional. Points to the AutomationContextFile.

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  22/10/2018
  Purpose/Change: Initial script development

.OUTPUTS
  The script creates a json file with information about the tenant, the automation account, the application created. In the json is also a secured - encrypted key for the service principal.
  
.EXAMPLE
  .\CreateOMSWorkspace -verbose

.EXAMPLE
  .\CreateOMSWorkspace -SaveSpecs -verbose

.EXAMPLE
  .\CreateOMSWorkspace.ps1 -AutomationContextFile .\AutomationContext.json -Verbose

.EXAMPLE
  .\CreateOMSWorkspace -WorkspaceName "AutomationAcccount" -verbose

.EXAMPLE
  .\CreateOMSWorkspace -WorkspaceName "AutomationAcccount" -ResourceGroup "Auto-RG" -verbose

.EXAMPLE
  .\CreateOMSWorkspace -WorkspaceName "AutomationAcccount" -ResourceGroup "Auto-RG" -Location "WestEurope" -verbose

#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
    [parameter(mandatory=$false)][string]$OMSWorkspaceName = "OMSWorkspace"  + (Get-Random -Maximum 99999),
    [parameter(mandatory=$false)][string]$ResourceGroup = "Automation",
    [parameter(mandatory=$false)][string]$Location = "westeurope",
    [parameter(mandatory=$false)][ValidateSet("Free", "PerNode", "Premium", "StandAlone", "Standard")][string]$Sku = "PerNode",
    [parameter(mandatory=$false)][string]$AutomationContextFile
)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ScriptVersion = "0.1"
#$FileNameContext = "AutomationContext.json"
$IntelligencePacks = @("AzureAutomation", "ServiceMap", "LogManagement", "NetworkMonitoring", "ChangeTracking", "AntiMalware", "Security")

<#
Packs:
Insight & Analytics
    Network performance monitor    NetworkMonitoring
    Service Map                    ServiceMap

Automation & Control (requires workspace config)
    Change tracking                ChangeTracking
    Update management

Security & compliance
    Antimalware Assessment         AntiMalware
    Security and Audit             Security  

Protection & Recovery
    Backup
    Azure Site recovery

Active directory health check

#>

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function get-AutomationContext (){
    Write-Verbose "Getting automation context"
    #$AutomationContextFile = "C:\_Repo\p3ops-tile\SvenTests\scripts\AutomationContext.json"
    $Context = Get-Content $AutomationContextFile | ConvertFrom-Json
    return $Context
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Clear-Host
Write-Output "Start script - version $($ScriptVersion)"

$Context = $null

if ($AutomationContextFile){

    # A context file was provided, get info to login to Azure
    $Context = get-AutomationContext
    $Serviceprincipal = $Context.ServicePrincipal.ApplicationId
    $ServicePrincipalPassword = $Context.ServicePrincipalPassword 
    $TenantID = $Context.Context.Tenant.TenantId
    
    # With the retrieved ApplicationId and secure password we can create a credential object
    $Securepassword = ConvertTo-SecureString -Force -AsPlainText -String $ServicePrincipalPassword
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential($Serviceprincipal, $Securepassword)
    #$cred = New-Object -TypeName System.Management.Automation.PSCredential($userId ,$password)

    # Finally we use this object to login on Azure with this credential object
    Write-Verbose "Login on Azure, using serviceprincipal"
    Connect-AzureRmAccount -ServicePrincipal -Credential $Credential -TenantId $TenantID

} else {
    
    # No context file was provided, login to Azure by asking credentials
    Write-Verbose "Login on to Azure"
    Login-AzureRmAccount
}

Write-Verbose "Create the resource group"
New-AzureRmResourceGroup -Name $ResourceGroup -Location $Location -Force

Write-Verbose "Creating workspace $($OMSWorkspaceName) in the $($Sku) tier"
$OMSWorkspace = New-AzureRmOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $OMSWorkspaceName -Location $Location -Sku $Sku -Force

Write-Verbose "Activate the Azure Automation solution in the workspace"
Write-Verbose "Adding Intelligence packs"
foreach ($ip in $IntelligencePacks){
    Write-Verbose "Adding $($ip)"
    $null = Set-AzureRmOperationalInsightsIntelligencePack -ResourceGroupName $ResourceGroup -WorkspaceName $OMSWorkspaceName -IntelligencePackName $ip -Enabled $true
}

Write-Verbose "Saving specs to $($AutomationContextFile)"
$Workspace = New-Object psobject -Property @{
    OMSWorkspaceId = $OMSWorkspace.CustomerId
    OMSWorkspaceKeys = Get-AzureRmOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $OMSWorkspace.ResourceGroupName -Name $OMSWorkspace.Name
    OMSWorkSpace = $OMSWorkspace
}
$Context | Add-Member -NotePropertyName "Workspace" -NotePropertyValue $Workspace
$Context | ConvertTo-Json | Out-File $AutomationContextFile
