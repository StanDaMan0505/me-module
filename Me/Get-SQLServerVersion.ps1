Function Get-SQLServerVersion
{
    [cmdletbinding()]

    param(
        
    )

    # Credentials für den Zugriff auf die SQL Server einlesen
    $credential = Get-Credential -username sqldba -Message "Berchtigung für die SQL-Server"
    $username  = $credential.UserName
    $password  = $credential.Password
    $password.MakeReadOnly()
    $creds = New-Object System.Data.SqlClient.SqlCredential($username, $password)

    #$count = 0

    foreach($line in Get-Content $PSScriptRoot\servers.txt )
    {        
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

            SELECT   SERVERPROPERTY('ProductVersion') AS [ProductVersion], 
	                SUBSTRING(@version, 0, @start) AS [Version], 
	                SUBSTRING(@version, @start+1, @len-1) AS [ServicePack], 
	                @@LANGUAGE AS [Language], 
            (
                SELECT [Server_type] = CASE
						             WHEN [virtual_machine_type] = 1
						             THEN 'Virtual, ' + convert(varchar,(Select SERVERPROPERTY ( 'ComputerNamePhysicalNetBIOS' ))  )
						             ELSE 'Physical'
					              END
                FROM   [sys].[dm_os_sys_info]
            ) as [ServerType],
            SERVERPROPERTY('Edition') AS [Edition];
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
        $serverType = $DataSet.Tables[0].ServerType.ToString()
        $edition = $DataSet.Tables[0].Edition.ToString()
        
        Write-Host "$($line.ToUpper())`t: $($edition.Trim()), $($version.Trim()), $($sp.Trim()), $($productVersion.Trim()), $($lang.Trim()), $serverType " -ForegroundColor Yellow
            
        $str = "-" * 150
        Write-Host $str
        
    } # nächste Linie aus Datei lesen
}