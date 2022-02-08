#requires -version 3.0
<#
.SYNOPSIS
  Script to install and configure a dhcp server

.DESCRIPTION
  This script will install the dhcp server role and configure it with the parameters passed to the script.
  The server will also be activated in Active Directory

.PARAMETER IPAdress
    The IPv4 address of the dhcp server

.PARAMETER SubnetMask
    The subnet mask of the DHCP scope

.PARAMETER StartRange
    The start range mask of the DHCP scope

.PARAMETER EndRange
    The end range mask of the DHCP scope
    
.PARAMETER Gateway
    The gateway for the clients of the DHCP scope

.PARAMETER ScopeName
    The the name of the DHCP scope

.PARAMETER ScopeDescription
    The the description of the DHCP scope

.INPUTS
  <Inputs if any, otherwise state None>

.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  27/03/2018
  Purpose/Change: Initial script development
  
.EXAMPLE
  .\InstallDhcp.ps1 -IPAddress 10.0.2.15 -SubnetMask 255.255.255.0 -StartRange 10.0.2.101 -EndRange 10.0.2.199 -Gateway 10.0.2.1 -ScopeName "DHCP Scope" -ScopeDescription "Scope desciption"
  .\InstallDhcp.ps1 -IPAddress 10.0.2.15 -SubnetMask 255.255.255.0 -StartRange 10.0.2.101 -EndRange 10.0.2.199 -Gateway 10.0.2.1 -ScopeName "DHCP Scope" -verbose
  .\InstallDhcp.ps1 -IPAddress 192.168.38.2 -SubnetMask 255.255.255.0 -StartRange 192.168.38.101 -EndRange 192.168.38.199 -ScopeName "DHCP Scope" -verbose
#>
#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
    [parameter(mandatory=$true)][string]$IPAddress,
    [parameter(mandatory=$true)][string]$SubnetMask,
    [parameter(mandatory=$true)][string]$StartRange,
    [parameter(mandatory=$true)][string]$EndRange,
    [parameter(mandatory=$false)][string]$Gateway,
    [parameter(mandatory=$true)][string]$ScopeName,
    [parameter(mandatory=$false)][string]$ScopeDescription
)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Set-StrictMode -Version Latest

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

# Get FQDN
$ComputerName = $env:COMPUTERNAME
$DomainName = $env:USERDNSDOMAIN
$DnsName = $ComputerName  + "." + $DomainName

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function WaitForActiveDirectory (){
    while ($true) {
        try {
            Write-Verbose "Trying AD..."
            Get-ADDomain | Out-Null
            Write-Verbose "Domain is active"
            #Start-Sleep -s 120
            break
        } catch {
            Write-Verbose "Waiting 10 seconds"
            Start-Sleep -Seconds 10
        }
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Verbose "Install DHCP feature & management tools"
Install-WindowsFeature dhcp -IncludeManagementTools

Write-Verbose "Wait for Active Directory"
WaitForActiveDirectory

Write-Verbose "Authorize DHCP server in Active Directory $($DnsName) with ip address $($IPAddress)"
Add-DhcpServerInDC -DnsName $DnsName -IPAddress $IPAddress

Write-Verbose "Add the security groups DHCP users and DHCP administrators to the DHCP server"
Add-DhcpServerSecurityGroup -ComputerName $ComputerName

netsh dhcp add securitygroups

Write-Verbose "Create new scope"
Add-DhcpServerv4Scope -Name $ScopeName -StartRange $StartRange -EndRange $EndRange -SubnetMask $SubnetMask -Description $ScopeDescription -State Active


if ($Gateway){
    Write-Verbose "Set gateway"
    Set-DhcpServerv4OptionValue -Router $Gateway 
}


Write-Verbose "Set dns server and domain"
Set-DhcpServerv4OptionValue -DnsServer $IPAddress -DnsDomain $DomainName

Write-Verbose "Allow the dhcp server to perform dynamic updates"
Set-DhcpServerv4DnsSetting -ComputerName $DnsName -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $True