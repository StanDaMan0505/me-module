
Function Write-MyLog
{
<#
    .SYNOPSIS
    Erstellt eine Log Datei und schreibt rein.

    .DESCRIPTION
    Erstellt eine Log Datei und schreibt rein. 
    Die Datei wird im Verzeichnis \\srv117\scripts$\Powershell\Log abgelegt.

    .PARAMETER Errorlevel
    Damit kann gesteuer werden, was für ein Schweregrad die Meldung haben soll.
    0 = START
    1 = INFO
    2 = WARN
    3 = ERROR
    4 = DONE

    .PARAMETER FilenamePrefix
    Hiermit kan der Dateinamen angegeben werden, welcher verwendet wird.
    Am Dateinamen wird immer das aktuelle Datum hinten angehängt.

    .PARAMETER Logstring
    Der Text, welcher ins Log geschrieben werden soll.

    .EXAMPLE VRSG-WriteLog -Errorlevel 1 -FilenamePrefix FIS-Backup -Logstring "Eine Information"

    Erstellt folgenden Eintrag in der Datei \\srv117\scripts$\Powershell\Log\FIS-Backup-2016-10-05.log :

    2016-10-05 08:25:23  INFO  Eine Information

    .EXAMPLE VRSG-WriteLog -Errorlevel 2 -FilenamePrefix FIS-Backup -Logstring "Eine Warnung"

    Erstellt folgenden Eintrag in der Datei \\srv117\scripts$\Powershell\Log\FIS-Backup-2016-10-05.log :

    2016-10-05 08:25:23  WARN  Eine Warnung

    .EXAMPLE VRSG-WriteLog -Errorlevel 3 -FilenamePrefix FIS-Backup -Logstring "Eine Fehler"

    Erstellt folgenden Eintrag in der Datei \\srv117\scripts$\Powershell\Log\FIS-Backup-2016-10-05.log :

    2016-10-05 08:25:23  ERROR  Ein Fehler

    .EXAMPLE VRSG-WriteLog 0 FIS-Backup "Eine Start-Meldung"

    Erstellt folgenden Eintrag in der Datei \\srv117\scripts$\Powershell\Log\FIS-Backup-2016-10-05.log :

    2016-10-05 08:25:23  START  Eine Start-Meldung

    .LINK

    .NOTES
    #>


    Param (
        [int]$Errorlevel,
        [string]$FilenamePrefix,
        [string]$Logstring
    )

    $filepath = "FileSystem::C:\temp\Powershell\Log"
    if(-not(Test-Path $filepath))
    {
        New-Item $filepath -ItemType Directory -Force  | Out-Null            
    }

    $sFullLogPath = "$filepath\$($FilenamePrefix)-$(Get-Date -format yyyy-MM-dd).log"

    $date = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    $fullLogString = $null
    switch($Errorlevel)
    {
        0 {$fullLogString = "$date`t`tSTART`t`t$Logstring"}
        1 {$fullLogString = "$date`t`tINFO`t`t$Logstring"}
        2 {$fullLogString = "$date`t`tWARN`t`t$Logstring"}
        3 {$fullLogString = "$date`t`tERROR`t`t$Logstring"}
        4 {$fullLogString = "$date`t`tDONE`t`t$Logstring"}
    }         
    
    try{
        Add-Content -Path $sFullLogPath -Value $fullLogString -Encoding UTF8
    }catch{
        Write-Error $_
    }
}