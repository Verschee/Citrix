<#
.SYNOPSIS
Retrieves point in time XenApp environment status based on input piped to Citrix Controller via Get-BrokerMachine cmdlets.
.DESCRIPTION
Title: CVAD 7.+ Environment Health Report
Author: Verschee
Date: 4/13/2021
    - Returns environment health of XenApp delivery groups and exports to a formatted HTML report.
.EXAMPLE
.LINK
https://github.com/Verschee/Citrix

#>

Function Set-CellColor{
    [CmdletBinding()]
        Param (
            [Parameter(Mandatory,Position=0)]
            [string]$Property,
            [Parameter(Mandatory,Position=1)]
            [string]$Color,
            [Parameter(Mandatory,ValueFromPipeline)]
            [Object[]]$InputObject,
            [Parameter(Mandatory)]
            [string]$Filter,
            [switch]$Row
        )

        Begin {
            Write-Verbose "$(Get-Date): Function Set-CellColor begins"
            If ($Filter)
            {   If ($Filter.ToUpper().IndexOf($Property.ToUpper()) -ge 0)
                {   $Filter = $Filter.ToUpper().Replace($Property.ToUpper(),"`$Value")
                    Try {
                        [scriptblock]$Filter = [scriptblock]::Create($Filter)
                    }
                    Catch {
                        Write-Warning "$(Get-Date): ""$Filter"" caused an error, stopping script!"
                        Write-Warning $Error[0]
                        Exit
                    }
                }
                Else
                {   Write-Warning "Could not locate $Property in the Filter, which is required.  Filter: $Filter"
                    Exit
                }
            }
        }

        Process {
            ForEach ($Line in $InputObject)
            {   If ($Line.IndexOf("<tr><th") -ge 0)
                {   Write-Verbose "$(Get-Date): Processing headers..."
                    $Search = $Line | Select-String -Pattern '<th ?[a-z\-:;"=]*>(.*?)<\/th>' -AllMatches
                    $Index = 0
                    ForEach ($Match in $Search.Matches)
                    {   If ($Match.Groups[1].Value -eq $Property)
                        {   Break
                        }
                        $Index ++
                    }
                    If ($Index -eq $Search.Matches.Count)
                    {   Write-Warning "$(Get-Date): Unable to locate property: $Property in table header"
                        Exit
                    }
                    Write-Verbose "$(Get-Date): $Property column found at index: $Index"
                }
                If ($Line -match "<tr( style=""background-color:.+?"")?><td")
                {   $Search = $Line | Select-String -Pattern '<td ?[a-z\-:;"=]*>(.*?)<\/td>' -AllMatches
                    $Value = $Search.Matches[$Index].Groups[1].Value -as [double]
                    If (-not $Value)
                    {   $Value = $Search.Matches[$Index].Groups[1].Value
                    }
                    If (Invoke-Command $Filter)
                    {   If ($Row)
                        {   Write-Verbose "$(Get-Date): Criteria met!  Changing row to $Color..."
                            If ($Line -match "<tr style=""background-color:(.+?)"">")
                            {   $Line = $Line -replace "<tr style=""background-color:$($Matches[1])","<tr style=""background-color:$Color"
                            }
                            Else
                            {   $Line = $Line.Replace("<tr>","<tr style=""background-color:$Color"">")
                            }
                        }
                        Else
                        {   Write-Verbose "$(Get-Date): Criteria met!  Changing cell to $Color..."
                            $Line = $Line.Replace($Search.Matches[$Index].Value,"<td style=""background-color:$Color"">$Value</td>")
                        }
                    }
                }
                Write-Output $Line
            }
        }

        End {
            Write-Verbose "$(Get-Date): Function Set-CellColor completed"
        }
    }

