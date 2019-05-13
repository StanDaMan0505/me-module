


Function Check-SQLServerVersion
{
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowWebsite
    )

    # URL
    $SQLUrl='https://buildnumbers.wordpress.com/sqlserver/'

    # Credentials für den Zugriff auf die SQL Server einlesen
    $credential = Get-Credential -username sqldba -Message "Berchtigung für die SQL-Server"
    $username  = $credential.UserName
    $password  = $credential.Password
    $password.MakeReadOnly()
    $creds = New-Object System.Data.SqlClient.SqlCredential($username, $password)

    #$count = 0

    foreach($line in Get-Content $PSScriptRoot\servers.txt )
    {
        #$count++
        #Write-Host $count
        # SQL Connection Objekt erstellen
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection

        # SQL Verbindung erstellen und öffnen
        $SqlConnection.ConnectionString = "Server=$line; Database=master; Integrated Security=false"
        $SqlConnection.Credential = $creds
        $SqlConnection.Open()

        # SQL Statement erstellen und ausführen
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.CommandTimeout = 0
        $SqlCmd.CommandText = "
            DECLARE @version VARCHAR(256)= @@VERSION;
            DECLARE @start INT= CHARINDEX('(', @version);
            DECLARE @end INT= CHARINDEX(')', @version);
            DECLARE @len INT= @end - @start;

            SELECT SERVERPROPERTY('ProductVersion') AS [ProductVersion], 
	            SUBSTRING(@version, 0, @start) AS [Version], 
	            SUBSTRING(@version, @start+1, @len-1) AS [ServicePack],
                @@LANGUAGE as [Language];
        "
        $SqlCmd.Connection = $SqlConnection

        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SqlCmd

        $DataSet = New-Object System.Data.DataSet
        $SqlAdapter.Fill($DataSet) | Out-Null

        # Verbindung schliessen
        $SqlConnection.Close()  

        # Welche Version ist es
        $productVersion = $Dataset.Tables[0].ProductVersion.ToString()
        $version = $Dataset.Tables[0].Version.ToString()
        $sp = $Dataset.Tables[0].ServicePack.ToString()
        $lang = $Dataset.Tables[0].Language.ToString()
        #Write-Host $productVersion
        $missing = new-object System.Data.DataTable

        try
        {
            # Komplette Webseite auslesen
            $WebRequest = Invoke-Webrequest $SQLUrl;

            # Alle Tabellen auslesen
            $tables = @($WebRequest.ParsedHtml.getElementsByTagName("TABLE"))

            # Erste Tabelle auslesen
            $versionTable = $tables[0]
            $rows = @($versionTable.Rows)
            $counter = 0
            $sqlversion = 0

            # Alle Zeilen durchgehen
            foreach($row in $rows)
            {
                # Text der letzten Spalte auslesen z.B. 15.0.1000.34 (CTP 2.0)
                $cells = @($row.Cells)
                $letzteSpalte = $cells.Count
                $text = $cells[$letzteSpalte-1].innerText
                # Wenn die ersten 2 Zeichen mit der Produktversion übereinstimmen, wurde die korrekte Zeile gefunden
                # Die Zeile entspricht auch der gewünschten Tabelle. z.B: die vierte Zeile entspricht SQL 2016, 
                # was auch der vierten Tabelle auf der Internet Seite entspricht
                if(($text).Substring(0,2) -eq ($productVersion).Substring(0,2) -and $sqlversion -eq 0)
                {
                    $sqlversion = $counter
                }
                $counter++
            }
<#

            switch (($productVersion).Substring(0,2))
            {
                # Die Nummer hier entspricht der Tabellennummer von der SQLUrl
                15 { $sqlversion = '1' } # '2019'
                14 { $sqlversion = '2' } # '2017'
                13 { $sqlversion = '3' } # '2016'
                12 { $sqlversion = '4' } # '2014'
                11 { $sqlversion = '5' } # '2012'
                10 { $sqlversion = '6' } # '2008'
            }             

#>
            # Benötigte Tabelle, beginnend mit 0, auslesen
            $table = $tables[$sqlversion]; 

            $titles = @();
            $dt = new-object System.Data.DataTable;
 
            $rows = @($table.Rows);
 
            # Durch alle Zeilen der Tabelle gehen
            foreach($row in $rows)
            {
                $cells = @($row.Cells)
                # Tabellen Header ermitteln
                if($cells[0].tagName -eq "TH")
                {
                    $titles = @($cells | % { ("" + $_.InnerText).Trim() });
                    continue;
                }
 
                # Falls keine Titel ermittelt werden konnte, einfach P1, P2 schreiben
                if(-not $titles)
                {
                    $titles = @(1..($cells.Count + 2) | % { "P$_" })
                }
                if ($dt.Columns.Count -eq 0)
                {
                    foreach ($title in $titles)
                    {
                        $col = New-Object System.Data.DataColumn($title, [System.String]);
                        $dt.Columns.Add($col);
                    } 
                    $col = New-Object System.Data.DataColumn('Link', [System.String]);
                    $dt.Columns.Add($col);
                } 
 
                $dr = $dt.NewRow();
                for($counter = 0; $counter -lt $cells.Count; $counter++)
                {
                    $c = $cells[$counter];
                    $title = $titles[$counter];
                    if(-not $title) { continue; }
                    $dr.$title = ("" + $c.InnerText).Trim();
                    if ($c.getElementsByTagName('a').length -gt 0)
                    {
                        $dr.Link = ($c.getElementsByTagName('a') | select -ExpandProperty href) -join ';';
                    }
                }
                $dt.Rows.add($dr);
            }
            $missing = $dt;
        }
        catch
        {
            Write-Error $_;
        }
        # Tabelle filtern
        #if($count -gt 1)
        #{
            Write-Host "Fehlende Hotfixes für $($line) ($version, $sp, $productVersion, $lang): " -ForegroundColor Yellow
            $missing.Select("Build > '$productVersion'", "Build desc") | Format-Table -AutoSize
            $str = "-" * 200
            Write-Host $str
        
        #}
    } # nächste Linie aus Datei lesen
    if($ShowWebsite)
    {
        $PageTableHeader=@'
            <html>
            <head>
            <style>
            body {
                font-size:16px;
                font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
                border-collapse: collapse;
                border-spacing: 0;
                width: 98%;
            }
            table#grid {
                font-size:14px;
                font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
                border-collapse: collapse;
                border-spacing: 0;
                width: 100%;
            }

            #grid td, #grid th {
                border: 1px solid #ddd;
                text-align: left;
                padding: 8px;
            }

            #grid tr:nth-child(even){background-color: #f2f2f2}

            #grid th {
                padding-top: 11px;
                padding-bottom: 11px;
                background-color: #4CAF50;
                color: white;
            }
            </style>
            <title>SQLServer Latest Service Pack and Cumulative Update</title>
            </head>
            <body>
            <h2>SQL Server : Last Service Pack By Date</h2>
            <pre><a href="https://technet.microsoft.com/en-us/library/ff803383.aspx">Microsoft Technet URL</a></pre>
