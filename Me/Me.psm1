<#
    .SYNOPSIS
    Hiermit werden die verschiedenen Funktionen zu Verfügung gestellt.

    .DESCRIPTION
    Im "Tasks" Verzeichnis sollen sich Funktionen befinden, welche eine Änderung am System vornehmen. Z.B: Backup-, Restore-, Löschen einer Datenbank etc.
    Dateien in diesem Verzeichnis müssen so heissen wie die Funktion, welche sich darin befindet. Nur eine Funktion pro Datei.

    Im "Maintenance" Verzeichis sollen sich Funktionen befinden, welche keine Änderung am System vornehmen und stattdessen eine Information ausgeben. Z.B: Availability Group Information, Backup Info, etc.
    Dateien in diesem Verzeichnis müssen so heissen wie die Funktion, welche sich darin befindet. Nur eine Funktion pro Datei.

    Im "Helper" Verzeichnis sollen sich Funktionen befinden, welche zum ausführen der Funktionen in den Verzeichnissen "Tasks" und "Maintenance" notwendig sind. 
    Z.B: Neue SMO Verbindung aufbauen, Log schreiben, Assembly laden, etc.
    Dateien in diesem Verzeichnis können mehrere Funktionen enthalten.

    .NOTES
    
#>

# Get the functions to import
$Maintenance  = @( Get-ChildItem -Path $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Recurse -ErrorAction SilentlyContinue )

# Dot source the files --> Könnte auch so gemacht werden: $($Maintenance + $Tasks + $Helper).Fullname | %{. $_} oder $($Maintenance + $Tasks + $Helper).Fullname | ForEach-Object {. $_} 
Foreach($import in ($Private + $Maintenance))
{
	Try
	{
		. $import.fullname
	}
	Catch
	{
		Write-Error -Message "Failed to import function $($import.fullname): $_"
	}
}

# Export the Public modules
Export-ModuleMember -Function $Maintenance.Basename
