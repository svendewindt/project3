<#
.SYNOPSIS
  Script to upload a Runbook to an Azure Automation Account

.DESCRIPTION
  This script will create an new operations manager workspace (OMS) in Azure. 

.PARAMETER Scriptpath
  Specifies the script to upload

.PARAMETER Description
  Specifies the description for the script

.PARAMETER AutomationContextFile
  Optional. Points to the AutomationContextFile.

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  13/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  .\UploadRunbook.ps1 -AutomationContextFile .\AutomationContext.json -ScriptPath .\WrapperForOnPremiseScripts.ps1 -Description "Wrapper to run scripts on premise" -Verbose

#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
    [parameter(mandatory=$true)][string]$AutomationContextFile,
    [parameter(mandatory=$true)][string]$ScriptPath,
    [parameter(mandatory=$true)][string]$Description
)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ScriptVersion = "0.1"
#$FileNameContext = "AutomationContext.json"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function get-AutomationContext (){
    Write-Verbose "Getting automation context"
    $Context = Get-Content $AutomationContextFile | ConvertFrom-Json
    return $Context
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Output "Start script - version $($ScriptVersion)"

$Context = $null

if ($AutomationContextFile){

    # A context file was provided, get info to login to Azure
    $Context = get-AutomationContext
    $Serviceprincipal = $Context.ServicePrincipal.ApplicationId
    $ServicePrincipalPassword = $Context.ServicePrincipalPassword 
    $TenantID = $Context.Context.Tenant.TenantId
    
    # With the retrieved ApplicationId and secure password we can create a credential object
    $Securepassword = ConvertTo-SecureString -Force -AsPlainText -String $ServicePrincipalPassword
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential($Serviceprincipal, $Securepassword)

    # Finally we use this object to login on Azure with this credential object
    Write-Verbose "Login on Azure, using serviceprincipal"
    Connect-AzureRmAccount -ServicePrincipal -Credential $Credential -TenantId $TenantID

} else {
    Write-Error "Script not meant to be run like this, use the automationContext file"
    Write-Verbose "Login on to Azure"
    Login-AzureRmAccount
}

Write-Verbose "Import runbook $($ScriptPath)"
Import-AzureRmAutomationRunbook -Path $ScriptPath -Description $Description -ResourceGroupName $Context.AutomationAccount.ResourceGroupName -Type PowerShell -AutomationAccountName $Context.AutomationAccount.AutomationAccountName -Published 
