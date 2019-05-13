function Database-Inventory
{
    #Import-Module sqlps -DisableNameChecking

    $filename = "C:\Users\DI125\Documents\Dokumentationen\Datenbanken.xlsx"

    # Kopie der Datei erstellen
    $a = Get-Date -Format yyyy-MM-dd_HHmmss
    if (Test-Path $filename){
        Copy-Item -Path $filename -Destination "$env:USERPROFILE\Documents\Dokumentationen\Archiv\Datenbanken-$a.xlsx" -Force
    }

    if(Test-Path "V:\ORG\IOS\Application Operations\Datenbanken & Middleware\Microsoft\SQL\Dokumente\Inventar\Archiv"){
        Copy-Item -Path $filename -Destination "V:\ORG\IOS\Application Operations\Datenbanken & Middleware\Microsoft\SQL\Dokumente\Inventar\Archiv\Datenbanken-$a.xlsx" -Force
    }else
    {
        Write-Host "Kann Archiv nicht finden. Pfad existiert nicht" -ForegroundColor Yellow
    }


    #region SQL TEIL 
#    $server = @("INF-SRV47.VOIS.LOCAL","MSSQL311.VOIS.LOCAL", "MSSQL312.VOIS.LOCAL", "MSSQL341.VOIS.LOCAL", "MSSQL342.VOIS.LOCAL", # Externe Server
#                <#"MSSQL111.LOCAL.VRSG.CH", "MSSQL112.LOCAL.VRSG.CH", "MSSQL121.LOCAL.VRSG.CH", "MSSQL122.LOCAL.VRSG.CH",#> 
#                "MSSQL131.LOCAL.VRSG.CH","MSSQL132.LOCAL.VRSG.CH","VRSGS93.LOCAL.VRSG.CH" # VRSG Interne Server
#                <#"MSSQL221.VRSGAPPL.CH", "MSSQL222.VRSGAPPL.CH", "MSSQL223.VRSGAPPL.CH", "MSSQL224.VRSGAPPL.CH",#> # VRSGAPPL Server
#                "10.55.72.97\PROD01","10.55.73.97\PROD03","10.55.73.98\TEST",
#                "SRV107.VRSGAPPL.CH", "SRV108.VRSGAPPL.CH", "SRV109.VRSGAPPL.CH", "SRV110.VRSGAPPL.CH") # VRSGAPPL Server

    $server = Get-Content $PSScriptRoot\servers.txt

    # Credentials für den Zugriff auf die SQL Server einlesen
    $credential = Get-Credential -username sqldba -Message "Berchtigung für die SQL-Server"
    $username  = $credential.UserName
    $password  = $credential.Password
    $password.MakeReadOnly()
    $creds = New-Object System.Data.SqlClient.SqlCredential($username, $password)

    # SQL Connection Objekt erstellen
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection

    #endregion

    #region EXCEL TEIL

    # Excel Objekt erstellen 
    $excel = New-Object -ComObject Excel.Application

    # Sichtbarkeit auf true setzen um Prozess ID auszulesen
    $excel.Visible = $true
    # Prozess ID auslesen
    $procId = Get-Process | Where-Object {$_.MainWindowHandle -eq $excel.HWND} | Select-Object -ExpandProperty ID
    #Sichtbarkeit auf false setzen
    $excel.Visible = $false

    # Warnungen deaktivieren
    $excel.DisplayAlerts = $false

    # Worksheets hinzufügen (3)
    $workbook = $excel.Workbooks.add()

    # Überflüssige Worksheets wieder entfernen (nur bei Excel 2012, nicht bei Excel 2016)
    if($excel.Version -ne "16.0")
    {
        $workbook.workSheets.item(3).delete()
        $workbook.workSheets.item(2).delete()
    }

    # Verbindung zum Worksheet erstellen
    $sheet = $workbook.Worksheets.Item(1)

    #endregion 

    $dbCount = $null

    foreach($srv in $server)
    {
        # Informationen Ausgeben
        Write-Host "Inventar von Server $srv" -ForegroundColor Green -NoNewline

        # Name des Worksheets mit dem Servernamen anpassen
        $workbook.WorkSheets.item(1).Name = $srv.Replace("\","-")

        # Verbindung zum umbenannten Worksheet erneuern
        $sheet = $workbook.WorkSheets.Item($srv.Replace("\","-"))

        # Titel einfügen
        $sheet.cells.item(1,1) = "Name of Database"
        $sheet.cells.item(1,2) = "Database ID"
        $sheet.cells.item(1,3) = "Create Date"
        $sheet.cells.item(1,4) = "Status"
        $sheet.cells.item(1,5) = "Recover Mode"
        $sheet.cells.item(1,6) = "Data GB"
        $sheet.cells.item(1,7) = "Log GB"
        $sheet.cells.item(1,8) = "Total GB"
        $sheet.cells.item(1,9) = "Compt.Lvl."
        $sheet.cells.item(1,10)= "Coll."

        # Titel formatieren
        $sheet.cells.item(1,1).ColumnWidth = 50
        $sheet.cells.item(1,1).Font.Bold = $true
        $sheet.cells.item(1,2).Font.Bold = $true
        $sheet.cells.item(1,3).ColumnWidth = 30
        $sheet.cells.item(1,3).Font.Bold = $true
        $sheet.cells.item(1,4).Font.Bold = $true
        $sheet.cells.item(1,5).Font.Bold = $true
        $sheet.cells.item(1,6).Font.Bold = $true
        $sheet.cells.item(1,7).Font.Bold = $true
        $sheet.cells.item(1,8).Font.Bold = $true
        $sheet.cells.item(1,9).Font.Bold = $true
        $sheet.cells.item(1,10).Font.Bold= $true

        # SQL Verbindung erstellen und öffnen
        $SqlConnection.ConnectionString = "Server=$srv; Database=master; Integrated Security=false"
        $SqlConnection.Credential = $creds
        $SqlConnection.Open()

        # SQL Statement erstellen und ausführen
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.CommandTimeout = 0
        $SqlCmd.CommandText = '    
    
    IF OBJECT_ID(''tempdb.dbo.#space'') IS NOT NULL
     DROP TABLE #space

    CREATE TABLE #space (
          database_id INT PRIMARY KEY
        , data_used_size DECIMAL(18,2)
        , log_used_size DECIMAL(18,2)
    )

    DECLARE @SQL NVARCHAR(MAX)
    DECLARE @v VARCHAR(4)
    SELECT @v = convert(varchar,SERVERPROPERTY(''productversion''))

    IF ( @v like ''12.%'')
    BEGIN

    SELECT @SQL = STUFF((
        SELECT ''
        USE ['' + d.name + '']
        INSERT INTO #space (database_id, data_used_size, log_used_size)
        SELECT
              DB_ID()
            , SUM(CASE WHEN [type] = 0 THEN space_used END)
            , SUM(CASE WHEN [type] = 1 THEN space_used END)
        FROM (
            SELECT s.[type], space_used = SUM(FILEPROPERTY(s.name, ''''SpaceUsed'''') * 8. / 1024)
            FROM sys.database_files s
            GROUP BY s.[type]
        ) t;''
        FROM sys.databases d
        WHERE d.[state] = 0
	    AND d.database_id > 4
        AND sys.fn_hadr_backup_is_preferred_replica(d.name) = 1
        FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''')
    END
    ELSE
    BEGIN

    SELECT @SQL = STUFF((
        SELECT ''
        USE ['' + d.name + '']
        INSERT INTO #space (database_id, data_used_size, log_used_size)
        SELECT
              DB_ID()
            , SUM(CASE WHEN [type] = 0 THEN space_used END)
            , SUM(CASE WHEN [type] = 1 THEN space_used END)
        FROM (
            SELECT s.[type], space_used = SUM(FILEPROPERTY(s.name, ''''SpaceUsed'''') * 8. / 1024)
            FROM sys.database_files s
            GROUP BY s.[type]
        ) t;''
        FROM sys.databases d
        WHERE d.[state] = 0
	    AND d.database_id > 4
        FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''')

    END

    EXEC sys.sp_executesql @SQL

    SELECT
          d.name
	    , d.database_id
	    , d.create_date
        , d.state_desc
        , d.recovery_model_desc    
        , t.data_sizeGB
        , t.log_sizeGB
	    , t.total_sizeGB
        , d.compatibility_level
        , d.collation_name
    FROM (
        SELECT
              database_id
            , log_sizeGB = CAST(SUM(CASE WHEN [type] = 1 THEN size END) * 8. / 1024 /1024 AS DECIMAL(18,2))
            , data_sizeGB = CAST(SUM(CASE WHEN [type] = 0 THEN size END) * 8. / 1024 / 1024 AS DECIMAL(18,2))
            , total_sizeGB = CAST(SUM(size) * 8. / 1024 / 1024 AS DECIMAL(18,2))
        FROM sys.master_files
        GROUP BY database_id
    ) t
    JOIN sys.databases d ON d.database_id = t.database_id
    JOIN #space s ON d.database_id = s.database_id
    where t.database_id > 4
    ORDER BY name asc
        '
        $SqlCmd.Connection = $SqlConnection
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SqlCmd
        $DataSet = New-Object System.Data.DataSet
        $SqlAdapter.Fill($DataSet) | Out-Null

        # Resultat in $table speichern
        $table = $DataSet.Tables[0]

        # Anzahl Datenbanken pro Server ausgeben
        Write-Host "`t`t $($table.Rows.Count) Datenbanken"

        # Anzahl Datenbanken zusammenzählen
        $dbCount += $table.Rows.Count

        # Ab der zweiten Zeile schreiben
        $x = 2

        # Reultat in die einzelnen Zellen schreiben
        Foreach($d in $table)
        {
            $sheet.cells.item($x, 1) = $d.Name
            $sheet.cells.item($x, 2) = $d.database_id
            $sheet.cells.item($x, 3) = $d.create_date
            $sheet.cells.item($x, 4) = $d.state_desc
            $sheet.cells.item($x, 5) = $d.recovery_model_desc
            $sheet.cells.item($x, 6) = $d.data_sizeGB
            $sheet.cells.item($x, 7) = $d.log_sizeGB
            $sheet.cells.item($x, 8) = $d.total_sizeGB
            $sheet.cells.item($x, 9) = $d.compatibility_level
            $sheet.cells.item($x,10) = $d.collation_name
            $x+= 1
        }
        # Spaltenbreite anpassen
        $sheet.UsedRange.EntireColumn.AutoFit() | Out-Null

        # Zoom auf 130% setzen
        $excel.ActiveWindow.Zoom = 130    

        # Neues Arbeitsblatt einfügen
        $workbook.Sheets.Add() | Out-Null

        # Verbindung schliessen
        $SqlConnection.Close()    
    }
    # Das letzte Worksheet wieder löschen
    $workbook.workSheets.item(1).delete()

    # Datei speichern
    $xlFixedFormat = [Microsoft.Office.Interop.Excel.XlFileFormat]::xlWorkbookDefault
    $excel.ActiveWorkbook.SaveAs($filename, $xlFixedFormat)

    # Excel schliessen
    $excel.Workbooks.Close()
    # Excel Prozess beenden
    Get-Process -Id $ProcID | Stop-Process -Force
    # $excel.Quit() # Funktioniert nicht sauber

    Write-Host "Anzahl Datenbanken auf allen Servern $dbCount" -ForegroundColor Cyan

    # Kopie der Datei erstellen
    if (Test-Path 'V:\ORG\IOS\Application Operations\Datenbanken & Middleware\Microsoft\SQL\Dokumente\Inventar\'){
        Copy-Item -Path $filename -Destination "V:\ORG\IOS\Application Operations\Datenbanken & Middleware\Microsoft\SQL\Dokumente\Inventar\\Datenbanken.xlsx" -Force
    }else
    {
        Write-Host "Kann die neue Datei nicht kopieren. Pfad nicht gefunden" -ForegroundColor Yellow
    }

    while([System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)){}
    Remove-Variable excel
}