Function Gather-CitrixResults {
    Begin {
        asnp Citrix*

    ### All Catalogs - with exemptions
    $Catalogs = $catalogs = Get-BrokerCatalog
    $CatalogArray = @($Catalogs.Name)
    ForEach ($Catalog in $CatalogArray) {
    Try {
    Write-Host "Catalog item: $Catalog" -ForegroundColor Cyan
        # Exemption when there are machines in the MachineCatalog but not assigned to a DesktopGroup/DeliveryGroup
        $RESULTS = Get-BrokerMachine -MaxRecordCount 10000 | Where-Object {$_.DesktopGroupName.Count -ne 0}
            } Catch {
             Write-Warning " ***** Will not proceed ***** `n [REASON] $($_.Exception.Message)"
            }
        } ### End All Catalogs
        # Old Version $results = Get-BrokerMachine -MaxRecordCount 1000 
        }
    Process {
    $ControllerName = $env:COMPUTERNAME
    $currentdate = Get-Date
    $title = "CVAD 7.+ Environment Summary Report - Full"

$htmlHeader = @"
<html>
<head>
<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>
<title>$title</title>
<STYLE TYPE="text/css">
<!--
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
td {
font-size: 14px;
border-top: 1px solid #999999;
border-right: 1px solid #999999;
border-bottom: 1px solid #999999;
border-left: 1px solid #999999;
padding-top: 1px;
padding-right: 1px;
padding-bottom: 1px;
padding-left: 1px;
overflow: hidden;
}
body {
margin-left: 5px;
margin-top: 5px;
margin-right: 0px;
margin-bottom: 10px;
table {
table-layout:fixed;
border: thin solid #000000;
}
-->
</style>
</head>
<body>
<table width='1200'>
<tr bgcolor='#6495ED'>
<td colspan='7' height='48' align='center' valign="middle">
<font face='tahoma' color='#141414' size='4'>
<strong>$title - $currentdate</strong></font>
</td>
</tr>
</table>
"@

$HTMLBody = @"
<br>
Environment data collected hourly from the Controller: <B>$ControllerName</B><br>
<br>
"@

    $newobj = @()
       ForEach ($result in $results) {
       $FreeDiskSpace = [Math]::Round(((Get-CimInstance -ComputerName $result.DNSName -ClassName CIM_LogicalDisk -Filter "DeviceID = 'C:'" | Measure-Object -Property FreeSpace -Sum).Sum/1GB),2)
        $LastBootUp = (Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $result.DNSName -ErrorAction SilentlyContinue).LastBootUpTime
        $uptime = $currentdate - $LastBootUp
       $newobj += [PSCustomObject] @{
           Servername = $result.DNSName
           DeliveryGroup = $result.DesktopGroupName
           LogonsAvailable = $result.WindowsConnectionSetting
           Sessions = $result.SessionCount
           FreeDiskSpace = $FreeDiskSpace
           IPAddress = $result.IPAddress
           LastBootUp = "$($uptime.Days)"
           AgentVersion = $result.AgentVersion
           Registration = $result.RegistrationState
           MaintenanceMode = $result.InMaintenanceMode
           }
       }
       $HTMLTitle = "XA7SEFarm_Full"
       $HTMLResults = $newobj | Sort-Object ServerName | ConvertTo-Html -Head $HTMLHeader -Body $HTMLBody
       $HTMLResults = $htmlResults | Set-CellColor MaintenanceMode Orange -Filter "MaintenanceMode -like ""*True*""" -Row
       $HTMLResults = $HTMLResults | Set-CellColor LogonsAvailable Red -Filter "LogonsAvailable -like ""*LogonDisabled*"""
       $HTMLResults = $HTMLResults | Set-CellColor FreeDiskSpace Red -Filter "FreeDiskSpace -lt ""10"""
       $HTMLResults = $HTMLResults | Set-CellColor FreeDiskSpace Yellow -Filter "FreeDiskSpace -gt 15 -and FreeDiskSpace -lt 20"
       $HTMLResults = $HTMLResults | Set-CellColor LastBootUp Yellow -Filter "LastBootUp -gt 7 -and LastBootUp -lt 13"
       $HTMLResults = $HTMLResults | Set-CellColor LastBootUp Red -Filter "LastBootUp -gt 14"
       # $HTMLResults = $HTMLResults | Set-CellColor WindowsConnectionSetting LightGreen -Filter "WindowsConnectionSetting -like ""*LogonEnabled*"""
       $HTMLResults = $HTMLResults | Set-CellColor Registration Red -Filter "Registration -like ""*Unregistered*""" -Row
       $TempHTML = $HTMLResults | Out-File .\$HTMLTitle.html
       $htmlfile = Get-Item .\$HTMLTitle.html
        }
        End {
            # Copy HTML file to Web Storefront servers for health site
        Copy-Item $htmlfile -Destination "\\RemoteHost\Reports"
             } # end
        } # Close function

    Gather-CitrixResults
