Function Get-SID
{
    param(
        [parameter()]
        [string][ValidateNotNullOrEmpty()]$name
    )
    $wmi = [wmi]"win32_useraccount.domain='vrsg',name='$($name)'"
    $wmi.SID
    Write-Host
    $wmi
}