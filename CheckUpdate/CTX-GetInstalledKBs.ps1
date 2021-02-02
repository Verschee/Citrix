<#
.NOTES
 Sam Verschuyl

 Changelog:
    8/21/2019
     - Script creation started.

.SYNOPSIS
 Prerequisites:
    - Only authorized credentials will be accepted to run this script. 
    - WinRM must be enabled on the remote servers to run Invoke-* cmdlets.

.DESCRIPTION
 This script will import a text file for a list of FQDN server names and run a command to look at installed Windows Hotfixes.
 Any error codes will be passed to the ErrorVariable and shown to the host in the console as a warning message.

.PARAMETER Path
 Location for the text file where the remote server names are stored

.PARAMETER Export
 List of servers and their installed KB's exported to a CSV file for spreadsheet analysis

#>
param (
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credentials
)

$path = "C:\Temp\testservers.txt"
$export = "C:\Temp\GetInstalledKB_Export.txt"
$servers =  Get-Content $path

Write-Host "**** Checking for Windows Updates on List of Servers from location: $path ****`n**** Security Updates Per Operating System:**** `n`n
----------------------------------------`n 
`t`tRetrieving Windows Updates/Hotfixes on the list of servers from the Path...
"
forEach ($server in $servers) {
    Write-Host "[INFO]`tWorking on server: ($server)"
    Invoke-Command -ScriptBlock {Get-Hotfix | Select PSComputerName, Description, InstalledOn, HotFixID} -ComputerName $server | FT | Out-File $export -Append -ErrorAction SilentlyContinue -ErrorVariable NonComp
    Write-Host "[INFO]`t$server information was exported to text file.`n"
} 

ForEach ($n in $NonComp) {
    If ($n.TargetObject){
        Write-Warning -Message "[INFO]`t We were unable to connect to server $($n.TargetObject)"
    }
}