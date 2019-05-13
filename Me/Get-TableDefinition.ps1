Function Get-TableDefinition
{
    param(
        [Parameter(Mandatory=$true)][string]$Server,
        [Parameter(Mandatory=$true)][string]$Database,
        [Parameter(Mandatory=$true)][string]$Table,
        [Parameter(Mandatory=$false)][string]$Schema="dbo"
    )
    Import-Module sqlps

    $cred = Get-Credential sqldba
    $user = $cred.UserName
    $password = $cred.GetNetworkCredential().Password

    $options = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ScriptingOptions
    $options.DriAll = $true
    $options.SchemaQualify = $true

    $connection = New-Object -TypeName Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList $Server
    $connection.LoginSecure = $false
    $connection.Login = $user
    $connection.Password = $password
    $smoserver = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $connection

    $smoserver.Databases.Item($database).Tables.Item($table, $schema).Script($options) | ForEach-Object -Process { $_ + "`nGO"}

}