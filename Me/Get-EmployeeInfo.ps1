Function Get-EmployeeInfo {
 
    <#
 .Synopsis
  Returns a customized list of Active Directory account information for a single user
 
 .Description
  Returns a customized list of Active Directory account information for a single user. The customized list is a combination of the fields that
  are most commonly needed to review when an employee calls the helpdesk for assistance.
 
 .Example
  Get-EmployeeInfo Michael_Kanakos
  Returns a customized list of AD account information fro Michael_Kanakos
 
  PS C:\Scripts> Get-EmployeeInfo Michael_Kanakos
 
    FirstName    : Michael
    LastName     : Kanakos
    Title        : Server Engineer
    Department   : Strategic Server Solutions
    Manager      : Christopher_Sharp
    City         : Cary
    EmployeeID   : 201278
    UserName     : Michael_Kanakos
    DisplayNme   : Kanakos, Michael
    EmailAddress : Michael_Kanakos@LORD.COM
    OfficePhone  : +1 919-342-4132
    MobilePhone  : +1 631-355-4580
 
    PasswordExpired       : False
    AccountLockedOut      : False
    LockOutTime           : 0
    AccountEnabled        : True
    AccountExpirationDate :
    PasswordLastSet       : 3/26/2018 9:29:02 AM
    PasswordExpireDate    : 9/28/2018 9:29:02 AM
 
 .Parameter UserName
  The employee account to lookup in Active Directory
 
  .Notes
  NAME: Get-EmployeeInfo
  AUTHOR: Mike Kanakos
  LASTEDIT: 2018-04-14
  .Link
    www.networkadmin.com
 
#>
 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$UserName
    )
 
 
    #Import AD Module
    Import-Module ActiveDirectory
 
    try{
        $Employee = Get-ADuser $UserName -Properties *, 'msDS-UserPasswordExpiryTimeComputed'
        $Manager = Get-ADUser $Employee.manager | Select-Object Name, SamAccountName
        $PasswordExpiry = [datetime]::FromFileTime($Employee.'msDS-UserPasswordExpiryTimeComputed')
 
          $AccountInfo = [PSCustomObject]@{
            FirstName    = $Employee.GivenName
            LastName     = $Employee.Surname
            Title        = $Employee.Title
            Department   = $Employee.department
            Manager      = $($Manager.Name + ' - ' + $Manager.SamAccountName )
            City         = $Employee.city
            EmployeeID   = $Employee.EmployeeID
            UserName     = $Employee.SamAccountName
            DisplayNme   = $Employee.displayname
            EmailAddress = $Employee.emailaddress
            OfficePhone  = $Employee.officephone
            MobilePhone  = $Employee.mobilephone
        }
 
        $AccountStatus = [PSCustomObject]@{
            PasswordExpired       = $Employee.PasswordExpired
            AccountLockedOut      = $Employee.LockedOut
            LockOutTime           = $Employee.AccountLockoutTime
            AccountEnabled        = $Employee.Enabled
            AccountExpirationDate = $Employee.AccountExpirationDate
            PasswordLastSet       = $Employee.PasswordLastSet
            PasswordExpireDate    = $PasswordExpiry
    }
    }catch
    {
        $AccountInfo = "Kein Benutzer mit $UserName gefunden"
    }
    Write-Host "================ [Account Info] ==================" #-NoNewline
    $AccountInfo
    Write-Host "================ [Account Status] ================" 
    $AccountStatus
 
} #END OF FUNCTION