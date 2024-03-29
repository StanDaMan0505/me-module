#requires -version 5.0
function Update-Sysinternals
{
    param (
        $NewPath = "https://download.sysinternals.com/files/SysinternalsSuite.zip",
        $OldPath = "$Env:UserProfile\Downloads\SysinternalsSuite.zip",
        $BaseDir = "$Env:UserProfile\Downloads\SysinternalsSuite",
        [Switch]$Email
    )
      
    try
    {

        # Get the list of files before the update
        $Files = Get-ChildItem -Path $BaseDir
            
        # Download the new zip file of tools
        Invoke-WebRequest -UseBasicParsing -Uri $NewPath -OutFile $OldPath -Verbose

        # Some sysinternals apps are often is locked, kill those processes
        $Running = Get-Process zoomit*, desktops*, procexp* -ErrorAction SilentlyContinue
        $Paths = $Running | Where-Object {$_.name -notlike '*64'} | Select-Object -Property Path
        if ($Running)
        {
            $Running | Stop-Process -Force -Verbose
        }
            
        try
        {
                  
            Expand-Archive -LiteralPath $OldPath -DestinationPath $BaseDir -Force

            $FilesUpdate = Get-ChildItem -Path $BaseDir
                  
            $Updates = Compare-Object -ReferenceObject $Files -DifferenceObject $FilesUpdate | 
                Select-Object -ExpandProperty InputObject |
                ForEach-Object {Get-ChildItem -Path $BaseDir\$_} | Select-Object Name, CreationTime
                  
            # See for Send-HtmlEmail cmdlet http://bit.ly/fPzbMO
            if ($Updates -and $Email)
            {
                Send-HTMLEmail -InputObject $Updates -Subject "Sysinternals suite updated $(Get-Date)"
            }

        }
        Catch
        {
            Write-Warning -Message $_
        }
        finally
        {
            
            # Restart any applications that were running previously
            if ($Paths)
            {
                $Paths | ForEach-Object { Start-Process -FilePath $_.Path }
            }
        }
    }
    catch
    {
        "Cannot connect to: $NewPath, please ensure you are connected to the Internet."   
    }
}#Update-Sysinternals

