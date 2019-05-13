Function Get-ThemisReleaseVersion
{

    # Credentials für den Zugriff auf die SQL Server einlesen
    $credential = Get-Credential -username sqldba -Message "Berchtigung für die SQL-Server"
    $username  = $credential.UserName
    $password  = $credential.Password
    $password.MakeReadOnly()
    $creds = New-Object System.Data.SqlClient.SqlCredential($username, $password)

    # SQL Connection Objekt erstellen
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection

    $server = @("SRV107.VRSGAPPL.CH","SRV110.VRSGAPPL.CH")
    $output = @()
    foreach($srv in $server)
    {
        #Write-Host Server: $srv
        switch ($srv)
        {
            "SRV107.VRSGAPPL.CH" { $dbs = @("THEMIS_TEST_DATA","THEMIS_RELEASE_DATA","THEMIS_ABNA_DATA","THEMIS_SCHU_DATA")}            
            "SRV110.VRSGAPPL.CH" { $dbs = @("THEMIS_PROD_DATA")}
        }

        # SQL Verbindung erstellen und öffnen
        $SqlConnection.ConnectionString = "Server=$srv; Database=master; Integrated Security=false"
        $SqlConnection.Credential = $creds
        $SqlConnection.Open()

        foreach($db in $dbs)
        {
            #Write-Host DB: $db
            # SQL Statement erstellen und ausführen
            $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
            $SqlCmd.CommandTimeout = 0
            $SqlCmd.CommandText = "
    USE [$db];


SELECT TOP 1 [NOM], 
		   [ENDTIME], 
		   ISNULL(
(
    SELECT TOP 1 [restore_date]
    FROM             [msdb]..[restorehistory]
    WHERE           [destination_database_name] = '$db'
    ORDER BY [restore_history_id] DESC
), '1999-01-01') AS [RESTOREDATE], 
(
    SELECT TOP 1 [ENDTIME]
    FROM         [OD_BATCH_LOG]
    ORDER BY [IDH] DESC
) AS [LASTSCRIPT]
FROM [OD_BATCH_LOG]
WHERE 1 = 1
	 AND [NOM] LIKE 'END%'
ORDER BY 1 DESC;

            "
            $SqlCmd.Connection = $SqlConnection
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
            $SqlAdapter.SelectCommand = $SqlCmd
            $DataSet = New-Object System.Data.DataSet
            $SqlAdapter.Fill($DataSet) | Out-Null

            # Resultat in $table speichern
            $table = $DataSet.Tables[0]  
            #$table 
            $versionTable = New-Object -TypeName PSObject -Property @{
                                                    Umgebung = $db
                                                    Version = ($table.NOM).Substring(4)
                                                    Datum = ($table.ENDTIME).ToString().Substring(0,10)
                                                    LastRestore = ($table.RESTOREDATE).ToString().Substring(0,10)
                                                    LastScript = ($table.LASTSCRIPT).ToString().Substring(0,10)
                                                }
            $output += $versionTable
            #Write-Host output: $output
        }
        # Verbindung schliessen
        $SqlConnection.Close() 
    }    
    # Ausgabe
    $output | Select-Object Umgebung, Version, Datum, LastRestore, LastScript | Format-Table
}