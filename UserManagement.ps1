# Import Active Directory module
Import-Module ActiveDirectory

# Path to csv file and log file
$CsvPath   = ".\Users.csv"
$LogPath   = ".\UserCreation.log"

# Logging
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

# Start log
Write-Log "script started"

# Check if the CSV exists
if (-not (Test-Path $CsvPath)) {
    Write-Log "CSV file not found: $CsvPath" "ERROR"
    exit
}

# Import the CSV
$Users = Import-Csv -Path $CsvPath

foreach ($User in $Users) {
    try {
        $DisplayName = "$($User.Voornaam) $($User.Achternaam)"
        $SamAccount  = $User.Name       # Login name
        $Email       = $User.Email
        $StudentID   = $User.StudentID   # Saved as employee ID

        # Check if the user already exists
        if (Get-ADUser -Filter {SamAccountName -eq $SamAccount} -ErrorAction SilentlyContinue) {
            Write-Log "User $DisplayName ($SamAccount) already exists, skipping user" "WARNING"
            continue
        }

        # Create the user in Active Directory
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

        Write-Log "successfully created the user : $DisplayName ($SamAccount)"
    }
    catch {
        Write-Log "error for user $DisplayName : $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "stopped script"
