<#
Author: Sam Verschuyl
Title: Citrix Reset SmartCard Service
Creation Date: November 21, 2019

.SYNOPSIS
Intended to reset the Citrix and Charismatics smart card service on a targeted machine.

.DESCRIPTION
PowerShell module that prompts the user for a server name, then can remotely reset the SmartCard services when the server is at a hung state. 
Can be copied to a tech's local PowerShell folder to be run on client machines in elevated PowerShell Window
- (C:\Users\<SAMAccountName>\Documents\WindowsPowerShell\Modules)

#>

# $citrixServer = Get-Content "c:\temp\serverlist.txt"
# $PSCred = Get-Credential

Write-Host "*********************************`n `n `tCitrix PowerShell Module `n`n`tReset SmartCard Services`n`nNOTE: Press CTRL-C to cancel script at any time`n`n*********************************`n`n"

$CitrixServer = Read-Host "[USER INPUT]`tName of server to reset the SmartCard service on"
$FindSvcs = get-service -Name CtxSmartCardSvc

ForEach ($server in $CitrixServer){
    Try {
        Invoke-Command -ComputerName $server -Credential $env:UserName -ScriptBlock {
            ForEach ($Svc in $FindSvcs){
                $Svc | Restart-Service -Verbose
                Write-Host "[OUTPUT]`tRestarting $($svc.Name) service on $server" -ForegroundColor Green
                $Findsvcs.MachineName
                }
        }
    } Catch { 
        Write-Host "[ERROR] `t$($_.Exception.Message)" -Foregroundcolor Red
    }
}
