<#
.SYNOPSIS
  Script to create a share

.DESCRIPTION
  This script creates a share

.PARAMETER ShareName
  The name of the broker server

.PARAMETER Path
  specifies the path where to create the share

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  10/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  .\CreateShare.ps1 -ShareName Data -Path c:\data -Verbose
#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
        [parameter(mandatory = $true)][String]$ShareName,
        [parameter(mandatory = $true)][String]$Path
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ScriptVersion = "0.1"
#$ShareName = "data"

#-----------------------------------------------------------[Functions]------------------------------------------------------------


#-----------------------------------------------------------[Execution]------------------------------------------------------------

Clear-Host
Write-Output "Start script - version $($ScriptVersion)"

if (-not(Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)){
    Write-Verbose "Share $($ShareName) does not exist"
    if (-not(Test-Path $Path)){
        Write-Verbose "Path $($Path) does not exist, creating..."
        New-Item -ItemType Directory -Force -Path $Path
    }
    Write-Verbose "Create share"
    New-SmbShare -Name $ShareName -Path $Path -ReadAccess 'Authenticated Users'
} else {
    Write-Output "Share $($ShareName) already exists"
}