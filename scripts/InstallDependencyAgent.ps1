<#
.SYNOPSIS
  Script to the Microsoft Service Map agent (MMA)

.DESCRIPTION
  This script will install the Microsoft Service Map agent on a Windows machine.
  This script needs to be run as an administrator. This agent is need for service maps in Azure.
  More info on https://docs.microsoft.com/en-us/azure/monitoring/monitoring-service-map-configure

.PARAMETER AgentLocation
  Optional. The location where to find the agent to install. If the agent is not there, it will be downloaded from the Internet.

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  24/10/2018
  Purpose/Change: Initial script development

  Version:        0.2
  Author:         Sven de Windt
  Creation Date:  2/11/2018
  Purpose/Change: Additional parameter for agent location.

.EXAMPLE
  .\InstallDependencyAgent

.EXAMPLE
  .\InstallDependencyAgent -verbose

.EXAMPLE
  .\InstallDependencyAgent -AgentLocation 'c:\vagrant_data\DASetup.exe' -verbose


#>

#requires -version 3.0
#Requires -RunAsAdministrator

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
    [parameter(mandatory = $false)][string]$AgentLocation = "$env:temp\DASetup.exe"   
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ScriptVersion = "0.2"
$AgentURL = "https://aka.ms/dependencyagentwindows"

#-----------------------------------------------------------[Functions]------------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------

Clear-Host
Write-Output "Start script - version $($ScriptVersion)"

Write-Output "Downloading and installing agent"

$Destination = $AgentLocation

if (-not (Test-Path $Destination)){
    Write-Verbose "Setup files not found, downloading..."
    $null = Invoke-WebRequest -uri $AgentURL -OutFile $Destination
    $null = Unblock-File $Destination
} else {
        Write-Verbose "Setup files already preset, skip download"
}
# Install the MMA
Write-Verbose "Installing Microsoft Dependency Agent"
$Command = $Destination
$Parameters = "/S", "/AcceptEndUserLicenseAgreement:1"
Start-Process -FilePath $Command -ArgumentList $Parameters -Wait

Write-Output "Agent installed"
    