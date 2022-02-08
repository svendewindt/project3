
<#
.SYNOPSIS
  Script to add a zone to Windows dns

.DESCRIPTION
  This script will add a zone to a DNS server

.PARAMETER ZoneName
  The name name of the forward lookup zone to add.

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  4/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  ./AddZone -ZoneName wotas.be -verbose

#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
    [parameter(mandatory = $true)][string]$ZoneName
)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ScriptVersion = "0.1"

#-----------------------------------------------------------[Functions]------------------------------------------------------------



#-----------------------------------------------------------[Execution]------------------------------------------------------------

Clear-Host
Write-Output "Start script - version $($ScriptVersion)"

Write-Output "Adding $($ZoneName) as forward lookup zone in DNS server"

Add-DnsServerPrimaryZone -Name $ZoneName -ReplicationScope "Forest" -PassThru
