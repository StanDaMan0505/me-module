Function ConvertFrom-DecToHex
{
    Param(
        [Parameter(Mandatory=$true)] 
        [Int]$dec=$null        
    )
    
    if($dec -match "^[0-9]*$")
    {
        [String]::Format("{0:x}", $dec)
    }
    else
    {
        Write-Error "Value $dec is no int"
    }
}