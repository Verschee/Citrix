$PSCred = Get-Credential
Write-Host "*********************************`n `n `tERC-Citrix PowerShell Module `n`n`tReset SmartCard Services`n`nNOTE: Press CTRL-C to cancel script at any time`n`n*********************************`n`n"
Write-Host "`n### Example of Operation : `n
1. Identify the Server has an issue by seeing disconnected users present on system:
`n`tGet-ServerSessions -server1, server2
2. Target the server to reset the CtxSmartCardSvc (Citrix Smart Card Service)
`n`tReset-SmartCard -server server1, server2`n"

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
    Begin { $report = @() }
    Process { 
        ForEach($s in $server) {
            # Parse 'query session' and store in $sessions:
            $sessions = query session /server:$s
                1..($sessions.count -1) | % {
                    $temp = "" | Select Server,SessionName, Username, Id, State
                    $temp.Server = $s
                    $temp.SessionName = $sessions[$_].Substring(1,18).Trim()
                    $temp.Username = $sessions[$_].Substring(19,20).Trim()
                    $temp.Id = $sessions[$_].Substring(39,9).Trim()
                    $temp.State = $sessions[$_].Substring(48,8).Trim()
                    $report += $temp }
            }
        }
    End { $report | Format-Table -GroupBy Server }
    }

Function Reset-SmartCard {
    # Define parameters and system dependencies
    [cmdletbinding(
        DefaultParameterSetName = 'session',
        ConfirmImpact = 'low'
    )]
        Param(
            [Parameter(
                Mandatory = $True,
                Position = 0)]
                [string[]]$server
                )
    ForEach ($s in $server){
        Try {   Invoke-Command -ComputerName $s -Credential $PSCred -ScriptBlock { 
            # define the services below in $CtxSvc. This array can support multiple services if necessary
            $ctxsvc = "CtxSmartCardSvc"
                    $GetCTXSvc = get-service -Name $CtxSvc 
                    If ($GetCtxSvc.Status -eq "Stopped") {
                    Write-Host "[OUTPUT] Service was stopped. Please wait..." -ForegroundColor Green
                        Start-Service $CtxSvc -Verbose
                    } 
                    Else { $GetCTXSvc | Restart-Service -Verbose }
            }
            # return success to console
        } Catch { 
            Write-Host "[ERROR] `t$($_.Exception.Message)" -Foregroundcolor Red
        }
        Write-Host "[OUTPUT] Successfully restart the Citrix Smart Card Service on $s" -ForegroundColor Green
    }
}