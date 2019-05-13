Function Update-BrentFirstResponderKit
{
    try
    {
        $WebClient = New-Object -TypeName System.Net.WebClient
        #$WebClient.Headers.Add('Authorization','{OAuth token}')
        $uri = "https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit/archive/master.zip"
        $targetPath = "$env:TEMP\master-$(Get-Date -Format yyyy-MM-dd).zip"
        $AllProtocols = [System.Net.SecurityProtocolType]'Tls11,Tls12'
        [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
        $WebClient.DownloadFile($uri, $targetPath)
        Write-Host "Erfolgreich runtergeladen" -ForegroundColor Green

        # wird nach C:\Users\DI125\AppData\Local\Temp\SQL-Server-First-Responder-Kit-master entpackt
        #Write-Host "export pfad: $env:TEMP"
        Expand-Archive $targetPath -DestinationPath $env:TEMP -Force
        #Expand-Archive -LiteralPath $targetPath -OutputPath $env:TEMP -Force -ShowProgress

        Write-Host "Erfolgreich entpackt" -ForegroundColor Green

        $files = Get-ChildItem $env:TEMP\SQL-Server-First-Responder-Kit-master | Where-Object {$_.Extension -eq ".sql" -and $_.Name -notlike "Install*" -and $_.Name -notlike "*AllNightLog*"}

        foreach($f in $files)
        {
            #Copy-Item -Path $f.FullName -Destination "$env:USERPROFILE\AppData\Roaming\Microsoft\SQL Server Management Studio\12.0\Templates\Sql\_Monitoring\Brent"
            #Write-Host "Erfolgreich kopiert $($f.Name) nach SSMS 2014" -ForegroundColor Green
            Copy-Item -Path $f.FullName -Destination "$env:USERPROFILE\AppData\Roaming\Microsoft\SQL Server Management Studio\14.0\Templates\Sql\_Monitoring\Brent"
            Write-Host "Erfolgreich kopiert $($f.Name) nach SSMS 2017" -ForegroundColor Green
        }

        Remove-Item $env:TEMP\SQL-Server-First-Responder-Kit-master -Recurse -Force
        Write-Host "Erfolgreich Verzeichnis gelöscht" -ForegroundColor Green
        Remove-Item $targetPath -Force
        Write-Host "Erfolgreich Archiv gelöscht" -ForegroundColor Green
    }
    catch
    {
        Write-Error $_
    }
}