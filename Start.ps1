#requires -version 3.0
#Requires -Modules AzureRM

param(
    [CmdletBinding()]
    [switch]$DeelAzure,
    [switch]$DeelVagrant,
    [switch]$DeelCertificate,
    [switch]$DeelRDS,
    [switch]$DeelAddServersToServerManager,
    [switch]$DeelPublishApps,
    [switch]$ToonOpties
)

$DomainName = "teamtile.be"

if ($ToonOpties){
    Write-Output "Kies een of meerdere delen"
    Write-Output "  -DeelAzure"
    Write-Output "  -DeelVagrant"
    Write-Output "  -DeelCertificate"
    Write-Output "  -DeelAddServersToServerManager"
    Write-Output "  -DeelRDS"
    Write-Output "  -DeelPublishApps"
    exit 0
}

$Nummer = Get-Date -UFormat "%Y-%m-%d %H-%M-%S"
$Nummer
$Log = "$($PSScriptRoot)\Log\Start$($Nummer).log"


function ExecuteRunbook(){
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

    Write-Output "Using these parameters:"
    Write-Output $Json

    $JsonParams = @{
        "Json" = $Json
    }

    $RBParams = @{
        AutomationAccountName = $AutomationAccountName
        ResourceGroupName = $ResourceGroupName
        Name = $RunbookName
        Parameters = $JsonParams
        RunOn = $HybridWorkerGroupName
    }

    Write-Host "Running runbook $($RunbookName) on Azure with script $($Command)" -ForegroundColor Green
    Write-Host $($RBParams | ConvertTo-Json) -ForegroundColor DarkYellow
    Start-AzureRmAutomationRunbook @RBParams -Wait
}

function RunDeelAzure(){
    Write-Host "1. Setting up Azure" -ForegroundColor Green
    Write-output "----------------------------------------------------------------"
    Write-Host "1.1. Create Azure Automation Account" -ForegroundColor Green
    $Command = "$($PSScriptRoot)\scripts\CreateAutomationAccount.ps1"
    $Parameters = "-verbose"
    Write-Output "$Command $Parameters"
    Invoke-Expression "$Command $Parameters"
    Write-Output "Elapsed Time"
    Write-Output $StopWatch.Elapsed
    Write-output "----------------------------------------------------------------"

    Write-Host "1.2. Create credentials in Azure Automation Account" -ForegroundColor Green
    $Command =  "$($PSScriptRoot)\scripts\CreateCredentialsInAutomationAccount.ps1"
    $Parameters = "-AutomationContextFile $($PSScriptRoot)\AutomationContext.json", "-UserName Administrator", "-Password vagrant", "-AutomationCredentialName AdminTile", "-DomainName $($DomainName)", "-Verbose"
    Write-Output "$Command $Parameters"
    Invoke-Expression "$Command $Parameters"
    Write-Output "Elapsed Time"
    Write-Output $StopWatch.Elapsed
    Write-output "----------------------------------------------------------------"

    Write-Host "1.3. Upload WrapperScript to Azure"
    $Command =  "$($PSScriptRoot)\scripts\UploadRunbook.ps1"
    $Parameters = "-AutomationContextFile $($PSScriptRoot)\AutomationContext.json", "-ScriptPath $($PSScriptRoot)\scripts\WrapperForOnPremiseScripts.ps1", "-Description 'Wrapper to run scripts on premise'",  "-Verbose"
    Write-Output "$Command $Parameters"
    Invoke-Expression "$Command $Parameters"
    Write-Output "Elapsed Time"
    Write-Output $StopWatch.Elapsed
    Write-output "----------------------------------------------------------------"

    Write-Host "1.4. Create Operations Manager Suite account" -ForegroundColor Green
    $Command =  "$($PSScriptRoot)\scripts\CreateOMSWorkspace.ps1"
    $Parameters = "-AutomationContextFile $($PSScriptRoot)\AutomationContext.json",  "-Verbose"
    Write-Output "$Command $Parameters"
    Invoke-Expression "$Command $Parameters"
    Write-Output "Elapsed Time"
    Write-Output $StopWatch.Elapsed
    Write-output "----------------------------------------------------------------"

    Move-Item "$($PSScriptRoot)\AutomationContext.json" "$($PSScriptRoot)\scripts\AutomationContext.json" -Force
}

function RunDeelVagrant(){
    Write-Host "2. Provisioning machines with Vagrant" -ForegroundColor Green
    Write-output "----------------------------------------------------------------"
    Write-Host "2.1. Starting Vagrant" -ForegroundColor Green
    $Command =  "vagrant"
    #$Parameters = "up", "dc1", "dc2", "rds1", "rdswa1", "fp1"
    #$Parameters = "up", "dc1", "rds1", "rdswa1", fp1"
    #$Parameters = "up", "dc1", "dc2", "rds1", "monitor"
    $Parameters = "up", "dc1", "rds1"
    Write-Output "$Command $Parameters"
    Invoke-Expression "$Command $Parameters"
    Write-Output $StopWatch.Elapsed
    Write-output "----------------------------------------------------------------"
}

