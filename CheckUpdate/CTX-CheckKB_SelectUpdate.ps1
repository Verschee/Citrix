<#
.NOTES
Author: tl828e

.SYNOPSIS
 Prerequisites:
    - Only authorized credentials will be accepted to run this script. 
    - WinRM must be enabled  on the remote servers to run Invoke-* cmdlets.

.DESCRIPTION
 This script will import a text file for a list of FQDN server names and check for server compliance based on the parameters described in the arrays given.
 The script will then ask the user to select if they want to remediate any servers when presented with a list.
 The user will then be prompted the ODSSD client on each machine, validate whether the process completed or failed, then terminate the script process.

----- Version Info
9/24/19: Would like to return ODSSD client status from CMD window to PowerShell window

#>

### List of servers to check
$path = "C:\temp\servers2.txt"
$servers =  Get-Content $path
$fdt = (Get-Date -format FileDateTime)
$noncompTXT = "C:\temp\NonComp_$fdt.txt"
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

Write-Host "**** Checking for Windows Updates on List of Servers from location: $path ****`n**** Security Updates Per Operating System:**** `n`n----------------------------------------`n*** SERVER COMPLIANCE INFORMATION FOR CRITICAL RDS VULNERABILITY (JAN 2020): CryptoAPI Vulnerability ***`n[INFO]`tWindows Server 2016:`t $1stPatch $2ndPatch `n`n[INFO]`tWindows Server 2008:`t $3rdPatch $4thPatch $5thPatch
[INFO]`tPath for exported list of servers and compliance status (Summary): $summary`n[INFO]`tPath for exported list of servers not in compliance (Non-Compliant): $noncompTXT `n`n[INFO]`t Starting Operation..."

Function Run-ODSSD {
    param([parameter(ValueFromPipeline=$True)]
    [string]$Servers,
    [string]$ODSSD="C:\Program Files\BSA\ODSSD_Client\ODSSDClient.exe",
    [string]$argument= '/rtc'
    )
    ForEach ( $server in $servers) {
    Try { Write-Progress " Executing the BSA ODSSD client on the selected machines. "
        Invoke-Command -ComputerName $server -ScriptBlock {& cmd /c $ODSSD $argument}
        Write-Progress " " -Completed
    } Catch { Write-Host "[ERROR]`t Process failed to run on $server : $($_.Exception.Message)"}
    }
}

foreach ($server in $servers) { 

### Create a PSCustomObject of Servers and their OS, non-compliant servers will go to $export
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
Function Run-Selection {
    $List = Import-CSV $summary
    # $List = Get-Content $noncompTXT
    $ServerToUpdate = $List | Out-GridView -Title "[Hotfix Compliance Summary List] Select the server to run the BSA ODSSD client manually:" -OutputMode Multiple
    Try { Run-ODSSD -servers $server } Catch { Write-Warning -Message "`t[INFO]`t Could not contact $_. [REASON] $($_.Exception.Message)" }
}
$Selection = [System.Windows.Forms.MessageBox]::Show("[INPUT]`t Would you like to select which servers to run the ODSSD client on manually?", "Please make a selection", 4)
If ($Selection -eq "Yes"){
    Try { 
        Run-Selection
    } Catch {
        [System.Windows.Form.MessageBox]::Show("[ERROR]`t Could not execute ODSSD client on selected servers: $($_.Exception.Message)")
    }
} Else { exit 1 }