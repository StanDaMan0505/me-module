Function Create-CredentialFile
{
    param(        
    )

    $cred = Get-Credential

    $filename = "$PSScriptRoot\$($cred.UserName).txt"
    New-Item -ItemType File -Path $filename -Force | Out-Null

    $cred.UserName | Out-File -FilePath $filename
    $EncodedText =[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($cred.GetNetworkCredential().Password))
    $EncodedText | Out-File -FilePath $filename -Append

    Write-Host "Datei $filename erstellt" -ForegroundColor Green
}