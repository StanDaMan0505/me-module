Function Start-ProTime
{
    # Damit [sendkeys] verwendet werden kann
    #[void] [System.Reflection.Assembly]::LoadWithPartialName("'System.Windows.Forms")
    #[void] [System.Reflection.Assembly]::LoadWithPartialName("'Microsoft.VisualBasic")

    # Credentials eingeben
    #$cred = Get-credential -Message "Passwort eingeben" -UserName "AXDST05"
    $loginUrl = 'http://sax81234.lnxsrv.abraxas.ch:8000/sap/bc/webdynpro/ppa/time_main?sap-client=100#'
    $proc = "iexplore.exe"

    # Prozess starten
    Start-Process -FilePath $proc -ArgumentList $loginUrl
    Start-Sleep -Seconds 2

    # Prozess finden
    $ie = (New-Object -ComObject Shell.Application).Windows() | Where-Object {$_.LocationUrl -eq $loginUrl}

    # Benutzername und Passwort eingeben
    #($ie.Document.IHTMLDocument3_getElementById("sap-user") | Select-Object -First 1).value = $cred.UserName
    #($ie.Document.IHTMLDocument3_getElementById("sap-password") | Select-Object -First 1).value = $cred.GetNetworkCredential().Password
    ($ie.Document.IHTMLDocument3_getElementById("sap-user") | Select-Object -First 1).value = "AXDST05"
    # Function Get-Base64String verwenden um Passwort zu verschlüsseln
    ($ie.Document.IHTMLDocument3_getElementById("sap-password") | Select-Object -First 1).value = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String("SgB1AHMAdAAxAGQAcwB0ACsA")) 

    # Anmelden
    ($ie.Document.IHTMLDocument3_getElementById("LOGON_BUTTON") | Select-Object -First 1).Click()

    # Warten bis Dokument geladen ist
    while($IE.busy) {Start-Sleep -Milliseconds 100} #Start-Sleep -Seconds 2

    # Drop Down von "Freier Eingabe" auf "Ab-/Anwesenheit" ändern
    #($ie.Document.IHTMLDocument3_getElementById("WD01C4-btn") | Select-Object -First 1).Click()
    #Start-Sleep -Milliseconds 500
    #[System.Windows.Forms.SendKeys]::Sendwait("Ab")
    #[System.Windows.Forms.SendKeys]::Sendwait("{ENTER}")
    #Start-Sleep -Milliseconds 500

    #$dt = Get-Date # Dienstag, 1. Januar 2019 07:17:16
    #$x = $dt.AddMinutes((-($dt.minute % 5))) # Dienstag, 1. Januar 2019 07:15:16
    #"$($x.Hour):$($x.Minute)" # 07:15 (Problem ist, es wird immer abgerundet.. 
    #                          # man müsste prüfen was näher ist und dann entweder auf oder abrunden

    # Uhrzeit von
    #($ie.Document.IHTMLDocument3_getElementById("WD0205") | Select-Object -First 1).value = (Get-Date -Format HH:mm)

    # Uhrzeit bis
    #($ie.Document.IHTMLDocument3_getElementById("WD0209") | Select-Object -First 1).value = "12:00"

}