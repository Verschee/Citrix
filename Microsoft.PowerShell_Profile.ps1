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
Function Restart-IMAService {
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ValueFromPipeline = $true)] # remove
            [string[]]$server
            )

    begin{
        ### List of Servers. Either imported text files or explicitly named $import = 'C:\Temp\servers.txt'
        # Interactive option, select specific hosts from a list $server = @(Get-Content $import | Out-GridView -Title "[RESTART IMA SERVICE] Select the servers you would like to target to reset the IMA Service" -OutputMode Multiple)
        $total = 0 # initialize total sum
     }
    process {
        ForEach ($s in $server){
                 Try {
                    # Test-Connection -computerName $s -count 4
                    Invoke-Command -ComputerName $s -Credential $env:UserName -ScriptBlock { Restart-Service -DisplayName "IMAService"}
					$total += $s.Count
                Write-Host "[INFO] Restarting IMA service on host : $s " -foregroundcolor Yellow
                } Catch { Write-Host "[ERROR] This action failed on $s `n Reason : $($_.Exception.Message)" -foregroundcolor Red }
            Write-Host "[OUTPUT] Successfully restart the Citrix IMA Service on $s" -ForegroundColor Green
            } # end ForEach
    } End { Write-host  "Final total of IMA Service restarts : $total" }
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

Function Reset-PowerCLIVM {
    [cmdletbinding(
        DefaultParameterSetName = 'session',
        ConfirmImpact = 'low'
    )]
    Param(
        [Parameter(
            Mandatory=$true,
            Position = 0,
            ValuefromPipeLine = $true)]
            [string[]]$server
            )
    Begin {
        # Create an empty array to host the server(s)
        $List = @()
    }
    # Perform VM Reset
    Process {
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