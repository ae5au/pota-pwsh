$ADIF_Path = Resolve-Path $args[0]

if(!$ADIF_Path)
{
    Write-Warning "No valid file path provided."
    exit
}

$Original_Ref = ""
$Multi_Refs = @()
$State = ""

if($ADIF_Path.Path -match "US-9161")
{
    $Original_Ref = "US-9161"
    $Multi_Refs = "US-7435","US-3791"
    $State = "AR"
    Write-Host "Match $Original_Ref"
}
elseif($ADIF_Path.Path -match "US-10236")
{
    $Original_Ref = "US-10236"
    $Multi_Refs = "US-4424","US-7335"
    $State = "AR"
    Write-Host "Match $Original_Ref"
}
else
{
    Write-Warning "No match"
}
$ADIF = Get-Content $ADIF_Path

if($State)
{
    $ADIF = $ADIF -replace "<MY_CNTY:","<MY_STATE:$($State.Length)>$State <MY_CNTY:"
}

foreach($Ref in $Multi_Refs)
{
    echo "Changing $Original_Ref to $Ref"
    $RefPath = $ADIF_Path.Path -replace "\.adi"," $Ref.adi"
    $ADIF -replace "<MY_SIG_INFO:$($Original_Ref.Length)>$Original_Ref","<MY_SIG_INFO:$($Ref.Length)>$Ref" | Out-File -FilePath $RefPath
}
