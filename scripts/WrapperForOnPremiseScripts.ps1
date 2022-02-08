
<#
.SYNOPSIS
  Run an on premise script

.DESCRIPTION
  This script runs an on premise script from an Azure Automation Runbook

.PARAMETER AutomationCredential
  Specifies the name of the automation credential in the automation account

.PARAMETER Scriptpath
  Specifies the path, the script name and the parameters as seen on the computer that will run the script. IE c:\vagrant_data\scripts\testscript.ps1 -verbose

.PARAMETER Computer
  The name of the computer that will run the script.

.PARAMETER Json
  A powershell object that will be converted to a json object. This object contains the command, the command parameters, the computername and the credentials required to run the script

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  11/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
param(
    [CmdletBinding()]
    [parameter(Mandatory=$true)][string]$Command,
    [parameter(Mandatory=$false)][string[]]$CommandParameters,
    [parameter(Mandatory=$true)][string]$Computer
)

    if(-not($CommandParameters)){$CommandParameters = $null}

    $Json = @{
        "AutomationCredential" = "AdminTile"
        "ScriptPath" = $Command
        "Computer" = $Computer
        "CommandParameters" = $CommandParameters
    }

    $Json = $Json | ConvertTo-Json

    $JsonParams = @{
        "json" = $Json
    }

    $RBParams = @{
        AutomationAccountName = $AutomationAccountName
        ResourceGroupName = $ResourceGroupName
        Name = $RunbookName
        Parameters = $JsonParams
        RunOn = $HybridWorkerGroupName
    }

    Write-Host "Running runbook on Azure with script $($Command)" -ForegroundColor Green
    Start-AzureRmAutomationRunbook @RBParams -Wait
}

$Command = "C:\vagrant_data\scripts\AddServersToServerManager.ps1"
$CommandParameters = @("rds1.tile.lan", "rdswa1.tile.lan", "fp1.tile.lan")
$Computer = "rds1"
ExecuteRunbook -Command $Command -CommandParameters $CommandParameters -Computer $Computer

#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
    [parameter(Mandatory=$true)][object]$json
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

$Json = $Json | ConvertFrom-Json

$AutomationCredential = $Json.AutomationCredential
$Command = $Json.ScriptPath
$CommandParameters = $Json.CommandParameters
$Computer = $Json.Computer

Write-Output "Getting credential $($AutomationCredential)"
$Credential = Get-AutomationPSCredential -Name $AutomationCredential

$ScriptBlock = "Invoke-Expression '$($Command) $($CommandParameters)'"
Write-Output $ScriptBlock
$ScriptBlock = [scriptblock]::Create($ScriptBlock)

Write-Output "Starting script $($Command) on $($Computer) as $($Credential.UserName)"
Invoke-Command -ScriptBlock $ScriptBlock -ComputerName $Computer -Credential $Credential


