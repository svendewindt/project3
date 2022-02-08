
<#
.SYNOPSIS
  Script to create Office 365 DNS records in Azure

.DESCRIPTION
  This script will create the records needed by Office 365 for a specific tenant in Azure

.PARAMETER DomainName
  Specifies the domain name where the records need to be created

.PARAMETER ResourceGroupName
  Specifies the resource group name in Azure

.PARAMETER MxToken
  Specifies the MxToken. This is a value like MSxxxxxxx and can be found in the Office 365 portal

.PARAMETER AutomationContextFile
  Points to the AutomationContextFile

.PARAMETER TXTVerificationRecord
  If specified, the script will create a TXT record with this value to prove domain ownership.

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
    [parameter(mandatory = $true)][string]$MxToken,
    [parameter(mandatory=$false)][string]$AutomationContextFile,
    [parameter(mandatory=$false)][string]$TXTVerificationRecord
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
$SPF = "v=spf1 include:spf.protection.outlook.com -all"

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

# Set DNS records per Microsoft documentation https://docs.microsoft.com/en-us/office365/admin/get-help-with-domains/create-dns-records-at-any-dns-hosting-provider?redirectSourcePath=%252fen-us%252farticle%252fcreate-dns-records-at-any-dns-hosting-provider-for-office-365-7b7b075d-79f9-4e37-8a9e-fb60c1d95166&view=o365-worldwide#add-three-cname-records

# Txt record for domain verification and spam prevention
    Write-Output "Adding txt record $($TXTVerificationRecord) for domain verification and SPF record to prevent spam prevention"
    $Records = @()
    if ($TXTVerificationRecord){
        $Records += New-AzureRmDnsRecordConfig -Value $TXTVerificationRecord
    }
    $Records += New-AzureRmDnsRecordConfig -Value $SPF
    $RecordSet = New-AzureRmDnsRecordSet -Name "@" -RecordType TXT -ResourceGroupName $ResourceGroupName -ZoneName $DomainName -TTL $TTL -DnsRecords $Records -Overwrite
    Set-AzureRmDnsRecordSet -RecordSet $RecordSet | Out-Null

# MX record to route mail
Write-Output "Adding  MX record to route mail"
$Records = @()
$Records += New-AzureRmDnsRecordConfig -Exchange "$($MxToken).mail.protection.outlook.com" -Preference 5
$RecordSet = New-AzureRmDnsRecordSet -Name "@" -RecordType MX -ResourceGroupName $ResourceGroupName -ZoneName $DomainName -Ttl $TTL -DnsRecords $Records -Overwrite
Set-AzureRmDnsRecordSet -RecordSet $RecordSet | Out-Null

# Three CNAME records to locate services
Write-Output "Adding three CNAME records to locate services"
$Records = @()
$Records += New-AzureRmDnsRecordConfig -Cname "autodiscover.outlook.com"
$RecordSet = New-AzureRmDnsRecordSet -Name "autodiscover" -RecordType CNAME -ResourceGroupName $ResourceGroupName -ZoneName $DomainName -Ttl $TTL -DnsRecords $Records -Overwrite
Set-AzureRmDnsRecordSet -RecordSet $RecordSet | Out-Null

$Records = @()
$Records += New-AzureRmDnsRecordConfig -Cname "webdir.online.lync.com"
$RecordSet = New-AzureRmDnsRecordSet -Name "lyncdiscover" -RecordType CNAME -ResourceGroupName $ResourceGroupName -ZoneName $DomainName -Ttl $TTL -DnsRecords $Records -Overwrite
Set-AzureRmDnsRecordSet -RecordSet $RecordSet | Out-Null

$Records = @()
$Records += New-AzureRmDnsRecordConfig -Cname "sipdir.online.lync.com"
$RecordSet = New-AzureRmDnsRecordSet -Name "sip" -RecordType CNAME -ResourceGroupName $ResourceGroupName -ZoneName $DomainName -Ttl $TTL -DnsRecords $Records -Overwrite
Set-AzureRmDnsRecordSet -RecordSet $RecordSet | Out-Null

# Two CNAME records for Mobile Device Management (MDM)
Write-Output "Adding two CNAME records for Mobile Device Management (MDM)" 
$Records = @()
$Records += New-AzureRmDnsRecordConfig -Cname "enterpriseregistration.windows.net"
$RecordSet = New-AzureRmDnsRecordSet -Name "enterpriseregistration" -RecordType CNAME -ResourceGroupName $ResourceGroupName -ZoneName $DomainName -Ttl $TTL -DnsRecords $Records -Overwrite
Set-AzureRmDnsRecordSet -RecordSet $RecordSet | Out-Null

$Records = @()
$Records += New-AzureRmDnsRecordConfig -Cname "enterpriseenrollment-s.manage.microsoft.com"
$RecordSet = New-AzureRmDnsRecordSet -Name "enterpriseenrollment" -RecordType CNAME -ResourceGroupName $ResourceGroupName -ZoneName $DomainName -Ttl $TTL -DnsRecords $Records -Overwrite
Set-AzureRmDnsRecordSet -RecordSet $RecordSet | Out-Null

# Two SRV record for Skype For Business (SFB)
Write-Output "Adding two SRV record for Skype For Business (SFB)"
$Records = @()
$Records += New-AzureRmDnsRecordConfig -Priority 100 -Weight 1 -Port 443 -Target "sipdir.online.lync.com"
$RecordSet = New-AzureRmDnsRecordSet -Name "_sip._tls" -RecordType SRV -ResourceGroupName $ResourceGroupName -ZoneName $DomainName -Ttl $TTL -DnsRecords $Records -Overwrite
Set-AzureRmDnsRecordSet -RecordSet $RecordSet | Out-Null

$Records = @()
$Records += New-AzureRmDnsRecordConfig -Priority 100 -Weight 1 -Port 5061 -Target "sipfed.online.lync.com"
$RecordSet = New-AzureRmDnsRecordSet -Name "_sipfederationtls._tcp" -RecordType SRV -ResourceGroupName $ResourceGroupName -ZoneName $DomainName -Ttl $TTL -DnsRecords $Records -Overwrite
Set-AzureRmDnsRecordSet -RecordSet $RecordSet | Out-Null