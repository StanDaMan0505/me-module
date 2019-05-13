function Change-CodePage
{
    param(
        [parameter(Mandatory=$true, Position=0)]
            [string] $path,
        [parameter(Mandatory=$false, Position=1)]
        [ValidateSet('Ascii','BigEndianUnicode','BigEndianUTF32','Byte','Default','Oem','String','Unicode','UTF32','UTF7','UTF8')]
            [string]$encoding
    )

    # Prüfen ob der übergebene Pfad eine Datei oder ein gesammter Pfad ist
    if([System.IO.Path]::GetExtension($path) -eq ".sql")
    {
        # Falls eine Datei angegeben wurde, wird die Datei im gleichen Verzeichnis konvertiert
        $convertedPath = "$path"
    }else
    {
        # Falls ein Pfad angegeben wurde, ein Unterverzeichnis mit dem Namen der neuen Codierung erstellen
        $convertedPath = "$path\$encoding"
    }
    
    if(-not (Test-Path($convertedPath)))
    {
        # Falls das Verzeichnis nicht existiert --> erstellen (wird nur gemacht, wenn ein Pfad in $path übergeben wurde)
        New-Item -ItemType Directory -Path "$convertedPath" -Force | Out-Null 
    }

    foreach($file2 in (Get-ChildItem -File -Path $path).FullName)
    {
        # Inhalt aus Datei auslesen
        $content = Get-Content $file2
        if($convertedPath -ne $path)
        {
            # Es wurde ein Pfad als Parameter $path übergeben

            $fileName = Split-Path $file2 -Leaf # Dateinamen auslesen
            Add-Content -Path "$convertedPath\$fileName" -Value $content -Encoding $encoding # Datei im neuen Verzeichnis mit neuer Codierung ablegen
        }else
        {
            Remove-Item -Path "$convertedPath" # Datei zuerst löschen
            Add-Content -Path "$convertedPath" -Value $content -Encoding $encoding # Datei mit neuer Codierung wieder herstellen
        }        
    }
}