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