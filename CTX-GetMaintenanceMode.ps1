<#
.SYNOPSIS
- Retrieve a list of Citrix servers in Maintenance Mode within a Citrix farm location
.DESCRIPTION
- Login to a Citrix Controller, query the DC for a list of machines with given properties and generate a report based on the results that gets copied to the clipboard
.PARAMETER CTXController
- Server FQDN for the Citrix Delivery Controller we want to look at
.PARAMETER DeliveryGroup
- The Citrix Delivery Group containing the machines we want to look at

#>
Add-PSSnapin Citrix*

Param(
    [Parameter(Mandatory=$true)]
    [string] $CTXController,
    [Parameter(Mandatory=$true)]
    [string] $DeliveryGroup = @()
)

# Authorized domain credentials to access the Citrix DC
$PSCred = Get-Credential

Write-Host " ********* Citrix Get-MaintenanceMode Server Script ********* `n" -ForegroundColor Cyan -BackgroundColor Black

Try { $sesh = Enter-PSSession -ComputerName $CTXController -Credential $PSCred -Verbose     
        } Catch { Write-Warning "[ERROR] $($_.Exception.Message)" }

Begin {
    # Get the number of machines within a delivery group that are in maintenance mode and the sessions count
    $machines = Get-BrokerMachine -DesktopGroupName $DeliveryGroup -InMaintenanceMode 1 | Select MachineName, InMaintenanceMode, SessionCount, AssociatedUserNames

    Write-Host "$Machines"

    Function Restart-Machines {
        # restart every server and put into Maintenance Mode with the following conditions : InMaintenanceMode is true and no action sessions
        Try {        
            ForEach ($Machine in $machines){
            Restart-Computer -ComputerName $Machine
            }
        } Catch { Write-Warning "[ERROR] $($_.Exception.Message)" }
    }
    Function Remove-MaintenanceMode {
        Try {
            ForEach ($Machine in $machines){
            Get-BrokerMachine -MachineName $Machine | Set-BrokerMachine -InMaintenanceMode 0
            }
        } Catch { Write-Warning "[ERROR] $($_.Exception.Message)" }
    }

    }
Process {
    Write-Host "$Machines.MachineName"
    # Prompt the user to bring the selected machines into production by taking them out of maintenance mode
    Write-Host "[INFO] The next question will direct specific operations to manipulate the machines given above. The machines will be restarted as required by the user and taken out of maintenance mode to be brought into the production environment.`nPlease consider the ramifications prior to answering these questions appropriately." -ForegroundColor Cyan
    $RebootServer = Read-Host -prompt "[INPUT] Would you like to restart the following servers? (y / n) "
    If ($RebootServer -eq "y"){
        Restart-Machines
    } ElseIf ($RebootServer -eq "n") { Write-Host "[INFO] You answered no. Script will not bring machines out of maintenance mode..." -ForegroundColor Cyan}
    Else {Write-Warning -Message "[ERROR] Improper input given. Please use y or n to respond to the prompt."}
    $MaintModeOff = Read-Host -prompt "[INPUT] Would you like to now bring the servers into production? (y / n) "
        If ($MaintModeOff -eq "y"){
            Remove-MaintenanceMode
        } ElseIf ($MaintModeOff -eq "n") { Write-Host "[INFO] You answered no. Script will not bring machines out of maintenance mode..." -ForegroundColor Cyan}
        Else {Write-Warning -Message "[ERROR] Improper input given. Please use y or n to respond to the prompt."}
    }
End { Exit-PSSession }