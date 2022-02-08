
<#
.SYNOPSIS
  Script to add a list of servers to Server Manager

.DESCRIPTION
  This script will add a list of servers to servermanager. This is not possible with powershell commands. The script will modify the xml file used by Server Manager.

.PARAMETER Servers
  A list of servers to add to Server Manager

.PARAMETER Username
  The xml file is stored in %AppData%\roaming per user. The default username is Administrator

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  3/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  ./AddServersToServerManager -Servers dc2.tile.lan, rds1.tile.lan, rdswa1.tile.lan, fp1.tile.lan -verbose

.EXAMPLE
  ./AddServersToServerManager -Servers dc2.tile.lan, -Username vagrant -verbose

#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
    [parameter(mandatory = $true)][string[]]$Servers,
    [parameter(mandatory = $false)][string]$Username = "Administrator"
)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

$Nummer = Get-Date -UFormat "%Y-%m-%d@%H-%M-%S"
$Nummer
$Log = "$($env:TEMP)\AddServersToServerManager $($Nummer).log"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ScriptVersion = "0.1"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Add-Server (){
param(
    [CmdletBinding()]
    [parameter(mandatory = $true)][string]$Server
)

    Write-Verbose "Adding server $($Server)"
    $NewServer = @($xml.ServerList.ServerInfo)[0].clone()
    $NewServer.name = $Server 
    $NewServer.lastUpdateTime = “0001-01-01T00:00:00” 
    $NewServer.status = “2”

    $xml.ServerList.AppendChild($newserver)
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Start-Transcript -Path $Log -NoClobber
$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()
Write-Output "Start script - version $($ScriptVersion)"

Write-Output "Adding servers $($Servers)"

Write-Verbose "Reading Server Manager xml file for user $($Username)"

Try{
    $File = Get-Item "$($env:SystemDrive)\users\$($Username)\AppData\Roaming\Microsoft\Windows\ServerManager\ServerList.xml"
} Catch {
    Write-Output "Cannot open xml file"
    Write-Error $_.exception
}

Write-Output "Create backup of the xml"
copy-item –path $file –destination $file-backup –force

Write-Output "Read xml file"
$xml = [xml] (get-content $file)

Write-Output "Close all Server Manager instances"
try {
    Get-Process ServerManager | Stop-Process –force
} catch {
    Write-Output $_.exception
}

foreach ($Server in $Servers){
    Add-Server -Server $Server
}

Write-Output "Save xml file"
$xml.Save($file.FullName)

Write-Output $StopWatch.Elapsed

$StopWatch.Stop()
Write-Output "Finished adding servers to Server Manager"
Stop-Transcript