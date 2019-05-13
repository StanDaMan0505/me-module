Function ConvertFrom-HexToBin
{
    Param(
        [Parameter(Mandatory=$true)] 
        [String]$hex=$null        
    )
    if($hex.StartsWith('0x',2))
    {
        [Convert]::ToString([Convert]::ToString($hex,10),2)
    }
    else
    {
        Write-Error "Parameter `$hex has to start with 0x"
    }

}