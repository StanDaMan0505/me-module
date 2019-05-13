function Get-MyVirusTotalReport
{        
    [String] $hash = $null
    [String] $method = $null
    [int] $count = 1
    $body = @{}
    
    $VTApiKey = 'f67f52b4aedc9b79edd7d7e378e65d4533c4bf4d5389c4859beba9b39732d8a8'
    $fileUri = 'https://www.virustotal.com/vtapi/v2/file/report'
    $method = 'POST'
    $proxy = [System.Net.WebRequest]::GetSystemWebProxy().GetProxy("http://www.google.com")    

    $filenames = (Get-Process).MainModule.FileName
        
    Write-Host "Number of processes found: " $filenames.Length
    if($filenames.Length -ge 4){
        Write-Host "Only 4 processes per minute allowed to check with VirusTotal!"
    }
    $filesLeft = $filenames.length

    Start-Sleep -Seconds 2

    foreach($proc in $filenames)
    {            
        $hash = Get-Hash -file $proc
            
        $body = @{ resource = $hash; apikey = $VTApiKey}

        $result = Invoke-RestMethod -Method $method -Uri $fileUri -Body $body -Proxy $proxy
            
        foreach ($code in $result)
        {            
            if ($code.response_code -eq 0)
            {                
                Write-Host $proc -ForegroundColor Gray
                Write-Host "Not found in VT database. " -ForegroundColor Gray #+ $proc1[$track]
            }

            elseif (($code.response_code -eq 1) -and ($code.positives -ne 0))
            {
                Write-Host $proc -ForegroundColor Red
                Write-Host "Something malicious is found. " -ForegroundColor Red 
                Write-Host "$($code.Permalink)" -ForegroundColor Red
            }
        }

        if($count -ge 4)
        {
            $filesLeft -= $count
            Write-Host "Waiting for 60 seconds" -ForegroundColor Blue
            Write-Host $filesLeft files left to check
            Write-Host $null           
            
            Start-Sleep -Seconds 60
            $count = 0
        }
        $count++
    }          
}

function Get-Hash(
    [System.IO.FileInfo] $file = $(Throw 'Usage: Get-Hash [System.IO.FileInfo]'), 
    [String] $hashType = 'sha256')
{
  $stream = $null;  
  [string] $result = $null;
  $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($hashType )
  $stream = $file.OpenRead();
  $hashByteArray = $hashAlgorithm.ComputeHash($stream);
  $stream.Close();

  trap
  {
    if ($stream -ne $null) { $stream.Close(); }
    break;
  }

  # Convert the hash to Hex
  $hashByteArray | foreach { $result += $_.ToString("X2") }
  return $result
}