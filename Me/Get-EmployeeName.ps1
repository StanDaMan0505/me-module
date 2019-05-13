Function Get-EmployeeName
{
    param(
        [string]$id,
        [switch]$picture
    )

    $srv = 'mssql131.local.vrsg.ch'
    $db = 'VR_BADGEMAKER_PROD'
    $buffer = 8192

    # Credentials für den Zugriff auf die SQL Server einlesen
    #$credential = Get-Credential -username sqldba -Message "Berchtigung für die SQL-Server"

    $query = ("
        SELECT LogonID
              ,[Surname]
              ,[Givenname]
              ,[ExternalUser]
          FROM [VR_BADGEMAKER_PROD].[dbo].[UserListABX]
        where LogonID like '%$id%'
        ")

    try{
        #Invoke-Sqlcmd -Database $db -ServerInstance $srv -Username sqldba -Password $([System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String("YQBkAG0AMQA5ACkA")))  -Query $query

        $con = New-Object Data.SqlClient.SqlConnection; 
        $con.ConnectionString = "Data Source=$srv;" + 
        "Integrated Security=false;" + 
        "Initial Catalog=$db;" +
        "User id=sqldba;" +
        "Password=$([System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String("YQBkAG0AMQA5ACkA")))"; 

        $con.Open(); 

        $cmd = New-Object Data.SqlClient.SqlCommand $query, $con;
        
        $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $cmd
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataSet) | Out-Null
        
        $dataset.Tables

        if($picture)
        {
            if($dataset.tables[0].Rows.Count -eq 1)
            {
                $query = ("
                    SELECT [ID]
                          ,[Picture]
                    FROM [VR_BADGEMAKER_PROD].[dbo].[PicturesABX]
                    where id like '%$id%'
                ")

                $cmd = New-Object Data.SqlClient.SqlCommand $query, $con;

                $rd = $cmd.ExecuteReader(); 
                $out = [array]::CreateInstance('Byte',$buffer)            

                while($rd.Read())
                {
                    try
                    {
                        $file = $env:TEMP + '\' + $rd.GetString(0) + '.jpg'
                        $fs = New-Object System.IO.FileStream ($file), Create, Write;
                        $bw = New-Object System.IO.BinaryWriter $fs

                        $start = 0

                        $received = $rd.GetBytes(1, $start, $out, 0, $buffer - 1)
                        while($received -gt 0)
                        {
                            $bw.Write($out,0, $received)
                            $bw.Flush()
                            $start += $received
                            $received = $rd.GetBytes(1, $start, $out, 0, $buffer - 1)
                        }
                        $bw.Close()
                        $fs.Close()
                        & $file
                    }
                    catch
                    {
                        Write-Host $_.Exception.Message -ForegroundColor Red
                        Write-Host $_.Exception.ItemName -ForegroundColor Red
                    }
                    finally
                    {
                        $fs.Dispose()        
                    }
                }
                $rd.Close(); 
            }else
            { Write-Host "Kein oder mehr als ein Resultat gefunden. Bild wird nicht angezeigt!" -ForegroundColor Yellow }
        }

        $cmd.Dispose(); 
        $con.Close();
    }catch{
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_.Exception.ItemName -ForegroundColor Red
    }
}