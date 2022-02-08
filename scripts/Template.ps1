<#
.SYNOPSIS
  Script to request a certificate

.DESCRIPTION
  This script will request a certificate with Letsencrypt.

.PARAMETER RDSBroker
  The name of the broker server

.PARAMETER RDSWebAcces
  The name of the web access server

.PARAMETER RDSHost <TODO array of hosts>
  The name of the RDS host

.PARAMETER RDSLicense
  The name of the RDS Licensen server

.OUTPUTS
  A log file in the temp directory

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  3/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  .\DeployRDS.ps1 -RDSBroker dc1.tile.lan -RDSWebAccess rdswa1.tile.lan -RDSHost rds1.tile.lan -RDSLicense dc1.tile.lan -Verbose
#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
        [parameter(mandatory = $false)][String]$Param1
)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

$Nummer = Get-Date -UFormat "%Y-%m-%d@%H-%M-%S"
$Log = "$($env:TEMP)\$($MyInvocation.MyCommand.Name) $($Nummer).log"

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





#-----------------------------------------------------------[Finish up]------------------------------------------------------------
Write-Output $StopWatch.Elapsed

$StopWatch.Stop()
Write-Output "Finished $($MyInvocation.MyCommand.Name)"
Stop-Transcript