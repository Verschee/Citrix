    <#
    .SYNOPSIS
        Retrieves tall user sessions from local or remote server/s
    .PARAMETER Server
        Name of server/s to run session query against.
    .NOTES
        Name: Get-ServerSessions
        Author: tl828e
        Adapted from a script taken from the link below :     
    .LINK
        https://boeprox.wordpress.org
    .EXAMPLE
    Get-ServerSessions -server "server1"
     
    Description
    -----------
    This command will query all current user sessions on 'server1'.
     
    #>
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
                    $temp = "" | Select Server,SessionName, Username, Id, State
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