<#
.SYNOPSIS
  Script to request a certificate

.DESCRIPTION
  This script will request a certificate with Letsencrypt

.PARAMETER Labels
  The FQDN's for which a certificate will be requested. If more than 1 label is specified, the script will request a SAN certificate.

.PARAMETER EmailAddress
  Specifies the mail address to where the expiration warnings will be sent to

.PARAMETER AutomationContextFile
  Points to the AutomationContextFile.

.PARAMETER Production
  Points the script to the production server of Letsencrypt. A limited amount of requests can be asked per week

.OUTPUTS
  All files provided by New-PACertificate are stored in localappdata. IE C:\Users\Administrator\AppData\Local\Posh-ACME\acme-v02.api.letsencrypt.org\
  The .pfx file will be copied to the script root.

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  15/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  .\RequestCertificate.ps1 -Labels wotas.be, *.wotas.be -EmailAddress sven.de.windt@gmail.com -AutomationContextFile .\AutomationContext.json -Verbose

  #>

#requires -version 3.0
##Requires -Modules Posh-ACME, AzureRM

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
        [parameter(mandatory = $true)][String[]]$Labels,
        [parameter(mandatory = $true)][string]$EmailAddress,
        [parameter(mandatory=$true)][string]$AutomationContextFile,
        [switch]$Production
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
$CertificateName = "cert.pfx"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function get-AutomationContext (){
    Write-Verbose "Getting automation context"
    #$AutomationContextFile = "C:\_Repo\p3ops-tile\Sven\scripts\AutomationContext.json"
    $Context = Get-Content $AutomationContextFile | ConvertFrom-Json
    return $Context
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Clear-Host
Start-Transcript -Path $Log -NoClobber
$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()
Write-Output "Start script - version $($ScriptVersion)"


Write-Output "Install the NuGet package provider"
Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force

Write-Output "Install Powershell module AzureRM"
Install-Module azurerm -Force

Write-Output "Import Powershell module AzureRM"
Import-Module azurerm -Force

if ($AutomationContextFile){

    # A context file was provided, get info to login to Azure
    $Context = get-AutomationContext
    $Serviceprincipal = $Context.ServicePrincipal.ApplicationId
    $ServicePrincipalPassword = $Context.ServicePrincipalPassword 
    $TenantID = $Context.Context.Tenant.TenantId
    
    # With the retrieved ApplicationId and secure password we can create a credential object
    $Securepassword = ConvertTo-SecureString -Force -AsPlainText -String $ServicePrincipalPassword
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential($Serviceprincipal, $Securepassword)


} else {
    Write-Error "No Automation context provided"
    # No context file was provided, login to Azure by asking credentials
    Write-Verbose "Login on to Azure"
    Login-AzureRmAccount
}

Write-Output "Import Powershell module Posh-Acme"
Install-Module posh-acme -Force

Write-Output "Install Powershell module Posh-Acme"
Import-Module posh-acme -Force

if ($Production) {
    Write-Output "Set Letsencrypt production server"
    Set-PAServer LE_PROD
} else {
    Write-Output "Set Letsencrypt staging server"
    Set-PAServer LE_STAGE
}

$AzureParameters = @{
    AZSubscriptionId = $Context.Context.Subscription.SubscriptionId
    AZTenantId = $Context.Context.Subscription.TenantId
    AZAppCred = $Credential
}

New-PACertificate $Labels -AcceptTOS -Contact $EmailAddress -DnsPlugin Azure -PluginArgs $AzureParameters -DNSSleep 300 -Verbose

Write-Output "Moving certificate to script location $($PSScriptRoot)"
$cert = Get-ChildItem "$($env:LOCALAPPDATA)\*\$($CertificateName)" -Recurse -Verbose
$cert
copy-Item $cert "$($PSScriptRoot)\cert.pfx"

#-----------------------------------------------------------[Finish up]------------------------------------------------------------
Write-Output $StopWatch.Elapsed

$StopWatch.Stop()
Write-Output "Finished $($MyInvocation.MyCommand.Name)"
Stop-Transcript