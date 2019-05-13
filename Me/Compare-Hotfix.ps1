function Compare-Hotfix ($computer1, $computer2)
{
    $node1 = Get-HotFix -ComputerName $computer1
    $node2 = Get-HotFix -ComputerName $computer2
    Compare-Object -ReferenceObject $node1 -DifferenceObject $node2  -Property HotFixID
}
