

Function Create-AsciiTableFromCsv
{
    Param(
        #[Parameter(Mandatory=$true)]
        [string]$FilePath,
        [char]$Delimiter = ';',
        [switch]$NoHeader
    )
    #$FilePath = "C:\users\di125\Desktop\Mappe1.csv"
    $file = New-Object System.IO.StreamReader($FilePath)

    if(-not $NoHeader){
        
        $fileEnd = $file.ReadLine()        
        #Write-Host "länge: " $text.Length
        ParseTextHeader -parseText $fileEnd -delimiter $Delimiter
        while ($fileEnd -ne $null)
        {
            $fileEnd = $file.ReadLine()
            ParseText -parseText ($fileEnd) -delimiter $Delimiter
            #$file.ReadToEnd()
        }
    }else{
        $fileEnd = $file.ReadLine()
        while ($fileEnd -ne $null)
        {            
            ParseText -parseText ($fileEnd) -delimiter $Delimiter
            $fileEnd = $file.ReadLine()
        }
    }
        
    $file.Close()
}

Function ParseTextHeader
{
    Param(
        [string]$parseText,
        [char]$delimiter = ';',
        [int]$anzSpalten = 0
    )

    $start = 0
    $end   = 0    

    Write-Host "| " -NoNewline

    while ($end -ne -1)
    {
        $end = $parseText.IndexOf($delimiter,$start)
        if($end -eq -1){ 
            Write-Host $parseText.Substring($start,$parseText.Length-$start) -NoNewline
            Write-Host " |" 
        }else { 
            Write-Host $parseText.Substring($start,$end-$start) -NoNewline 
            Write-Host " | " -NoNewline
        }
        $start = $end + 1
        
        $anzSpalten++
    }
    #Write-Host
    Write-Host $("+" * (($parseText.Length) + ($anzSpalten) * (2) + 2))
    #Write-Host "Anz Spalten: "$anzSpalten
    #Write-Host "fertig: " $((($parseText.Length) + ($anzSpalten) * (2) + 2))
}


Function ParseText
{
    Param(
        [string]$parseText,
        [char]$delimiter = ';',
        [int]$anzSpalten = 0
    )

    $start = 0
    $end   = 0    

    Write-Host "| " -NoNewline

    while ($end -ne -1)
    {
        $end = $parseText.IndexOf($delimiter,$start)
        if($end -eq -1){ 
            Write-Host $parseText.Substring($start,$parseText.Length-$start) -NoNewline
            Write-Host " |" 
        }else { 
            Write-Host $parseText.Substring($start,$end-$start) -NoNewline 
            Write-Host " | " -NoNewline
        }
        $start = $end + 1
        
        $anzSpalten++
    }
    #Write-Host
    #Write-Host $("+" * (($parseText.Length) + ($anzSpalten) * (2) + 2))
    #Write-Host "Anz Spalten: "$anzSpalten
    #Write-Host "fertig: " $((($parseText.Length) + ($anzSpalten) * (2) + 2))
}

<#

$parseText2="| id1 | id2 | id3 | id4 |"
$parseText1="id1;id2;id3;id4;"
Write-Host $parseText2
Write-Host $("+" * (($parseText1.Length) + ($anzSpalten-1) * (3)))

Write-Host $("+" * (($anzSpalten-1) * (3) + 2))

#>