param ([switch]$MonitorSpots=$false)

# Determine platform and make assumption about logfile path. Manually set it if this doesn't work for you
if ($IsLinux) { $LogFile = "~/.local/share/WSJT-X/wsjtx.log" }
elseif ($IsMacOS) { $LogFile = "~/Library/Application Support/WSJT-X/wsjtx.log" }
else { $LogFile = "~/AppData/Local/WSJT-X/wsjtx.log" }

$AllTxt = $LogFile.Replace("wsjtx.log","ALL.TXT")
Write-Host "Using log file: $LogFile"
Write-Host "Using ALL.TXT file: $AllTxt"
Start-Sleep -Seconds 2
$UTCToday = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$SpotsLastFetched = (Get-Date).AddDays(-1)

while($UTCToday -eq (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd"))
{
    $Contacts = Import-Csv $LogFile -Header StartDate,StartTime,EndDate,EndTime,Call,Grid,Frequency,Mode,Sent,Received,TxPower,Comment,Name,PropMode
    $Contacts = $Contacts | ?{$_.EndDate -eq $UTCToday}
    $Contacts | %{$_ | Add-Member -MemberType NoteProperty -Name Band -Value ($_.Frequency -replace('\..*',''))}
    $Summary = $Contacts | Group-Object Call,Band,Mode

    if($MonitorSpots)
    {
        if($SpotsLastFetched -lt (Get-Date).AddMinutes(-1))
        {
            $SpotsLastFetched = Get-Date
            Write-Host "Fetching spots"
            $SpotResp = Invoke-WebRequest -Uri "https://api.pota.app/spot/activator"
            if($SpotResp.StatusCode -eq 200)
            {
                $Spots = $SpotResp.Content | ConvertFrom-Json
                #$Activators = $Spots | Select-Object -ExpandProperty activator
            }
            else 
            {
                Write-Warning "Failed to retrieve spots"
            }
            Start-Sleep -Seconds 2
        }

        ### TODO: Verify rx station list is from at least today or maybe this hour.
        $RxStations = Get-Content -Path $AllTxt -Last 50 | %{$_.split(" ")[-2]} | Sort-Object -Unique

        ### TODO: Filter worked stations from list but only if they were worked on the current band and mode.
        $RxSpots = $Spots | ?{$_.activator -in $RxStations}
    }

    Clear-Host
    $Summary | select Name,Count | Sort-Object Name | Out-Host
    Write-Host "Total contacts: $($Summary.Count)"
    Write-Host
    Write-Host "Received spots:"
    $RxSpots | Sort-Object activator | Format-Table activator,reference,name -HideTableHeaders | Out-Host
    Write-Host "All spots:"
    $Spots | ?{$_.mode -like "FT*"} | Sort-Object frequency,mode,activator | Format-Table activator,reference,frequency,mode,spotTime -HideTableHeaders
    1..5 | %{Write-Host "." -NoNewline; Start-Sleep -Seconds 1}
}
