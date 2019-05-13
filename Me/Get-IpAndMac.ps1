Function Get-IpAndMac
{
<#
        .Synopsis
        Function to retrieve IP & MAC Address of a Machine.
        .DESCRIPTION
        This Function will retrieve IP & MAC Address of local and remote machines.
        .EXAMPLE
        PS>Get-ipmac -ComputerName viveklap
        Getting IP And Mac details:
        --------------------------

        Machine Name : TESTPC
        IP Address : 192.168.1.103
        MAC Address: 48:D2:24:9F:8F:92
        .INPUTS
        System.String[]
        .NOTES
        Author - Vivek RR
        Adapted logic from the below blog post
        "http://blogs.technet.com/b/heyscriptingguy/archive/2009/02/26/how-do-i-query-and-retrieve-dns-information.aspx"
#>

Param
(
    #Specify the Device names
    [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
    [string[]]$ComputerName
)
    Write-Host "Getting IP And Mac details:`n--------------------------`n"
    foreach ($Inputmachine in $ComputerName )
    {
        if (!(test-Connection -Cn $Inputmachine -quiet))
        {
            Write-Host "$Inputmachine : Is offline`n" -BackgroundColor Red
        }
        else
        {
            try{
                $IPAddress = ([System.Net.Dns]::GetHostByName($Inputmachine).AddressList).IpAddressToString
            }catch{
                $IPAddress = "N/A"
            }
            #$IPMAC | select MACAddress
            try{
                if($IPAddress.Count -gt 1)
                {
                    $IPMAC = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $Inputmachine
                    $MACAddress = ($IPMAC | where { $_.IpAddress -eq $IPAddress[1]}).MACAddress
                    if($MACAddress -eq $null)
                    { $MACAddress = "N/A" }
                }else
                {
                    $MACAddress = "N/A"
                }
            }catch{
                $MACAddress = "N/A"
            }
            try{
                $PrimaryOwnerName = Get-WmiObject -ComputerName $Inputmachine -Class Win32_ComputerSystem | Select PrimaryOwnerName
            }catch{
                $PrimaryOwnerName = "N/A"
            }
            Write-Host "Machine Name : $Inputmachine`nIP Address : $IPAddress`nMAC Address: $MACAddress`nUser name : $PrimaryOwnerName"
        }
    }
}

