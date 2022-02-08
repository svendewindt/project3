# One Vagrantfile to rule them all!
#
# This is a generic Vagrantfile that can be used without modification in
# a variety of situations. Hosts and their properties are specified in
# `vagrant-hosts.yml`. Provisioning is done by an Ansible playbook,
# `ansible/site.yml`.
#
# See https://github.com/bertvv/ansible-skeleton/ for details

require 'rbconfig'
require 'yaml'

# set default LC_ALL for all BOXES
ENV["LC_ALL"] = "en_US.UTF-8"

# Set your default base box here
DEFAULT_BASE_BOX = 'bento/centos-7.5'

# When set to `true`, Ansible will be forced to be run locally on the VM
# instead of from the host machine (provided Ansible is installed).
FORCE_LOCAL_RUN = false

#
# No changes needed below this point
#

VAGRANTFILE_API_VERSION = '2'
PROJECT_NAME = '/' + File.basename(Dir.getwd)

# set custom vagrant-hosts file
vagranthosts = ENV['VAGRANTS_HOST'] ? ENV['VAGRANTS_HOST'] : 'vagrant-hosts.yml'
hosts = YAML.load_file(File.join(__dir__, vagranthosts))

# {{{ Helper functions

def provision_ansible(config, host)
  if run_locally?
    ansible_mode = 'ansible_local'
  else
    ansible_mode = 'ansible'
  end
  
  # Provisioning configuration for Ansible (for Mac/Linux hosts).
  config.vm.provision ansible_mode do |ansible|
    ansible.playbook = host.key?('playbook') ?
        "ansible/#{host['playbook']}" :
        "ansible/site.yml"
    ansible.become = true
  end
end

def run_locally?
  windows_host? || FORCE_LOCAL_RUN
end

def windows_host?
  Vagrant::Util::Platform.windows?
end

# Set options for the network interface configuration. All values are
# optional, and can include:
# - ip (default = DHCP)
# - netmask (default value = 255.255.255.0
# - mac
# - auto_config (if false, Vagrant will not configure this network interface
# - intnet (if true, an internal network adapter will be created instead of a
#   host-only adapter)
def network_options(host)
  options = {}

  if host.key?('ip')
    options[:ip] = host['ip']
    options[:netmask] = host['netmask'] ||= '255.255.255.0'
  else
    options[:type] = 'dhcp'
  end

  options[:mac] = host['mac'].gsub(/[-:]/, '') if host.key?('mac')
  options[:auto_config] = host['auto_config'] if host.key?('auto_config')
  options[:virtualbox__intnet] = true if host.key?('intnet') && host['intnet']
  options
end

def custom_synced_folders(vm, host)
  return unless host.key?('synced_folders')
  folders = host['synced_folders']

  folders.each do |folder|
    vm.synced_folder folder['src'], folder['dest'], folder['options']
  end
end

# }}}


# Set options for shell provisioners to be run always. If you choose to include
# it you have to add a cmd variable with the command as data.
#
# Use case: start symfony dev-server
#
# example:
# shell_always:
#   - cmd: php /srv/google-dev/bin/console server:start 192.168.52.25:8080 --force
def shell_provisioners_always(vm, host)
  if host.has_key?('shell_always')
    scripts = host['shell_always']

    scripts.each do |script|
      vm.provision "shell", inline: script['cmd'], run: "always"
    end
  end
end

# }}}

# Adds forwarded ports to your Vagrant machine
#
# example:
#  forwarded_ports:
#    - guest: 88
#      host: 8080
def forwarded_ports(vm, host)
  if host.has_key?('forwarded_ports')
    ports = host['forwarded_ports']

    ports.each do |port|
      vm.network "forwarded_port", guest: port['guest'], host: port['host']
    end
  end
end

