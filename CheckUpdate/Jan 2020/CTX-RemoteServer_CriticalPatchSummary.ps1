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
### Arrays for patch string values
# 2016
<#$1stPatch = "KB4532933"
$2ndPatch = "KB4534271"
# 2008
$3rdpatch = "KB4536952"
$4thPatch = "KB4534314"
$5thPatch = "KB4534251"
#>

### List of servers to check
$path = "C:\temp\servers.txt"
$servers =  Get-Content $path
$fdt = (Get-Date -format FileDateTime)
$summary = "C:\temp\Summary_$fdt.CSV"


function Check-PatchCompliance {
  Param(
  [Parameter(
      ValueFromPipeline=$True,
      Position = 0)]
      [string[]] $2008Patch,
      [Parameter(
      ValueFromPipeline=$True,
      Position = 0)]
      [string[]] $2016Patch
  )

  Begin {
    $PatchList = @()
    Write-Host "**** Checking for Windows Updates on List of Servers from location: $path ****`n**** Security Updates Per Operating System:**** `n`n----------------------------------------`n*** SERVER COMPLIANCE INFORMATION FOR CRITICAL RDS VULNERABILITY (JAN 2020): CryptoAPI Vulnerability ***`n[INFO]`tKB to check for Windows Server 2016:`t $2016Patch `n[INFO]`tKB to check for Windows Server 2008:`t $2008Patch
  `n[INFO]`tPath for exported list of servers and compliance status (Summary): $summary`n`n[INFO]`t Starting Operation..."
  }
  
  Process {
      foreach ($server in $servers) { 
      ### Create a PSCustomObject of Servers and their OS
        Try { 
          $output = [ordered]@{
            'FQDN' = $server
            'OperatingSystem' = (Get-CimInstance -ComputerName $server -ClassName CIM_OperatingSystem -Verbose).Caption
            'Patch2016' = (Get-HotFix -ComputerName $server -ID $2008Patch -ErrorAction SilentlyContinue -Verbose).HotfixID
            'Patch2008' = (Get-HotFix -ComputerName $server -ID $2016Patch -ErrorAction SilentlyContinue -Verbose).HotfixID
            }
          # Put the objects into the appropriate compliance status
          [PSCustomObject]$output | Export-CSV -path $Summary -append -NoTypeInformation
            } Catch { Write-Warning -Message "`t[ERROR]`t Could not contact $server " }
        }
      }
  End {
          $List = Import-CSV $summary
          $ServerToUpdate = $List | Out-GridView -Title "[Hotfix Compliance Summary List] "
      }
}