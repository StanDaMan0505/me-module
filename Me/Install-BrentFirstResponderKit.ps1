Function Install-BrentFirstResponderKit
{
    param(
        [string[]]$server= @()
    )
    Import-Module SQLPS -DisableNameChecking

    if($server.Count -eq 0)
    {
        $server = Get-Content $PSScriptRoot\servers.txt
    }

    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null

    #alle dateien finden, welche installiert werden sollen
    $path = "$env:USERPROFILE\AppData\Roaming\Microsoft\SQL Server Management Studio\14.0\Templates\Sql\_Monitoring\Brent"
    $onlyFiles = ("sp_Blitz.sql","sp_BlitzCache.sql","sp_BlitzFirst.sql","sp_BlitzIndex.sql","sp_BlitzLock.sql","sp_BlitzWho.sql","sp_BlitzBackups.sql")
    $files = Get-ChildItem $path\* -Include $onlyFiles
    
    # Credentials für den Zugriff auf die SQL Server einlesen
    $credential = Get-Credential -username sqldba -Message "Berchtigung für die SQL-Server"

    foreach($srv in $server)
    {
        Write-Host "Server: `t $srv" -ForegroundColor Green
        $x = $sqlConnection = New-Object Microsoft.SqlServer.Management.Smo.Server $srv
        $x.ConnectionContext.LoginSecure = $false
        $x.ConnectionContext.set_Login($credential.username)
        $x.ConnectionContext.set_SecurePassword($credential.password)
        $x.ConnectionContext.Connect()

        foreach($file in $files)
        {
            try
            {
                Invoke-Sqlcmd -Database master -Query $(Get-Content $file -Raw) -ServerInstance $x -Username $credential.UserName -Password $credential.GetNetworkCredential().Password
                Write-Host "Successfully installed: `t $($file.Name)" -ForegroundColor Green
            }
            catch
            {
                Write-Host "Not installed: `t $($file.Name)" -ForegroundColor Red
            }
        }
        $x.ConnectionContext.Disconnect()
    }
}