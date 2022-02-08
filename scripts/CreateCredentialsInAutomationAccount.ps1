<#
.SYNOPSIS
  Script to add Automation Credentials to an automation account.

.DESCRIPTION
  This script create an Automation Credential in an automation account, these credentials can be used by the automation account. 

.PARAMETER AutomationCredentialName
  Specifies the name of the automation credential. This is the name of the credential that the other scripts refer to.

.PARAMETER UserName
  Specifies the username

.PARAMETER DomainName
  Specifies the domainname

.PARAMETER Sku
  Specifies the password

.PARAMETER AutomationContextFile
  Points to the AutomationContextFile.

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  11/10/2018
  Purpose/Change: Initial script development

.EXAMPLE
  .\CreateCredentialsInAutomationAccount.ps1 -AutomationContextFile .\AutomationContext.json -AutomationCredentialName mycredential -Verbose

.EXAMPLE
  .\CreateCredentialsInAutomationAccount.ps1 -AutomationContextFile .\AutomationContext.json -UserName Sven -Password mypassword -AutomationCredentialName mycredential -Verbose

.EXAMPLE
  .\CreateCredentialsInAutomationAccount.ps1 -AutomationContextFile .\AutomationContext.json -UserName Sven -Password mypassword -AutomationCredentialName mycredential -DomainName tile.lan -Verbose

#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
    [parameter(mandatory=$true)][string]$AutomationContextFile,
    [parameter(mandatory=$true)][string]$AutomationCredentialName,
    [parameter(mandatory=$false)][string]$UserName = "administrator",
    [parameter(mandatory=$false)][string]$DomainName,
    [parameter(mandatory=$false)][string]$Password = "vagrant"
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

function get-AutomationContext (){
    Write-Verbose "Getting automation context"
    #$AutomationContextFile = "C:\_Repo\p3ops-tile\Sven\scripts\AutomationContext.json"
    $Context = Get-Content $AutomationContextFile | ConvertFrom-Json
    return $Context
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Clear-Host
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
    #$cred = New-Object -TypeName System.Management.Automation.PSCredential($userId ,$password)

    # Finally we use this object to login on Azure with this credential object
    Write-Verbose "Login on Azure, using serviceprincipal"
    Connect-AzureRmAccount -ServicePrincipal -Credential $Credential -TenantId $TenantID

} else {
    Write-Error "This script is meant to be used with an automationContext"
    # No context file was provided, login to Azure by asking credentials
    # Write-Verbose "Login on to Azure"
    # Login-AzureRmAccount
}

Write-Verbose "Get Automation account"
Get-AzureRmAutomationAccount -ResourceGroupName $Context.AutomationAccount.ResourceGroupName -Name $Context.AutomationAccount.AutomationAccountName

Write-Verbose "Create credentials"
if ($DomainName){
    $Split = $DomainName.Split(".")
    $UserName = $Split[0] + "\" + $UserName
}

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, (ConvertTo-SecureString $Password -AsPlainText -Force)

Write-Verbose "Store credentials in Automation account"
New-AzureRmAutomationCredential -AutomationAccountName $Context.AutomationAccount.AutomationAccountName -Name $AutomationCredentialName -Value $Credential -ResourceGroupName $context.AutomationAccount.ResourceGroupName