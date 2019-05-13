Function Write-MyOutput
{
    param(
        [Parameter(Mandatory=$True)][string]$Text,
        [ValidateRange(1,3)][int]$Errorvalue=3,
        [Parameter(ParameterSetName='ToLogFile')][switch]$ToLogFile,
        [Parameter(ParameterSetName='ToLogFile')][string]$Path
    )

    $t = $host.ui.RawUI.ForegroundColor

    switch($Errorvalue)
    {
        1{        $host.ui.RawUI.ForegroundColor =  "Red"    }
        2{        $host.ui.RawUI.ForegroundColor =  "Yellow" }
        3{        $host.ui.RawUI.ForegroundColor =  "Green"  }
    }
    
    if(-not($ToLogFile))
    {
        Write-Output $Text
    }else
    {
        Write-Output $Text | Tee-Object -FilePath $Path -Append
    }
    
    $host.ui.RawUI.ForegroundColor = $t
}
