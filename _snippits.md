# Snippits

## Router
```
  config.vm.define 'router' do |router |
    router.vm.box = ROUTER_BASE_BOX
    router.vm.network :private_network,
      ip: '192.0.2.254',
      netmask: '255.255.255.0'
    router.vm.network :private_network,
      ip: '172.16.255.254',
      netmask: '255.255.0.0'
    router.ssh.insert_key = false

    router.vm.provision "shell" do |sh|
      sh.path = "scripts/router-config.sh"
    end
  end
```

## IPv6

```
  Vagrant.configure("2") do |config|
    config.vm.network "private_network", ip: "fde4:8dba:82e1::c4"
  end
```

## IPV6 tunnel op HE.net config
```
Tunnel ID: 503311
Creation Date:Oct 14, 2018
Description:
IPv6 Tunnel Endpoints
Server IPv4 Address:216.66.84.46
Server IPv6 Address:2001:470:1f14:484::1/64
Client IPv4 Address:188.118.2.101
Client IPv6 Address:2001:470:1f14:484::2/64
Routed IPv6 Prefixes
Routed /64:2001:470:1f15:488::/64
Routed /48:2001:470:7ace::/48 [X]
DNS Resolvers
Anycast IPv6 Caching Nameserver:2001:470:20::2
Anycast IPv4 Caching Nameserver:74.82.42.42
rDNS DelegationsEdit
rDNS Delegated NS1:
rDNS Delegated NS2:
rDNS Delegated NS3:
rDNS Delegated NS4:
rDNS Delegated NS5:
```

## Enable windows host firewall

```
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol="icmpv4:
8,any" dir=in action=allow

netsh advfirewall firewall add rule name="ICMP Allow incoming V6 echo request" protocol="icmpv6:8,any" dir=in action=allow
```

```
  Vagrant.configure("2") do |config|
  config.vm.network "private_network",
    ip: "fde4:8dba:82e1::c4",
    netmask: "96"
end
```

## Configure Vagrant
		config.vm.provider "virtualbox" do |vb|
		# Display the VirtualBox GUI when booting the machine
			vb.gui = true
			vb.customize ["modifyvm", :id, "--memory", 4096]
			vb.customize ["modifyvm", :id, "--cpus", 2]
			vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]	
		end

## Azure

Login-AzureRmAccount -ServicePrincipal -ApplicationId  "http://my-app" -Credential $pscredential -TenantId $tenantid
Uitleg [hier](https://stackoverflow.com/questions/41190914/azure-provisioning-without-manual-login/41216332#41216332)

```
$azureAplicationId ="Azure AD Application Id"
$azureTenantId= "Your Tenant Id"
$azurePassword = ConvertTo-SecureString "strong password" -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($azureAplicationId , $azurePassword)
Add-AzureRmAccount -Credential $psCred -TenantId $azureTenantId  -ServicePrincipal 
```

### IntelligencePacks

https://systemcenter.wiki/?GetCategory=Microsoft+Operations+Management+Suite

To link 
https://www.verboon.info/2017/02/how-to-link-an-oms-workspace-with-an-azure-automation-account/

### Service map - supercool
Servicemap -> needs to install a dependancy agent https://aka.ms/dependencyagentwindows, https://aka.ms/dependencyagentlinux

https://docs.microsoft.com/nl-be/azure/monitoring/monitoring-service-map 

[Dependency agent](https://docs.microsoft.com/en-us/azure/monitoring/monitoring-service-map-configure) voor windows & linux

Add computer to azure/O365 https://www.youtube.com/watch?v=3ZYixicp-2k

LetsEncrypt
https://onedrive.live.com/?authkey=!AGxuu7wuvZ4Utmw&cid=6BAD75A56D4DD590&id=6BAD75A56D4DD590!881465&parId=6BAD75A56D4DD590!862272&o=OneUp 


### Runbooks
```
$password =  ConvertTo-SecureString "[your admin account user password]" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\[your admin account]", $password)
$command = $file = $PSScriptRoot + "\CustomScriptSQLPS.ps1"
Enable-PSRemoting –force
Invoke-Command -FilePath $command -Credential $credential -ComputerName $env:COMPUTERNAME
Disable-PSRemoting -Force


Start-AzureRmAutomationRunbook –AutomationAccountName "MyAutomationAccount" –Name "Test-Runbook" -RunOn "MyHybridGroup"

$Cred = Get-AutomationPSCredential -Name "MyCredential"
$Computer = Get-AutomationVariable -Name "ComputerName"

Restart-Computer -ComputerName $Computer -Credential $Cred
```

### Azure AD / RDS deployment

[https://docs.microsoft.com/en-us/azure/active-directory/manage-apps/application-proxy-integrate-with-remote-desktop-services](https://docs.microsoft.com/en-us/azure/active-directory/manage-apps/application-proxy-integrate-with-remote-desktop-services)

[http://embedyoutube.org/](http://embedyoutube.org/)

### Commands

```powershell
.\DeployRDS.ps1 -RDSBroker dc1.teamtile.be -RDSWebAccess rds1.teamtile.be -RDSHost rds1.teamtile.be -RDGateway rds1.teamtile.be -ExternalFQDN portal.teamtile.be -RDSLicense dc1.teamtile.be -Certificate C:\vagrant_data\scripts\cert.pfx -CertificatePassword poshacme -Verbose
```