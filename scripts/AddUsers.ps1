<#
.SYNOPSIS
  Script to create users from a csv file

.DESCRIPTION
  This script will import a csv file to add the users to Active Directory

.PARAMETER CsvFile
  Specifies the csv file containing the users

.OUTPUTS
  A log file in the temp directory

.NOTES
  Version:        0.1
  Author:         Sven de Windt
  Creation Date:  25/11/2018
  Purpose/Change: Initial script development

.EXAMPLE
  .\AddUsers.ps1 -CsvFile ..\resources\UsersToCreate.csv -Verbose

.EXAMPLE
  .\AddUsers.ps1 -CsvFile ..\resources\UsersToCreate.csv -OU "OU=Users,OU=teamtile,DC=teamtile,DC=be" -Verbose

.EXAMPLE
  .\AddUsers.ps1 -CsvFile ..\resources\UsersToCreate.csv -OU "OU=Users,OU=teamtile,DC=teamtile,DC=be" -Groups teamtile -Verbose

.EXAMPLE
  .\AddUsers.ps1 -CsvFile ..\resources\test.csv -OU "OU=Users,OU=teamtile,DC=teamtile,DC=be" -Groups teamtile -Verbose

#>

#requires -version 3.0

#-----------------------------------------------------------[Parameters]-----------------------------------------------------------

param(
    [CmdletBinding()]
        [parameter(mandatory = $true)][String]$CsvFile,
        [parameter(mandatory = $false)][String]$OU,
        [parameter(mandatory = $false)][String[]]$Groups
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
#$CsvFile = "c:\vagrant_data\resources\UsersToCreate.csv"

#-----------------------------------------------------------[Functions]------------------------------------------------------------



#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Clear-Host
Start-Transcript -Path $Log -NoClobber
$StopWatch = New-Object System.Diagnostics.Stopwatch
$StopWatch.Start()
Write-Output "Start script - version $($ScriptVersion)"

$Users = Import-Csv -Delimiter ";" -Path $CsvFile

foreach ($User in $Users)            
{            
    $Displayname = $User.Firstname + " " + $User.Lastname            
    $UserFirstname = $User.Firstname            
    $UserLastname = $User.Lastname            
    $OrgUnit = $OU            
    $SAM = $User.SAM
    $UPN = $User.Firstname + "." + $User.Lastname + "@" + $User.Maildomain            
    $Description = $User.Description            
    $Password = $User.Password

    Write-Output "Add user $($Displayname)"

    try{
    
    if ($OU){
        New-ADUser -Name "$Displayname" -DisplayName "$Displayname" -SamAccountName $SAM -UserPrincipalName $UPN -GivenName "$UserFirstname" -Surname "$UserLastname" -Description "$Description" -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -Enabled $true -Path "$OU" -ChangePasswordAtLogon $false -EmailAddress $UPN
    }else {
        New-ADUser -Name "$Displayname" -DisplayName "$Displayname" -SamAccountName $SAM -UserPrincipalName $UPN -GivenName "$UserFirstname" -Surname "$UserLastname" -Description "$Description" -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -Enabled $true -ChangePasswordAtLogon $false -EmailAddress $UPN
    }
    if ($Groups){
        foreach($Group in $Groups){
            Add-ADGroupMember -Identity $Group -Members $sam
        }
    }
    } catch {
        Write-Output "Error"
        Write-Output $_.exception
    }
    
}

#-----------------------------------------------------------[Finish up]------------------------------------------------------------
Write-Output $StopWatch.Elapsed

$StopWatch.Stop()
Write-Output "Finished $($MyInvocation.MyCommand.Name)"
Stop-Transcript