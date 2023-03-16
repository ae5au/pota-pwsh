if ($IsLinux) {
    $LogFile = "~/.local/share/WSJT-X/wsjtx.log"
    Write-Host "Using log file: $LogFile"
}
elseif ($IsMacOS) {
    $LogFile = "~/Library/Application Support/WSJT-X/wsjtx.log"
    Write-Host "Using log file: $LogFile"
}
elseif ($IsWindows) {
    $LogFile = "~/AppData/Local/WSJT-X/wsjtx.log"
    Write-Host "Using log file: $LogFile"
}

$UTCToday = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")

while($UTCToday -eq (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd"))
{
    $Contacts = Import-Csv $LogFile -Header StartDate,StartTime,EndDate,EndTime,Call,Grid,Frequency,Mode,Sent,Received,TxPower,Comment,Name,PropMode
    $Contacts = $Contacts | ?{$_.EndDate -eq $UTCToday}
    $Contacts | %{$_ | Add-Member -MemberType NoteProperty -Name Band -Value ($_.Frequency -replace('\..*',''))}
    $Summary = $Contacts | Group-Object Call,Band,Mode

    Clear-Host
    $Summary | select Name,Count | Out-Host
    Write-Host "Total contacts: $($Summary.Count)"
    1..5 | %{Write-Host "." -NoNewline; Start-Sleep -Seconds 1}

}