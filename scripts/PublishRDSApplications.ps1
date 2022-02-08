<#
.SYNOPSIS
  Script to publish applications in a RDS environment

.DESCRIPTION
  This script try to get the Session Collection specified. If it fails, the script will create the session collection.
  The script will publish the specified applications in the Session Collection. 
  To get a list of availlable applictions for the session collection run Get-RDAvailableApp
  IE Get-RDAvailableApp -CollectionName $SessionCollectionName -ConnectionBroker $RDSBroker

.PARAMETER RDSBroker
  The name of the broker server

.PARAMETER SessionCollectionName
  The name of the Session Collection

.PARAMETER SessionCollectionDescription
  The description for the Session Collection

.PARAMETER SessionCollectionHosts
  An array of RDS servers used by the session collection

.PARAMETER Applications
  A hashtable of applications to publish

.PARAMETER UserGroup
  The user group allowed to access the collection

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  10/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  .\PublishRDSApplications.ps1 -SessionCollectionName "UserCollection" -SessionCollectionDescription "A collection for users" -SessionCollectionHosts @("rds1.tile.lan") -RDSBroker "dc1.tile.lan" -Applications @{SmarTTY="C:\Program Files (x86)\Sysprogs\SmarTTY\SmarTTY.exe"; Chrome="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"} -Verbose
#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
        [parameter(mandatory = $true)][String]$SessionCollectionName,
        [parameter(mandatory = $true)][String]$SessionCollectionDescription,
        [parameter(mandatory = $true)][String[]]$SessionCollectionHosts,
        [parameter(mandatory = $true)][String]$RDSBroker,
        [parameter(mandatory = $true)][Hashtable]$Applications = @{SmarTTY="C:\Program Files (x86)\Sysprogs\SmarTTY\SmarTTY.exe"; Chrome="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"}
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

$Nummer = Get-Date -UFormat "%Y-%m-%d@%H-%M-%S"
$Log = "$($env:TEMP)\PublishApps $($Nummer).log"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ScriptVersion = "0.1"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function tryRemoting{
    param(
        [parameter(mandatory = $true)][String]$server
    )
    Write-verbose "Trying $($server)"
    $response = Test-WSMan -ComputerName $server -Authentication Default
    Write-Verbose $response.productversion
    $response
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Clear-Host
Start-Transcript -Path $Log -NoClobber
$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()
Write-Output "Start script - version $($ScriptVersion)"

Import-Module RemoteDesktop

$SessionCollection = $null

try {
    $SessionCollection = Get-RDSessionCollection -CollectionName $SessionCollectionName -ConnectionBroker $RDSBroker -ErrorAction SilentlyContinue
} catch {
    Write-Verbose "Session collection $($SessionCollectionName) doesn't exist"
}

if (-not($SessionCollection)){
    Write-Verbose "Creating collection $($SessionCollectionName) with broker $($RDSBroker)"
    $SessionCollection = New-RDSessionCollection -CollectionName $SessionCollectionName -SessionHost $SessionCollectionHosts -CollectionDescription $SessionCollectionDescription -ConnectionBroker $RDSBroker
}

foreach ($key in $Applications.Keys){
    
    Write-Verbose "Adding the application $($key)"
    New-RDRemoteApp -Alias $key -DisplayName $key -FilePath $Applications[$key] -ShowInWebAccess 1 -CollectionName $SessionCollectionName -ConnectionBroker $RDSBroker -ErrorAction SilentlyContinue
}

Write-Output $StopWatch.Elapsed

$StopWatch.Stop()
Write-Output "Finished publishing applications"
Stop-Transcript
