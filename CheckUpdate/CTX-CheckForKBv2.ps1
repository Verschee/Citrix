<#
.NOTES
 Sam Verschuyl

.SYNOPSIS
 Prerequisites:
    - Only authorized credentials will be accepted to run this script. 
    - WinRM must be enabled  on the remote servers to run Invoke-* cmdlets.

.DESCRIPTION
 This script will import a text file for a list of FQDN server names and run a command to look at installed Windows Hotfixes for the specified patches.
 Any error codes will be passed to the ErrorVariable and shown to the host in the console as a warning message.

.PARAMETER Path
 Location for the text file where the remote server names are stored

.PARAMETER Patches2k8 
 List of KB#'s to look for on the remote Server 2008 R2 servers

.PARAMETER Patches2k16 
 List of KB#'s to look for on the remote Server 2016 R2 servers

.PARAMETER Summary
 Lists all servers that were checked for HotfixID under the patch string values

.PARAMETER NonCompTXT
 Contains the servers that were not-compliant for the server hotfixes. 

 
Changelog:
    8/21/2019
     - Initially created to look for the KB#'s matching the Remote Desktop Services critical vulnerability - CVE-2019-1181 and CVE-2019-1182 ("Deja Blue")
     - Updated Error Handling and any errors exhibited in the file will export to a text file $export
     - Added KB4512495 - VB patch to replace KB4512517 as it supercedes the former
    8/28/2019
     - Added new parameters and specifically defined 2008 and 2016 patches for remediation/compliance
    9/9/2019
     - Made the commands verbose to verify that the process is running within the console.

#>

param (
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credentials
)
### List of servers to check
$path = "C:\temp\servers2.txt"
$servers =  Get-Content $path
$fdt = (Get-Date -format FileDateTime)
$noncompTXT = "C:\temp\NonComp_$fdt.txt"
$summary = "C:\temp\Summary_$fdt.CSV"

### Arrays for patch string values
$2k8patches = 'KB4517297' # 'KB4512486' - VB patch
$2k16patches = 'KB4512495'

Write-Host "**** Checking for Windows Updates on List of Servers from location: $path ****`n**** Security Updates Per Operating System:**** `n`n----------------------------------------`n*** SERVER COMPLIANCE INFORMATION FOR CRITICAL RDS VULNERABILITY (AUG 2019): CVE-2019-1181 & CVE-2019-1182 ***`n[INFO]`tServer 2016:`t$2k16patches `n[INFO]`tServer 2008 R2:`t$2k8patches`n`n
[INFO]`tExported list of servers and compliance status: $summary`n[INFO]`tExported list of servers not in compliance: $noncompTXT"
 
foreach ($server in $servers) { 

  ### Create a PSCustomObject of Servers and their OS, non-compliant servers will go to $export
  Try { 
    $output = [ordered]@{
      'FQDN' = $server
      'OperatingSystem' = (Get-CimInstance -ComputerName $server -ClassName CIM_OperatingSystem -Verbose).Caption
      'HotfixID2016' = (Get-HotFix -ComputerName $server -Id "$2k16patches" -ErrorAction SilentlyContinue -Verbose).HotfixID
      'HotfixID2008' = (Get-HotFix -ComputerName $server -id "$2k8patches" -ErrorAction SilentlyContinue -Verbose).HotfixID
      }
            If ($output.HotfixID2008 -match $2k8patches) {
                Write-Host "`n[INFO]`t Server $($output.FQDN) is compliant for 2008 patches ( $2k8patches )" -ForegroundColor Green
                }
            ElseIf ($output.HotfixID2016 -contains $2k16patches) { 
                Write-Host "`n[INFO]`t Server $($output.FQDN) is compliant for 2016 ( $2k16patches )" -ForegroundColor Green
            }
            Else { 
                Write-Host " `n[INFO]`t Server: $($output.FQDN) is not compliant" -ForegroundColor Red
                $output.FQDN | Out-File $noncomptxt -append
                }
    # Put the objects into the appropriate compliance status
    [PSCustomObject]$output | Export-CSV -path $Summary -append -NoTypeInformation
      } Catch { Write-Warning -Message "`t[INFO]`t Could not contact $server " }
    }