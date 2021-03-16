    <#
    .SYNOPSIS
        Disable/Enable remote logins for targeted server(s)
    .PARAMETER Server
        Name of server/s to run operation function against.
    .PARAMETER Credential
        Elevating credentials in order to perform operations
    .NOTES
        Name: Toggle-RemoteLogons
    .LINK
        https://github.com/Verschee/Citrix/
    .EXAMPLE
    LogonEnable -ServerName venator.nos.company.com -credential Get-Credential
     
    #>
function LogonDisable {
    param (
            [Parameter(Mandatory=$true,Position=0)]
            [Alias("CN")]
                [string[]]$ComputerName
        )
    TRY {
        $ComputerName | Select-Object -Unique | %{
            $TS_Connector = Get-WmiObject Win32_TerminalServiceSetting -N "root/cimv2/terminalservices" -computername $_ -Authentication PacketPrivacy
            $TS_Connector.Logons=1
            $TS_Connector.Put()
             $TS_Connector.Get()
            if ($TS_Connector.Logons -eq 1) {
                "OK"
            } else {
                "Error"
            }
        }
    }#TRY
    CATCH {
        Write-Warning -Message "$($Error[0].Exception)"
    }
}

function LogonEnable {

   param (
            [Parameter(Mandatory=$true,Position=0)]
            [Alias("CN")]
                [string[]]$ComputerName
        )
    TRY {
        $ComputerName | Select-Object -Unique | %{
            $TS_Connector = Get-WmiObject Win32_TerminalServiceSetting -N "root/cimv2/terminalservices" -computername $_ -Authentication PacketPrivacy
            $TS_Connector.Logons=0
            $TS_Connector.Put()
            $TS_Connector.Get()
            if ($TS_Connector.Logons -eq 0) {
                "OK"
            } else {
                "Error"
            }
        }
    }#TRY
    CATCH {
        Write-Warning -Message "$($Error[0].Exception)"
    }
}


Function Set-Logons {

    Param([Parameter(
        Mandatory=$true,
        Position = 0,
        ValuefromPipeline=$true)
        [string[]]$ServerName,

        [Parameter()]
        [PSCredential]
        $Credential,
    ])
}