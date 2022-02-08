<#
.SYNOPSIS
  Script to deploy a Remote Desktop environment

.DESCRIPTION
  This script will deploy an RDS environment. First the script will try to remote to all provided servers. Then it will install the required roles on the servers
  After the deployment the licensing will be set to per user licensing.

.PARAMETER RDSBroker
  The name of the broker server

.PARAMETER RDSWebAcces
  The name of the web access server

.PARAMETER RDSHost
  The name of the RDS host

.PARAMETER RDSLicense
  The name of the RDS Licensen server

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  3/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  .\DeployRDS.ps1 -RDSBroker dc1.tile.lan -RDSWebAccess rdswa1.tile.lan -RDSHost rds1.tile.lan -RDSLicense dc1.tile.lan -Verbose

.EXAMPLE
  .\DeployRDS.ps1 -RDSBroker rds1.wotas.be -RDSWebAccess rds1.wotas.be -RDSHost rds1.wotas.be -RDSLicense dc1.wotas.be -Verbose

.EXAMPLE
  .\DeployRDS.ps1 -RDSBroker rds1.teamtile.be -RDSWebAccess rds1.teamtile.be -RDSHost rds1.teamtile.be -RDSLicense dc1.teamtile.be -RDGateway rds1.teamtile.be -ExternalFQDN portal.teamtile.be -Verbose

.EXAMPLE
  .\DeployRDS.ps1 -RDSBroker rds1.teamtile.be -RDSWebAccess rds1.teamtile.be -RDSHost rds1.teamtile.be -RDSLicense dc1.teamtile.be -RDGateway rds1.teamtile.be -ExternalFQDN portal.teamtile.be -Verbose

#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
        [parameter(mandatory = $true)][String]$RDSBroker,
        [parameter(mandatory = $true)][String]$RDSWebAccess,
        [parameter(mandatory = $true)][String]$RDSHost,
        [parameter(mandatory = $true)][String]$RDGateway,
        [parameter(mandatory = $false )][String]$ExternalFQDN,
        [parameter(mandatory = $true)][String]$RDSLicense,
        [parameter(mandatory = $false)][String]$Certificate,
        [parameter(mandatory = $false)][string]$CertificatePassword
)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

$Nummer = Get-Date -UFormat "%Y-%m-%d@%H-%M-%S"
$Log = "$($env:TEMP)\DeployRDS $($Nummer).log"

# if no external fqdn is passed, point it to the gateway
if (-not($ExternalFQDN)){
    $ExternalFQDN = $RDGateway
}

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ScriptVersion = "0.1"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function tryRemoting{
    param(
        [parameter(mandatory = $true)][String]$server
    )
    Write-output "Trying $($server)"
    $response = Test-WSMan -ComputerName $server -Authentication Default
    Write-output $response.productversion
    $response
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Clear-Host
Start-Transcript -Path $Log -NoClobber
$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()
Write-Output "Start script - version $($ScriptVersion)"

Write-Output "RDSBroker:    $($RDSBroker)"
Write-Output "RDSWebAccess: $($RDSWebAccess)"
Write-Output "RDSHost:      $($RDSHost)"
Write-Output "RDGateway:    $($RDGateway)"
Write-Output "RDSLicense:   $($RDSLicense)"
Write-Output "Certificate:  $($Certificate)"


$servers = $RDSBroker, $RDSWebAccess, $RDSHost,$RDGateway, $RDSLicense

Write-Output "Trying to remote to the servers"
Write-Output "If any errors occur here, the script will stop."
$identity = & whoami
Write-output "running as $($identity)"
    foreach ($server in $servers){
       tryRemoting -server $server
    }

Write-Output "All servers are accessible, continuing"
Write-Output $StopWatch.Elapsed
Write-output "Import RemoteDesktop powershell module"
Import-Module RemoteDesktop

    Write-Output "Setting up session deployment"
    New-RDSessionDeployment -ConnectionBroker $RDSBroker -WebAccessServer $RDSWebAccess -SessionHost $RDSHost -PipelineVariable pvar

    Write-Output "Finished RDS deployment"
    Write-Output "Adding License server"

    Add-RDServer -Server $RDSLicense -Role RDS-LICENSING -ConnectionBroker $RDSBroker
    Write-Output $StopWatch.Elapsed

    Write-Output "Configuring Licensing mode per user"
    Set-RDLicenseConfiguration -LicenseServer $RDSLicense -Mode PerUser -ConnectionBroker $RDSBroker -Force

    Write-Output "Configuring Remote Desktop Gateway server"
    Add-RDServer -Server $RDGateway -Role RDS-GATEWAY -ConnectionBroker $RDSBroker -GatewayExternalFqdn $ExternalFQDN
    Set-RDDeploymentGatewayConfiguration -GatewayMode custom -GatewayExternalFqdn $RDGateway -LogonMethod AllowUserToSelectDuringConnection -UseCachedCredentials $true -BypassLocal $true -ConnectionBroker $RDSBroker -Force

if ($Certificate -and $CertificatePassword){
    Write-Output "Apply certificate"
    $SecurePassword = ConvertTo-SecureString $CertificatePassword -AsPlainText -Force
    Set-RDCertificate -Role RDPublishing -ImportPath $Certificate -Password $SecurePassword -ConnectionBroker $RDSBroker -Force
    Set-RDCertificate -Role RDGateway -ImportPath $Certificate -Password $SecurePassword -ConnectionBroker $RDSBroker -Force
    Set-RDCertificate -Role RDRedirector -ImportPath $Certificate -Password $SecurePassword -ConnectionBroker $RDSBroker -Force
    Set-RDCertificate -Role RDWebAccess -ImportPath $Certificate -Password $SecurePassword -ConnectionBroker $RDSBroker -Force
}


Write-Output $StopWatch.Elapsed

$StopWatch.Stop()
Write-Output "Finished installing RDS roles"
Stop-Transcript