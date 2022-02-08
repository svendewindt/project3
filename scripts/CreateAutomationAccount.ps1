
<#
.SYNOPSIS
  Script to create an automation account in Azure

.DESCRIPTION
  This script will create an automation account in Azure. It will also create a service principal to be used by powershell scripts
  Inspiration found on https://social.technet.microsoft.com/wiki/contents/articles/40062.automating-azure-login-for-powershell-scripts-using-service-principal.aspx

.PARAMETER AccountName
  Optional. The name of the automation account to create.

.PARAMETER ResourceGroup
  Optional. The name of the resource group where to create the automation account

.PARAMETER Location
  Optional. The location of the Azure data center where to create the automation account. To get all locations, run Get-AzureRmLocation

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  21/10/2018
  Purpose/Change: Initial script development
  
.EXAMPLE
  .\CreateAutomationAccount -verbose

.EXAMPLE
  .\CreateAutomationAccount -AccountName "AutomationAcccount" -verbose

.EXAMPLE
  .\CreateAutomationAccount -AccountName "AutomationAcccount" -ResourceGroup "Auto-RG" -verbose

.EXAMPLE
  .\CreateAutomationAccount -AccountName "AutomationAcccount" -ResourceGroup "Auto-RG" -Location "WestEurope" -verbose

#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
    [parameter(mandatory=$false)][string]$AccountName = "PowershellAutomation",
    [parameter(mandatory=$false)][string]$ResourceGroup = "Automation",
    [parameter(mandatory=$false)][string]$Location = "westeurope",
    [Parameter(mandatory=$false)][PSCredential] $Credential
)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ScriptVersion = "0.1"
$HomePage = "https://github.com/svendewindt"
$IdentifierUris = "https://github.com/svendewindt" + $(Get-Random -Maximum 9999)
$SecondsToWaitForServicePrincipal = 60
$FileNameContext = "AutomationContext.json"

#-----------------------------------------------------------[Functions]------------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Clear-Host
Write-Output "Start script - version $($ScriptVersion)"

Write-host "Installing and importing necessary Azure modules"
#Install-Module azurerm -Scope CurrentUser -Force
#Import-Module AzureRm


Write-Verbose "Login on to Azure"
Add-AzureRmAccount

Write-Verbose "Create the resource group"
New-AzureRmResourceGroup -Name $ResourceGroup -Location $Location -Force

Write-Verbose "Creating Automation account"
$AutomationAccount = New-AzureRmAutomationAccount -ResourceGroupName $ResourceGroup -Name $AccountName -Location $Location

Write-Verbose "Get Automation account info"
#Get-AzureRmAutomationRegistrationInfo -ResourceGroup "ResourceGroup01" -AutomationAccountName "AutomationAccount01"
$AutomationAccountInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroup $ResourceGroup -AutomationAccountName $AccountName

Write-Verbose "Creating password"

# We need to create a random password for the automation account.
Add-Type -Assembly System.Web
$Password = [System.Web.Security.Membership]::GeneratePassword(16,3)
$Securepassword = ConvertTo-SecureString -Force -AsPlainText -String $Password

Write-Verbose "Creating application in Azure"
$ADApplication = New-AzureRmADApplication -DisplayName $AccountName -HomePage $HomePage -IdentifierUris $IdentifierUris -Password $Securepassword 

Write-Verbose "Creating service principal for application"
$ServicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $ADApplication.ApplicationId -Password $Securepassword

Write-Verbose "Saving Specs"
#$Password.Guid | Out-File "password.txt" -Force
$AzureContext = Get-AzureRmContext
$Context = New-Object psobject -Property @{
    Context = $AzureContext
    AutomationAccount = $AutomationAccount
    Application = $ADApplication
    ServicePrincipal = $ServicePrincipal
    ServicePrincipalPassword = $Password
    AutomationAccountInfo = $AutomationAccountInfo
}
$Context | ConvertTo-Json | Out-File $FileNameContext

# Wait until the ServicePrincipal is ready
Write-Verbose "Wait a few seconds for the ServicePrincipal to become active"
Start-Sleep $SecondsToWaitForServicePrincipal

Write-Verbose "Assigning contributor role to service principal"
New-AzureRmRoleAssignment -ServicePrincipalName $ADApplication.ApplicationId.Guid -RoleDefinitionName Contributor