# }}}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  #config.ssh.insert_key = false

  # DC1
  config.vm.define "dc1" do |cfg|
    cfg.vm.box = "svendewindt/win2016"
		#cfg.vm.box = "d:/temp/SVDW2016.box"
		
		cfg.vm.hostname = "dc1"
		cfg.vm.guest = :windows

    cfg.winrm.transport = :plaintext
		cfg.winrm.basic_auth_only = true
		
		cfg.winrm.username = "administrator"
		cfg.winrm.password = "vagrant"
  
		cfg.vm.communicator = "winrm"
    cfg.vm.network :private_network, ip: "192.168.20.11", gateway: "192.168.20.254", virtualbox__intnet: true
    cfg.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", auto_correct: true
		
		cfg.vm.synced_folder ".", "/vagrant_data"
    cfg.vm.provision "shell", path: "scripts/InstallSoftwareWithChocolatey.ps1", privileged: true, args: " -ApplicationList dotnet4.7.2 -verbose"
    cfg.vm.provision :reload
    cfg.vm.provision "shell", path: "scripts/InstallDomain.ps1", privileged: true, args: "-DomainName teamtile.be -Password RecoveryPassword  -SetDNSForwarder Comodo -verbose"
    cfg.vm.provision "shell", path: "scripts/InstallDhcp.ps1", privileged: true, args: " -IPAddress 192.168.20.11 -SubnetMask 255.255.255.0 -StartRange 192.168.20.100 -EndRange 192.168.20.199  -Gateway 192.168.20.254 -ScopeName 'DHCP Scope' -verbose"

    cfg.vm.provision "shell", path: "scripts/SetupAd.ps1", privileged: true, args: "-Domain teamtile.be -verbose"
    cfg.vm.provision "shell", path: "scripts/AddUsers.ps1", privileged: true, args: "-CsvFile c:/vagrant_data/resources/UsersToCreate.csv -OU 'OU=Users,OU=teamtile,DC=teamtile,DC=be' -Groups teamtile -Verbose"

    cfg.vm.provision "shell", path: "scripts/InstallMonitoringAgent.ps1", privileged: true, args: " -AutomationContextFile 'C:/vagrant_data/scripts/AutomationContext.json' -AgentLocation 'c:/vagrant_data/resources/MMASetup.exe' -AddAsHybridWorker -Verbose"
    cfg.vm.provision "shell", path: "scripts/InstallDependencyAgent.ps1", privileged: true, args: " -AgentLocation 'c:/vagrant_data/resources/DASetup.exe' -verbose"

		config.vm.provider "virtualbox" do |vb|
		# Display the VirtualBox GUI when booting the machine
			vb.gui = true
			vb.customize ["modifyvm", :id, "--memory", 4096]
			vb.customize ["modifyvm", :id, "--cpus", 2]
			vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]	
		end
	end

  # DC2
  config.vm.define "dc2" do |cfg|
		cfg.vm.box = "svendewindt/win2016"
		#cfg.vm.box = "d:/temp/SVDW2016.box"
		
		cfg.vm.hostname = "dc2"
		cfg.vm.guest = :windows

    cfg.winrm.transport = :plaintext
		cfg.winrm.basic_auth_only = true
		
    cfg.winrm.username = "administrator"
		cfg.winrm.password = "vagrant"
  
		cfg.vm.communicator = "winrm"
    cfg.vm.network :private_network, ip: "192.168.20.12", gateway: "192.168.20.254", virtualbox__intnet: true
    cfg.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", auto_correct: true
		
		cfg.vm.synced_folder ".", "/vagrant_data"
    cfg.vm.provision "shell", path: "scripts/JoinDomain.ps1", privileged: true, args: " -Username administrator -Password vagrant -DomainName teamtile.be -DnsServer1 192.168.20.11 -DnsServer2 192.168.20.12 -verbose"
    cfg.vm.provision :reload
    cfg.vm.provision "shell", path: "scripts/InstallDomain.ps1", privileged: true, args: "-DomainName teamtile.be -username administrator -Password vagrant -JoinExistingDomain -SetDNSForwarder Comodo -verbose"
    cfg.vm.provision :reload
    cfg.vm.provision "shell", path: "scripts/InstallMonitoringAgent.ps1", privileged: true, args: " -AutomationContextFile 'C:/vagrant_data/scripts/AutomationContext.json' -AgentLocation 'c:/vagrant_data/resources/MMASetup.exe' -AddAsHybridWorker -Verbose"
    cfg.vm.provision "shell", path: "scripts/InstallDependencyAgent.ps1", privileged: true, args: " -AgentLocation 'c:/vagrant_data/resources/DASetup.exe' -verbose"
		
    config.vm.provider "virtualbox" do |vb|
		# Display the VirtualBox GUI when booting the machine
			vb.gui = true
			vb.customize ["modifyvm", :id, "--memory", 3072]
			vb.customize ["modifyvm", :id, "--cpus", 2]
			vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]	
		end
	end  

    # rds1
  config.vm.define "rds1" do |cfg|
		cfg.vm.box = "svendewindt/win2016"
		#cfg.vm.box = "d:/temp/SVDW2016.box"
		
		cfg.vm.hostname = "rds1"
		cfg.vm.guest = :windows

    #cfg.winrm.transport = :plaintext
		#cfg.winrm.basic_auth_only = true
		
		cfg.winrm.username = "administrator"
		cfg.winrm.password = "vagrant"
  
		cfg.vm.communicator = "winrm"
    cfg.vm.network :private_network, ip: "192.168.20.21", gateway: "192.168.20.254", virtualbox__intnet: true
    cfg.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", auto_correct: true
    cfg.vm.network :forwarded_port, guest: 443, host: 443, id: "https", auto_correct: true
		
		cfg.vm.synced_folder ".", "/vagrant_data"
    cfg.vm.provision "shell", path: "scripts/JoinDomain.ps1", privileged: true, args: " -Username administrator -Password vagrant -DomainName teamtile.be -DnsServer1 192.168.20.11 -DnsServer2 192.168.20.12 -Gateway 192.168.20.254 -verbose"
    cfg.vm.provision :reload
    cfg.vm.provision "shell", path: "scripts/InstallMonitoringAgent.ps1", privileged: true, args: " -AutomationContextFile 'C:/vagrant_data/scripts/AutomationContext.json' -AgentLocation 'c:/vagrant_data/resources/MMASetup.exe' -Verbose"
    cfg.vm.provision "shell", path: "scripts/InstallDependencyAgent.ps1", privileged: true, args: " -AgentLocation 'c:/vagrant_data/resources/DASetup.exe' -verbose"
    cfg.vm.provision "shell", path: "scripts/AddLocalGroupMember.ps1", privileged: true, args: "-LocalGroup 'Remote Desktop Users' -Member 'teamtile\teamtile'"    
    cfg.vm.provision "shell", path: "scripts/InstallSoftwareWithChocolatey.ps1", privileged: true, args: " -ApplicationList smartty3 -verbose"
    #cfg.vm.provision "shell", path: "scripts/InstallSoftwareWithChocolatey.ps1", privileged: true, args: " -ApplicationList firefox -verbose"
    cfg.vm.provision "shell", path: "scripts/InstallSoftwareWithChocolatey.ps1", privileged: true, args: " -ApplicationList googlechrome -verbose"
    #cfg.vm.provision "shell", path: "scripts/InstallSoftwareWithChocolatey.ps1", privileged: true, args: " -ApplicationList foxitreader -verbose"
    #cfg.vm.provision "shell", path: "scripts/InstallSoftwareWithChocolatey.ps1", privileged: true, args: " -ApplicationList awscli -verbose"
    cfg.vm.provision :reload
		config.vm.provider "virtualbox" do |vb|
		# Display the VirtualBox GUI when booting the machine
			vb.gui = true
      vb.customize ["modifyvm", :id, "--memory", 3072]
			vb.customize ["modifyvm", :id, "--cpus", 4]
			vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]	
		end
	end  

  # rdswa1
    config.vm.define "rdswa1" do |cfg|
		cfg.vm.box = "svendewindt/win2016"
		#cfg.vm.box = "d:/temp/SVDW2016.box"
		
		cfg.vm.hostname = "rdswa1"
		cfg.vm.guest = :windows

    #cfg.winrm.transport = :plaintext
		#cfg.winrm.basic_auth_only = true
		
		cfg.winrm.username = "administrator"
		cfg.winrm.password = "vagrant"
  
		cfg.vm.communicator = "winrm"
    cfg.vm.network :private_network, ip: "192.168.20.31", gateway: "192.168.20.254", virtualbox__intnet: true
    cfg.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", auto_correct: true
    cfg.vm.network :forwarded_port, guest: 443, host: 443, id: "https", auto_correct: true
		
		cfg.vm.synced_folder ".", "/vagrant_data"
    cfg.vm.provision "shell", path: "scripts/JoinDomain.ps1", privileged: true, args: " -Username administrator -Password vagrant -DomainName teamtile.be -DnsServer1 192.168.20.11 -DnsServer2 192.168.20.12 -Gateway 192.168.20.254 -verbose"
    cfg.vm.provision :reload
    cfg.vm.provision "shell", path: "scripts/InstallMonitoringAgent.ps1", privileged: true, args: " -AutomationContextFile 'C:/vagrant_data/scripts/AutomationContext.json' -AgentLocation 'c:/vagrant_data/resources/MMASetup.exe' -Verbose"
    cfg.vm.provision "shell", path: "scripts/InstallDependencyAgent.ps1", privileged: true, args: " -AgentLocation 'c:/vagrant_data/resources/DASetup.exe' -verbose"
		
		config.vm.provider "virtualbox" do |vb|
		# Display the VirtualBox GUI when booting the machine
			vb.gui = true
			vb.customize ["modifyvm", :id, "--memory", 2560]
			vb.customize ["modifyvm", :id, "--cpus", 2]
			vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]	
		end
	end  

      # fp1
  config.vm.define "fp1" do |cfg|
		cfg.vm.box = "svendewindt/win2016"
		#cfg.vm.box = "d:/temp/SVDW2016.box"
		
		cfg.vm.hostname = "fp1"
		cfg.vm.guest = :windows

    #cfg.winrm.transport = :plaintext
		#cfg.winrm.basic_auth_only = true
        
		cfg.winrm.username = "administrator"
		cfg.winrm.password = "vagrant"
  
		cfg.vm.communicator = "winrm"
    cfg.vm.network :private_network, ip: "192.168.20.41", gateway: "192.168.20.254", virtualbox__intnet: true
    cfg.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", auto_correct: true
		
		cfg.vm.synced_folder ".", "/vagrant_data"
    cfg.vm.provision "shell", path: "scripts/JoinDomain.ps1", privileged: true, args: " -Username administrator -Password vagrant -DomainName teamtile.be -DnsServer1 192.168.20.11 -DnsServer2 192.168.20.12 -Gateway 192.168.20.254 -verbose"
    cfg.vm.provision :reload
    cfg.vm.provision "shell", path: "scripts/InstallMonitoringAgent.ps1", privileged: true, args: " -AutomationContextFile 'C:/vagrant_data/scripts/AutomationContext.json' -AgentLocation 'c:/vagrant_data/resources/MMASetup.exe' -Verbose"
    cfg.vm.provision "shell", path: "scripts/InstallDependencyAgent.ps1", privileged: true, args: " -AgentLocation 'c:/vagrant_data/resources/DASetup.exe' -verbose"
		
		config.vm.provider "virtualbox" do |vb|
		# Display the VirtualBox GUI when booting the machine
			vb.gui = true
			vb.customize ["modifyvm", :id, "--memory", 2560]
			vb.customize ["modifyvm", :id, "--cpus", 2]
			vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]	
		end
	end 
  
  hosts.each do |host|
    config.vm.define host['name'] do |node|
      node.vm.box = host['box'] ||= DEFAULT_BASE_BOX
      node.vm.box_url = host['box_url'] if host.key? 'box_url'

      node.vm.hostname = host['name']
      node.vm.network :private_network, network_options(host)
      custom_synced_folders(node.vm, host)
      shell_provisioners_always(node.vm, host)
      forwarded_ports(node.vm, host)

      # Add VM to a VirtualBox group
      node.vm.provider :virtualbox do |vb|
        # WARNING: if the name of the current directory is the same as the
        # host name, this will fail.
        vb.customize ['modifyvm', :id, '--groups', PROJECT_NAME]
      end
      
      # Run Ansible playbook for the VM
      provision_ansible(config, host)
    end
  end
end

# -*- mode: ruby -*-
# vi: ft=ruby :
