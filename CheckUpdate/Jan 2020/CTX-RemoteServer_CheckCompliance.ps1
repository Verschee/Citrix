<#
.NOTES
Author: tl828e
Date : 1/22/2020

.SYNOPSIS
 Prerequisites:
    - Only authorized credentials will be accepted to run this script. 
    - WinRM must be enabled  on the remote servers to run Invoke-* cmdlets.

.DESCRIPTION
 This script will import a text file for a list of FQDN server names and check for Hotfix compliance based on the parameters described in the arrays given.

#>

### List of servers to check
$path = "C:\temp\servers.txt"
$servers =  Get-Content $path
$fdt = (Get-Date -format FileDateTime)
$summary = "C:\temp\Summary_$fdt.CSV"

### Arrays for patch string values
# 2016
$1stPatch = "KB4532933"
$2ndPatch = "KB4534271"
$2016Patch = @($1stPatch, $2ndPatch)
# 2008
$3rdpatch = "KB4536952"
$4thPatch = "KB4534314"
$5thPatch = "KB4534251"
$2008Patch = @($3rdpatch,$4thPatch,$5thPatch)

Write-Host "**** Checking for Windows Updates on List of Servers from location: $path ****`n**** Security Updates Per Operating System:**** `n`n----------------------------------------`n*** SERVER COMPLIANCE INFORMATION FOR CRITICAL RDS VULNERABILITY (JAN 2020): CryptoAPI Vulnerability ***`n[INFO]`tWindows Server 2016:`t $1stPatch $2ndPatch `n[INFO]`tWindows Server 2008:`t $3rdPatch $4thPatch $5thPatch
`n[INFO]`tPath for exported list of servers and compliance status (Summary): $summary`n`n[INFO]`t Starting Operation..."

foreach ($server in $servers) { 

### Create a PSCustomObject of Servers and their OS
  Try { 
    $output = [ordered]@{
      'FQDN' = $server
      'OperatingSystem' = (Get-CimInstance -ComputerName $server -ClassName CIM_OperatingSystem -Verbose).Caption
      'Patch2016-1' = (Get-HotFix -ComputerName $server -ID $1stPatch -ErrorAction SilentlyContinue -Verbose).HotfixID
      'Patch2016-2' = (Get-HotFix -ComputerName $server -ID $2ndPatch -ErrorAction SilentlyContinue -Verbose).HotfixID
      'Patch2008-3' = (Get-HotFix -ComputerName $server -ID $3rdPatch -ErrorAction SilentlyContinue -Verbose).HotfixID
      'Patch2008-4' = (Get-HotFix -ComputerName $server -ID $4thPatch -ErrorAction SilentlyContinue -Verbose).HotfixID
      'Patch2008-5' = (Get-HotFix -ComputerName $server -ID $5thPatch -ErrorAction SilentlyContinue -Verbose).HotfixID
      }
    # Put the objects into the appropriate compliance status
     [PSCustomObject]$output | Export-CSV -path $Summary -append -NoTypeInformation
      } Catch { Write-Warning -Message "`t[ERROR]`t Could not contact $server " }
}
    $List = Import-CSV $summary
    # $List = Get-Content $noncompTXT
    $ServerToUpdate = $List | Out-GridView -Title "[Hotfix Compliance Summary List] "