<#
.SYNOPSIS
  Script to deploy a Remote Desktop environment

.DESCRIPTION
  This script will deploy an RDS environment. First the script will try to remote to all provided servers. Then it will install the required roles on the servers
  After the deployment the licensing will be set to per user licensing.

.PARAMETER RDSBroker
  The name of the broker server

.PARAMETER RDSWebAcces
  The name of the web access server

.PARAMETER RDSHost <TODO array of hosts>
  The name of the RDS host

.PARAMETER RDSLicense
  The name of the RDS Licensen server

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  3/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  .\InstallRoles -Name RDS-RD-Server -verbose
#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
        [parameter(mandatory = $true)][String[]]$Roles
)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

$Nummer = Get-Date -UFormat "%Y-%m-%d %H-%M-%S"
$Nummer
$Log = "$($env:TEMP)\DeployRDS$($Nummer).log"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ScriptVersion = "0.1"

#-----------------------------------------------------------[Functions]------------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Clear-Host
Start-Transcript -Path $Log -NoClobber
$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()
Write-Output "Start script - version $($ScriptVersion)"


Install-WindowsFeature -Name $Roles

#-----------------------------------------------------------[Finish up]------------------------------------------------------------
Write-Output $StopWatch.Elapsed

$StopWatch.Stop()
Write-Output "Finished installing RDS roles"
Stop-Transcript