#requires -version 4.0
<#
.SYNOPSIS
Retrieve SQL Server build history from 3rd party website
 
.DESCRIPTION
Get-SQLBuildHistory is to extract SQL Server build numbers from a web site, 
which defaults to https://buildnumbers.wordpress.com/sqlserver/ 
.Parameter
-SQLUrl weblink, defaulted to https://buildnumbers.wordpress.com/sqlserver/, non mandatory
 
.PARAMETER
-TableNumber indicates which table in the SQLUrl website shall we extract the SQL Build number,
the table number is 0 based, and defaults to 1 for the default  https://buildnumbers.wordpress.com/sqlserver/, 
not mandatory
 
.PARAMETER
-IncludeLink a switch parameter, if exists, will extract the HREF link out of the table column value
 
.EXAMPLE
The following returns the latest SQL Server (SQL Server 2017 as of today, 2018/Jan/02) Version Build
Get-SQLBuildHistory | format-table -auto 
 
Build         Description                                                        Release Date    
-----         -----------                                                        ------------    
14.0.3008.27  CU2 for Microsoft SQL Server 2017 (KB4052574)                      2017 November 28
14.0.3006.16  CU1 for Microsoft SQL Server 2017 (KB4038634)                      2017 October 24 
14.0.1000.169 SQL Server 2017 (vNext) RTM                                        2017 October 2  
14.0.900.75   SQL Server 2017 (vNext) RC2 (Release Candidate 2)                  2017 August 2   
14.0.800.90   SQL Server 2017 (vNext) RC1 (Release Candidate 1)                  2017 July 17    
14.0.600.250  SQL Server 2017 (vNext) CTP 2.1 (Community Technology Preview 2.1) 2017 May 17     
14.0.500.272  SQL Server 2017 (vNext) CTP 2.0 (Community Technology Preview 2.0) 2017 April 19   
14.0.405.198  SQL Server vNext CTP 1.4 (Community Technology Preview 1.4)        2017 March 18   
14.0.304.138  SQL Server vNext CTP 1.3 (Community Technology Preview 1.3)        2017 February 17
14.0.200.24   SQL Server vNext CTP 1.2 (Community Technology Preview 1.2)        2017 January 20 
14.0.100.187  SQL Server vNext CTP 1.1 (Community Technology Preview 1.1)        2016 December 16
14.0.1.246    SQL Server vNext CTP 1 (Community Technology Preview 1)            2016 November 16
 
.EXAMPLE
The following returns the SQL Server 2016 version build and the link
Get-SQLBuildHistory -TableNumber 2 -IncludeLink | Format-Table -Auto
 
#>
function Get-SQLBuildHistory
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$SQLUrl='https://buildnumbers.wordpress.com/sqlserver/',
 
        [Parameter(Mandatory = $false)]
        [int] $TableNumber=1, # 0 based
 
        [Parameter(Mandatory=$false)]
        [switch] $IncludeLink
    )
 
    ## Extract the tables out of the web request
    Write-Output $SQLUrl
    try
    {
        $WebRequest = invoke-webrequest $SQLUrl;
        $tables = @($WebRequest.ParsedHtml.getElementsByTagName("TABLE"))
        $table = $tables[$TableNumber];
        $titles = @();
        $dt = new-object System.Data.DataTable;
 
        $rows = @($table.Rows);
 
        ## Go through all of the rows in the table
        foreach($row in $rows)
        {
            $cells = @($row.Cells)
            ## If we've found a table header, remember its titles
            if($cells[0].tagName -eq "TH")
            {
                $titles = @($cells | % { ("" + $_.InnerText).Trim() });
                continue;
            }
 
            ## If we haven't found any table headers, make up names "P1", "P2", etc.
            if(-not $titles)
            {
                $titles = @(1..($cells.Count + 2) | % { "P$_" })
            }
            if ($dt.Columns.Count -eq 0)
            {
                foreach ($title in $titles)
                {
                    $col = New-Object System.Data.DataColumn($title, [System.String]);
                    $dt.Columns.Add($col);
                }
                if ($IncludeLink)
                {  
                    $col = New-Object System.Data.DataColumn('Link', [System.String]);
                    $dt.Columns.Add($col);
                }
 
            } #if $dt.columns.count -eq 0
 
            $dr = $dt.NewRow();
            for($counter = 0; $counter -lt $cells.Count; $counter++)
            {
                $c = $cells[$counter];
                $title = $titles[$counter];
                if(-not $title) { continue; }
                $dr.$title = ("" + $c.InnerText).Trim();
                if ($IncludeLink)
                {
                    if ($c.getElementsByTagName('a').length -gt 0)
                    {
                      $dr.Link = ($c.getElementsByTagName('a') | select -ExpandProperty href) -join ';';
                    }
                }
            }
            $dt.Rows.add($dr);
        }
        Write-Output $dt;
    }#try
    catch
    {
        Write-Error $_;
    }
}# Get-SQLBuildHisotry Get-SQLBuildHisotry