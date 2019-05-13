Function Create-ThemisScript
{
    param
    (
      [String]$path = ''
    )

    $rows = $path.split("`r`n") # jede Zeile aufsplitten
    $rows = $rows.Replace("<", '') # < Zeichen entfernen
    $rows = $rows.Replace(">", '') # > Zeichen entfernen

    Write-Host ":on error exit"

    # Alle .sql Dateien ausgeben
    foreach($row in $rows)
    {        
        if( -not ([string]::IsNullOrEmpty($row))) # Für jede Zeile welche nicht leer ist
        {
            if(Test-Path "$row" -PathType Container)
            {
                If(Test-Path "$row") # Wenn Pfad existiert
                {
                    $files = Get-Childitem -Path "FileSystem::$($row.Trim())\*" -include *.sql | Sort-Object # Alle .sql Dateien im Pfad sammeln
                
                    foreach($file in $files) # Alle Dateien aus Pfad ausgeben
                    {
                        Write-Host ":r `"$file`""
                        Write-Host "GO"
                    }
                }
            }else
            {
                #Write-Host "Dateiname im Pfad... Ätsch"
                if(Test-Path "$row") # Wenn Datei existiert
                {
                    Write-Host ":r `"$row`""
                    Write-Host "GO"
                }
            }
        }
    }

    # Alle .sql Dateien zu UTF8 konvertieren und original Datei in neuem Verzeichnis speichern
    foreach($row in $rows)
    {        
        if( -not ([string]::IsNullOrEmpty($row))) # Für jede Zeile welche nicht leer ist
        {
            If(Test-Path "$row") # Wenn Pfad existiert
            {
                $files = Get-Childitem -Path "FileSystem::$($row.Trim())\*" -include *.sql # Alle .sql Dateien im Pfad sammeln

                foreach($file in $files)
                {
                    $backupPath = "$(Split-Path -Path $file -Parent)\orig" # Pfad um Original Datei abzulegen
                    if(-not (Test-Path $backupPath)) # Falls Pfad nicht existiert --> Pfad erstellen
                    {
                        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null 
                    }
                    Copy-Item -Path $file -Destination $backupPath -Force # Datei kopieren
                    Change-CodePage -path $file -encoding UTF8 # Datei als UTF8 speichern
                }                
            }
        }
    }
}
