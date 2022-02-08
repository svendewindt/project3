<#
.SYNOPSIS
  Script to create an initial AD directory

.DESCRIPTION
  This script will setup an initial AD directory, this will look like
  \DomainName
    \Domain\
      \Groups
      \Servers
        \RDS
      \Services
      \Users

.PARAMETER DomainName
  The name of the directory

.OUTPUTS
  A log file in the temp directory

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  25/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  .\SetupAd.ps1 -Domain teamtile.be -verbose
#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
        [parameter(mandatory = $false)][String]$Domain
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

$OUPath = $Domain.Split('.')
$OUDomain = "DC=$($OUPath[0]),DC=$($OUPath[1])"


$OUsToCreate = [ordered]@{
        "$($OUPath[0])" = "$($OUDomain)";
        "Groups" = "OU=$($OUPath[0]),$($OUDomain)";
        "Servers" = "OU=$($OUPath[0]),$($OUDomain)";
        "RDS" = "OU=Servers,OU=$($OUPath[0]),$($OUDomain)";
        "Services" = "OU=$($OUPath[0]),$($OUDomain)";
        "Users" = "OU=$($OUPath[0]),$($OUDomain)"
}

foreach($OU in $OUsToCreate.Keys){
    Write-Output "Create OU $($OU)"
    $output = New-ADOrganizationalUnit -Name $OU -Path $OUsToCreate.$OU 2>&1 -ProtectedFromAccidentalDeletion $false
    #Write-Verbose $output
}

New-ADGroup -Name $OUPath[0] -Path "OU=Groups,$($OUsToCreate.'Groups')" -GroupScope Global

#-----------------------------------------------------------[Finish up]------------------------------------------------------------
Write-Output $StopWatch.Elapsed

$StopWatch.Stop()
Write-Output "Finished $($MyInvocation.MyCommand.Name)"
Stop-Transcript