
<#
.SYNOPSIS
  Script to a cname in Azure

.DESCRIPTION
  This script will create a cname in Azure

.PARAMETER DomainName
  Specifies the domain name where the records need to be created

.PARAMETER ResourceGroupName
  Specifies the resource group name in Azure

.PARAMETER Record
  Specifies the name of the portal

.PARAMETER target
  Specifies the target of the portal, where the cname will point to. If the is used for the Azure Active Directory proxy, the target might look like myapp-demotileml.msappproxy.net

.PARAMETER AutomationContextFile
  Points to the AutomationContextFile

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  4/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  .\CreateO365DNSRecordsInAzure.ps1 -DomainName demotile.ml -ResourceGroupName dns -AutomationContextFile .\AutomationContext.json -MxToken MS123456 -TXTVerificationRecord MSQQDJFMLQSJDFLQSHPFHQPS -Verbose

.EXAMPLE
  .\CreateO365DNSRecordsInAzure.ps1 -DomainName demotile.ml -ResourceGroupName dns -MxToken MS123456 -TXTVerificationRecord MSQQDJFMLQSJDFLQSHPFHQPS -Verbose
#>

#requires -version 3

#---------------------------------------------------------[Parameters]--------------------------------------------------------

[CmdletBinding()]
param(
    [parameter(mandatory = $true)][string]$DomainName,
    [parameter(mandatory = $true)][string]$ResourceGroupName,
    [parameter(mandatory = $true)][string]$Record,
    [parameter(mandatory = $true)][string]$Target,
    [parameter(mandatory=$false)][string]$AutomationContextFile
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

# Set Error Action to Stop on every error
$ErrorActionPreference = "Stop"

# Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# Script Version
$ScriptVersion = "1.0"

$TTL = 60

# Keep up with best practices
Set-StrictMode -Version latest
$ErrorActionPreference = "stop"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function get-AutomationContext (){
    Write-Verbose "Getting automation context"
    #$AutomationContextFile = "C:\_Repo\p3ops-tile\SvenTests\scripts\AutomationContext.json"
    $Context = Get-Content $AutomationContextFile | ConvertFrom-Json
    return $Context
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Clear-Host
Write-Output "Start script - version $($ScriptVersion)"

Write-host "Installing and importing necessary Azure modules"
#Install-Module azurerm -Scope CurrentUser -Force
#Import-Module AzureRm

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
    
    # No context file was provided, login to Azure by asking credentials
    Write-Verbose "Login on to Azure"
    Login-AzureRmAccount
}

Write-Verbose "Does the domain name $($DomainName) exist"

try{
    $RecordSet = Get-AzureRmDnsRecordSet -ZoneName $DomainName -ResourceGroupName $ResourceGroupName
    #Write-Output $RecordSet
    Write-Verbose "The zone exists in Azure"
} catch {
    Write-Error $_.Exception    
}

# Create the cname
Write-Output "Add the CNAME records " 
$Records = @()
$Records += New-AzureRmDnsRecordConfig -Cname $Target
$RecordSet = New-AzureRmDnsRecordSet -Name $Record -RecordType CNAME -ResourceGroupName $ResourceGroupName -ZoneName $DomainName -Ttl $TTL -DnsRecords $Records -Overwrite
Set-AzureRmDnsRecordSet -RecordSet $RecordSet | Out-Null