'@
        # Technet Adresse mit all den korrekten Links
        $URI = "https://technet.microsoft.com/en-us/library/ff803383.aspx"
        # Webseite abrufen
	    $WebResponse = Invoke-WebRequest -UseBasicParsing -Uri $URI
        # Bereinigen
        $content = $WebResponse.RawContent -replace "\s*`n", " " 

        $Tab = $content -match "<table(.*)</table>"
        $Output = $matches[0]

        # Doppelte Leerzeichen bereinigen
        while ($Output.Contains("  "))
        {
            $Output = $Output -replace "  "," "
        }

        # Header erstellen
        $Output = $Output.replace('class="grid"','id="grid"').replace("<td> <strong>","<th>").replace("</strong> </td>","</th>")
        # Datei unter C:\Benutzer\USER\Download\ abspeichern
        $OutputFile = ".\SQLServer-Latest-SP-CU.html"            

        # Datei zusammenstellen
        $PageTableHeader | Out-File $OutputFile -Encoding default
        (Get-Date) | Out-File $OutputFile -Encoding default -Append
        $Output | Out-File $OutputFile -Encoding default -Append

        "<BR><font size='-1'>DANIEL STEFFEN</font> <br /></html>" | Out-File $OutputFile -Encoding default -Append
        # Ausgabe
        Write-Host "Output written to $OutputFile"
        # Datei öffnen
        Start $OutputFile
    }
}