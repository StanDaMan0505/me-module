Function Get-Base64String
{
    param(
        [string]$Text
    )

    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
    $EncodedText =[Convert]::ToBase64String($Bytes)
    $EncodedText
}
