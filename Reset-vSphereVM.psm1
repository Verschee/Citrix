    <#
    .SYNOPSIS
        This script will send a Reset command to a VM host on vSphere.
    .PARAMETER Server
        The given server name (FQDN or IPv4) that you would like to run the script against.
    #>
    # Import the PowerCLI module
    Import-Module "VMware.PowerCLI"
    
Function Reset-VM {
    [cmdletbinding(
        DefaultParameterSetName = 'session',
        ConfirmImpact = 'low'
    )]
    Param(
        [Parameter(
            Mandatory=$true,
            Position = 0,
            ValuefromPipeLine = $true)]
            [string[]]$server,
            [string]$domain
            )
    Begin {
        # Create an empty array to host the server(s)
        $List = @()
        # valid creds and store in variable
        $creds = Get-Credential
        # validate the vSphere host
        If ($domain -eq "NW"){
            $dm = "<#server FQDN#>"
        } elseif ($domain -eq "SE") {
            $dm = "<#server FQDN#>"
            }
            elseif ($domain -eq "SW") {
            $dm = "<#server FQDN#>"
            }
    }
    # Perform VM Reset
    Process {
        Connect-viServer $dm -Credential $creds
        ForEach ($s in $server) { 
            $retrieve = Get-VM -Name "$server"
            $reset = ($retrieve).ExtensionData.ResetVM()
            Write-Host "[OUTPUT]`t Restarting $($retrieve.Name) through vSphere..." -ForegroundColor Green
        }
    }
    End {
        $list | Format-Table -GroupBy Name
    }
}