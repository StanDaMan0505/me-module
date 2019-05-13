<#

# Konfiguration ausgeben
Get-DbcConfig | Out-GridView

# Konfiguration erstellen
#-------------------------

# Full Backup 7 Tage
Set-DbcConfig -Name policy.backup.fullmaxdays -Value 7

# DB Owner sa oder sqldba
Set-DbcConfig -Name policy.validdbowner.name -Value sa, sqldba

# Job owner sa oder sqldba
Set-DbcConfig -Name agent.validjobowner.name -Value sa, sqldba

# Log Backup 130 Minuten
Set-DbcConfig -Name policy.backup.logmaxminutes -Value 130

# Checks deaktivieren
Set-DbcConfig -Name command.invokedbccheck.excludecheck -value policy.database.filegrowthfreespacethreshold, policy.database.logfilecount

# Mailprofil angeben
Set-DbcConfig -Name agent.databasemailprofile -Value mailsg.abxsec.com
# Failsage Operator angeben
Set-DbcConfig -Name agent.failsafeoperator -Value "Abraxas Datenbanken"

# Recover Model nicht prüfen für system datenbanken
Set-DbcConfig -Name policy.recoverymodel.excludedb -Value 'master','msdb','tempdb'

# Offline Datenbanken excluden
#Set-DbcConfig -Name command.invokedbccheck.excludedatabases -Value VR_BERLINGEN, VR_BERLINGEN_REST
Set-DbcConfig -Name policy.database.status.excludeoffline -Value VR_BERLINGEN, VR_BERLINGEN_REST

# Db Mail sollte aktiviert sein
Set-DbcConfig -Name policy.security.databasemailenabled -Value $True

# Model Db Wachstum nicht testen
Set-DbcConfig -Name skip.instance.modeldbgrowth -Value $True

Export-DbcConfig -Path C:\temp\dbacheck_config.json

$cred = Get-Credential sqldba
$sqlInstances = "MSSQL132.local.vrsg.ch","MSSQL131.local.vrsg.ch"
Invoke-DbcCheck -SqlInstance $sqlInstances -AllChecks -Show Fails -PassThru -SqlCredential $cred | Update-DbcPowerBiDataSource -Environment local.vrsg

# Power BI Starten
Start-DbcPowerBi

#>

Function Get-DbcCheckResultForBI
{
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("vrsgappl","vrsg","vois", "all")][String]$Servergroup,
        [String]$ExportPath = "C:\temp\dbachecks"
    )
    # Der korrekte Pfad wäre
    #$pfad = "C:\Windows\Temp\dbachecks"

    $timeData = @()
    #$PowerBiDataPath = "C:\temp\dbachecks"
    $servers = @()
<#
    switch($ExportPath)
    {
        {$_ -in ("all", "vrsgappl")} {$servers += "10.55.72.97\prod01","10.55.73.97\prod03","10.55.73.98\test","srv107.vrsgappl.ch","srv108.vrsgappl.ch","srv109.vrsgappl.ch","srv110.vrsgappl.ch"}
        {$_ -in ("all", "vrsg")}     {$servers += "mssql131.local.vrsg.ch","mssql132.local.vrsg.ch","vrsgs93.local.vrsg.ch"}        
        {$_ -in ("all", "vois")}     {$servers += "inf-srv47.vois.local","mssql341.vois.local","mssql342.vois.local","mssql343.vois.local"}
        default                      {$servers += "localhost"}
    }
#>

    switch($Servergroup)
    {
        {$_ -in ("all", "vrsgappl")} {$servers += "srv107.vrsgappl.ch"}
        {$_ -in ("all", "vrsg")}     {$servers += "mssql132.local.vrsg.ch"}
        {$_ -in ("all", "vois")}     {$servers += "inf-srv47.vois.local","mssql341.vois.local","mssql342.vois.local","mssql343.vois.local"}
        default                      {$servers += "localhost"}
    }
    
    $servers = "srv107.vrsgappl.ch"
    Write-Host "Diese Server werden abgefragt:" -ForegroundColor Green
    $servers
    pause
<#
    $tags = 'ErrorLog','WhoIsActiveInstalled','TempDbConfiguration','DatafileAutoGrowthType','AutoCreateStatistics','OrphanedUser',
            'CompatibilityLevel','AutoUpdateStatistics','LastFullBackup','LastDiffBackup','LastLogBackup','RecoveryModel',
            'LastGoodCheckDb','ValidDatabaseOwner','SuspectPage','ValidJobOwner','FailedJob','DatabaseMailProfile',
            'AutoClose', 'AutoShrink', 'DAC', 'TempDbConfiguration', 'DatafileAutoGrowthType','DatabaseMailEnabled'
#>    

    $tags = 'LastFullBackup','LastDiffBackup','LastLogBackup','OrphanedUser','AutoUpdateStatistics','TempDbConfiguration','LastGoodCheckDb',
            'ValidDatabaseOwner','SuspectPage','DatabaseMailProfile','AutoClose', 'AutoShrink', 'DAC','DatabaseMailEnabled'
    
    #$tags = 'FKCKTrusted'

    Write-Host "Diese Prüfungen werden vorgenommen:" -ForegroundColor Green
    $tags
    pause

    $cred = Get-Credential sqldba

    $servers |    
        ForEach-Object {
            $serverName = $PSItem
  
            $tags | ForEach-Object {
                $tag = $PSItem
 
                $obj =  [pscustomobject]@{            
                    Server = $serverName
                    #NumServers = 1 #$sqlinstances.Count
                    Tag = $tag
                    InvokeStartTime = Get-Date
                    InvokeCompleteTime = $null
                    WriteResultsTime = $null
                    TestExecution = $null
                    InvokeDuration = $null
                    ResultsDuration = $null
                    PassedCount       = $null
                    FailedCount       = $null
                    SkippedCount      = $null
                    PendingCount      = $null
                    InconclusiveCount = $null               
                }
             
                $results = Invoke-DbcCheck -SqlInstance $serverName -tags $tag -PassThru -Show Fails -SqlCredential $cred

                $obj.TestExecution     = $results.time
                $obj.PassedCount       = $results.PassedCount      
                $obj.FailedCount       = $results.FailedCount      
                $obj.SkippedCount      = $results.SkippedCount     
                $obj.PendingCount      = $results.PendingCount     
                $obj.InconclusiveCount = $results.InconclusiveCount
 
                $obj.InvokeCompleteTime = Get-Date
 
                $results | Update-DbcPowerBiDataSource -Environment $serverName.Replace("\","_") -Path $ExportPath
                $obj.WriteResultsTime = Get-Date      
 
                $obj.InvokeDuration = New-TimeSpan -Start $obj.InvokeStartTime -End $obj.InvokeCompleteTime
                $obj.ResultsDuration = New-TimeSpan -Start $obj.InvokeCompleteTime -End $obj.WriteResultsTime 
 
                $timeData += $obj       
            } # $tags | ForEach-Object               
    } # $servers | ForEach-Object
 
    $timeData |
        Select-Object Server, tag, PassedCount, FailedCount, SkippedCount, InvokeDuration,  TestExecution, ResultsDuration |
        ft -AutoSize
}