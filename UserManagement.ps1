# importeer Active Directory module
Import-Module ActiveDirectory

# pad naar het CSV bestand en log bestand
$CsvPath   = ".\Users.csv"
$LogPath   = ".\UserCreation.log"

# logging functie
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp [$Level] $Message"
    Add-Content -Path $LogPath -Value $LogMessage
    Write-Output $LogMessage
}

# start log
Write-Log "script gestart"

# controleer of CSV bestaat
if (-not (Test-Path $CsvPath)) {
    Write-Log "CSV bestand niet gevonden: $CsvPath" "ERROR"
    exit
}

# importeer de CSV
$Users = Import-Csv -Path $CsvPath

foreach ($User in $Users) {
    try {
        $DisplayName = "$($User.Voornaam) $($User.Achternaam)"
        $SamAccount  = $User.Email       # school email wordt login naam
        $Email       = $User.Email
        $StudentID   = $User.StudentID   # opgeslaged als employee id

        # controleer of de gebruiker al bestaat
        if (Get-ADUser -Filter {SamAccountName -eq $SamAccount} -ErrorAction SilentlyContinue) {
            Write-Log "gebruiker $DisplayName ($SamAccount) bestaat al, deze gebruiker wordt overgeslagen" "WARNING"
            continue
        }

        # maak de gebruiker aan in active directory
        New-ADUser `
            -Name $DisplayName `
            -GivenName $User.Voornaam `
            -Surname $User.Achternaam `
            -SamAccountName $SamAccount `
            -UserPrincipalName $Email `
            -EmailAddress $Email `
            -EmployeeID $StudentID `
            -AccountPassword (ConvertTo-SecureString $User.Wachtwoord -AsPlainText -Force) `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        Write-Log "gebruiker succesvol aangemaakt : $DisplayName ($SamAccount)"
    }
    catch {
        Write-Log "fout bij gebruiker $DisplayName : $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "script gestopt"
