

<#
.SYNOPSIS
  Script to remove resources created in Azure for P3-Tile

.DESCRIPTION
  This script will remove all resources in the resource group provided in declarations, and it will remove the automation account

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  14/11/2018
  Purpose/Change: Initial script development
  
.EXAMPLE
  .\DeletaAzureResources -verbose

#>

#requires -version 3.0
#Requires -Modules AzureRM

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

[CmdletBinding()]
param(


)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ScriptVersion = "0.1"
$ResourceGroupName = "Automation"
$ADApplication = "PowershellAutomation"

#-----------------------------------------------------------[Functions]------------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Clear-Host
Write-Output "Start script - version $($ScriptVersion)"

Write-host "Installing and importing necessary Azure modules"
#Install-Module azurerm -Scope CurrentUser -Force
#Import-Module AzureRm


Write-Verbose "Login on to Azure"
Add-AzureRmAccount

Write-Output "Removing resource group $($ResourceGroupName)"
Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue | Remove-AzureRmResourceGroup -Force 
Write-Output "Removing Application $($ADApplication)"
Get-AzureRmADApplication -DisplayName $ADApplication -ErrorAction SilentlyContinue | Remove-AzureRmADApplication -Force 