function RunDeelCertificate(){
    Write-Host "3.1. Deploying RDS"
    $Command = "C:\vagrant_data\scripts\RequestCertificate.ps1"
    $CommandParameters = @("-Labels $($DomainName), *.$($DomainName)", "-EmailAddress sven.de.windt@gmail.com", "-AutomationContextFile c:\vagrant_data\scripts\AutomationContext.json", "-Verbose")
    $Computer = "dc1"
    ExecuteRunbook -Command $Command -CommandParameters $CommandParameters -Computer $Computer
    Write-Output "Elapsed Time"
    Write-Output $StopWatch.Elapsed
    Write-output "----------------------------------------------------------------"    
}

function RunDeelDeployRDS(){
    Write-Host "3.2. Deploying RDS"
    $Command = "C:\vagrant_data\scripts\DeployRDS.ps1"
    $CommandParameters = @("-RDSBroker rds1.$($DomainName)", "-RDSWebAccess rds1.$($DomainName)", "-RDSHost rds1.$($DomainName)", "-RDSLicense dc1.$($DomainName)", "-RDGateway rds1.$($DomainName)", "-ExternalFQDN portal.$($DomainName)", "-Certificate C:\vagrant_data\scripts\cert.pfx", "-CertificatePassword poshacme", "-Verbose")
    $Computer = "dc1"
    ExecuteRunbook -Command $Command -CommandParameters $CommandParameters -Computer $Computer
    Write-Output "Elapsed Time"
    Write-Output $StopWatch.Elapsed
    Write-output "----------------------------------------------------------------"
}

function RunDeelPublishApps(){
    Write-Host "3.2. Deploying RDS"
    $Command = "C:\vagrant_data\scripts\PublishRDSApplications.ps1"
    $Description = '"A collection for users"'
    $Chrome = '"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"'
    $Smartty = '"C:\Program Files (x86)\Sysprogs\SmarTTY\SmarTTY.exe"'
    $CommandParameters = @("-SessionCollectionName UserCollection", "-SessionCollectionDescription $($Description)", "-SessionCollectionHosts rds1.$($DomainName)", "-RDSBroker rds1.$($DomainName)", "-Applications @{SmarTTY=$($Smartty); Chrome= $($Chrome)}", "-Verbose")
    $Computer = "dc1"
    ExecuteRunbook -Command $Command -CommandParameters $CommandParameters -Computer $Computer
    Write-Output "Elapsed Time"
    Write-Output $StopWatch.Elapsed
    Write-output "----------------------------------------------------------------"    
}

function RunDeelAddServersToServerManager(){
    Write-Host "3.3. Adding servers to Server Manager"
    $Command = "C:\vagrant_data\scripts\AddServersToServerManager.ps1"
    $CommandParameters = @("-Servers dc2.$($DomainName), rds1.$($DomainName)", "-Verbose")
    $Computer = "dc1"
    ExecuteRunbook -Command $Command -CommandParameters $CommandParameters -Computer $Computer
    Write-Output "Elapsed Time"
    Write-Output $StopWatch.Elapsed
    Write-output "----------------------------------------------------------------"    
}

Start-Transcript -Path $Log -NoClobber
#Clear-Host
$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()

if ($DeelAzure){
    Write-output "RunDeelAzure"
    RunDeelAzure
}

if ($DeelVagrant){
    Write-output "RunDeelVagrant"
    RunDeelVagrant
}

    Write-Host "3. Starting scripts from Azure" -ForegroundColor Green
    Write-output "----------------------------------------------------------------"

    Write-Output "Getting automation context"
    $AutomationContextFile = "$($PSScriptRoot)\scripts\AutomationContext.json"
    $Context = Get-Content $AutomationContextFile | ConvertFrom-Json

    $Serviceprincipal = $Context.ServicePrincipal.ApplicationId
    $ServicePrincipalPassword = $Context.ServicePrincipalPassword 
    $TenantID = $Context.Context.Tenant.TenantId
    $Securepassword = ConvertTo-SecureString -Force -AsPlainText -String $ServicePrincipalPassword
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential($Serviceprincipal, $Securepassword)
    Write-Output "Login on Azure, using serviceprincipal"
    Connect-AzureRmAccount -ServicePrincipal -Credential $Credential -TenantId $TenantID
    $RunbookName = "WrapperForOnPremiseScripts"
    $AutomationAccountName = $Context.AutomationAccount.AutomationAccountName
    $HybridWorkerGroupName = "PowershellAutomation"
    $ResourceGroupName = $Context.AutomationAccount.ResourceGroupName

if ($DeelCertificate){
    Write-Output "RunDeelCertificate"
    RunDeelCertificate
}

if ($DeelRDS){
    Write-output "RunDeelDeployRDS"
    RunDeelDeployRDS
}

if ($DeelAddServersToServerManager){
    RunDeelAddServersToServerManager
}

if ($DeelPublishApps){
    Write-Output "RunDeelPublishApps"
    RunDeelPublishApps
}

$StopWatch.Stop()
Write-Output "Finished"
Stop-Transcript
