Function Get-UnicodeFromBase64
{
    param(
        [string]$EncodedText
    )

    $DecodedText = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($EncodedText))
    $DecodedText 
}