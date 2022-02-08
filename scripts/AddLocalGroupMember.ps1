<#
.SYNOPSIS
  Script to add a local group member

.DESCRIPTION
  This script will add a member to a local group

.PARAMETER LocalGroup
  The local group. You can find all local groups with the 'Get-LocalGroup' cmdlet

.PARAMETER Member
  Specifies the member to add to the local group

.OUTPUTS
  A log file in the temp directory

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  28/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  .\AddLocalGroupMember.ps1 -LocalGroup "Remote Desktop Users" -Member "teamtile\teamtile"
#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
    [parameter(mandatory = $true)][String]$LocalGroup,
    [parameter(mandatory = $true)][String]$Member
    
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

Add-LocalGroupMember -Group $LocalGroup -Member $Member

#-----------------------------------------------------------[Finish up]------------------------------------------------------------

Write-Output $StopWatch.Elapsed

$StopWatch.Stop()
Write-Output "Finished $($MyInvocation.MyCommand.Name)"
Stop-Transcript