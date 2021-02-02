<#
.NOTES
 Sam Verschuyl

 Changelog:
    8/21/2019
     - Initially created to look for the KB#'s matching the Remote Desktop Services critical vulnerability - CVE-2019-1181 and CVE-2019-1182 ("Deja Blue")
     - Added KB4512495 as it does supersede KB4512517 - removed KB4512517

.SYNOPSIS
 Prerequisites:
    - Only authorized credentials will be accepted to run this script. 
    - WinRM must be enabled  on the remote servers to run Invoke-* cmdlets.

.DESCRIPTION
 This script will import a text file for a list of FQDN server names and run a command to look at installed Windows Hotfixes for the specified patches.
 Any error codes will be passed to the ErrorVariable and shown to the host in the console as a warning message.

.PARAMETER Path
 Location for the text file where the remote server names are stored

.PARAMETER Patches
 List of KB#'s to look for on the remote servers.

#>

param (
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credentials
)

$path = "C:\Temp\servers.txt"
$fdt = (Get-Date -Format FileDateTime)
$export = "C:\Temp\NonComp-$fdt.txt"
# $servers =  Get-Content $path
$servers = Read-Host "Enter server name "
$patches = "KB4512495", 'KB4517297', 'KB4512486'#, 'KB4517297')
# Pulled: 'KB4512495' Server 2008, 'KB4512517'

Write-Host "**** Checking for Windows Updates on List of Servers from location: $path ****`n**** Security Updates Per Operating System:**** `n`n----------------------------------------`n*** SERVER INFORMATION FOR CRITICAL RDS VULNERABILITY: CVE-2019-1181 & CVE-2019-1182 ***`n[INFO]`tServer 2016:`t`nKB 4512517 `n[INFO]`tServer 2008 R2:`t`nKB 4512486, 4517297"

Invoke-Command $servers -Verbose {
    Get-HotFix -Id "KB4512495"
} -ErrorAction SilentlyContinue -ErrorVariable NonComp

forEach ($p in $NonComp) {
    if ($p.originInfo.PSComputerName) {
        Write-Warning -Message "[INFO]`t Patch was not found on the following server: ($($p.originInfo.PSComputerName)) `n `t"
        $p.originInfo.PSComputerName  | Out-File $export -Append
    }
    ElseIf ($p.TargetObject){
        Write-Warning -Message "[INFO]`t Unable to connect to server $($p.TargetObject)"
    }
}