$Grab = Get-ChildItem I:\Scripts\PowerShell | Out-GridView -OutputMode Single
$ComputerNames = Get-Content $Grab

Function Get-ServerSessions {
    [cmdletbinding(
        DefaultParameterSetName = 'session',
        ConfirmImpact = 'low'
    )]
        Param(
            [Parameter(
                Mandatory = $True,
                Position = 0,
                ValueFromPipeline = $True)]
                [string[]]$server
                )
    Begin {
        $report = @()
        }
    Process { 
        ForEach($s in $server) {
            # Parse 'query session' and store in $sessions:
            $sessions = query session /server:$s
                1..($sessions.count -1) | % {
                    $temp = "" | Select-Object Server,SessionName, Username, Id, State
                    $temp.Server = $s
                    $temp.SessionName = $sessions[$_].Substring(1,18).Trim()
                    $temp.Username = $sessions[$_].Substring(19,20).Trim()
                    $temp.Id = $sessions[$_].Substring(39,9).Trim()
                    $temp.State = $sessions[$_].Substring(48,8).Trim()
                    $report += $temp
                }
            }
        }
    End {
        $report | Format-Table -GroupBy Server
        }
    }

function Get-LogonAbility {
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [Alias("CN")]
        [string[]]$ComputerName
        Try {
            $ComputerName | Select-Object -Unique | ForEach-Object {
            $TS_Connector = Get-WmiObject Win32_TerminalServiceSetting -N "root/cimv2/terminalservices" -computername $_ | Select PSComputerName, Logons
            Write-Host "Logons enabled: 0 `nLogons disabled: 1 `n"
            }
        } Catch {
            Write-Output "This couldn't work"
        }
    )

}
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
    
    