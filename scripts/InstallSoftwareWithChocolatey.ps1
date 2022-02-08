
<#
.SYNOPSIS
  Script to install application via Chocolatey

.DESCRIPTION
  This script accepts a list of names of software to install with Chocolatey. If Chocolatey is not installed yet, it will be installed first.

.PARAMETER ApplicationList
  A list of software to install

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  3/11/2018
  Purpose/Change: Initial script development
  
.EXAMPLE
  ./InstallSoftwareWithChocolatey -ApplicationList smartty3, firefox, googlechrome, awscli -verbose
  ./InstallSoftwareWithChocolatey -ApplicationList office365proplus
#>

#requires -version 3.0
#Requires -RunAsAdministrator

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
    [parameter(mandatory=$true)][string[]]$ApplicationList
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

Function InstallChoco(){
    Write-Verbose "Install Chocolatey"
    Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Output "Start script - version $($ScriptVersion)"

If (-not(Test-Path -Path "$env:ProgramData\Chocolatey")) {
    Write-Verbose "Chocolatey is not installed"
    InstallChoco
}

foreach ($Application in $ApplicationList){
    Write-Output "Installing $($Application)"
    choco install $Application -y

}