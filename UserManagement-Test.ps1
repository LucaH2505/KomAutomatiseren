# Test paths
$CsvPath = ".\Users_Test.csv"
$LogPath = ".\UserCreation_Test.log"

# Logging function
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

# Create fake CSV if it doesn't exist
if (-not (Test-Path $CsvPath)) {
@"
Voornaam,Achternaam,Name,Email,StudentID,Wachtwoord
John,Doe,john.doe,john.doe@contoso.com,1001,P@ssword1
Jane,Smith,jane.smith,jane.smith@contoso.com,1002,P@ssword2
Tom,Brown,tom.brown,tom.brown@contoso.com,1003,P@ssword3
"@ | Out-File -FilePath $CsvPath -Encoding UTF8
    Write-Output "Created fake CSV $CsvPath for testing"
}

# Start log
Write-Log "test script started"

# Import CSV
$Users = Import-Csv -Path $CsvPath

foreach ($User in $Users) {
    try {
        $DisplayName = "$($User.Voornaam) $($User.Achternaam)"
        $SamAccount  = $User.Name
        $Email       = $User.Email
        $StudentID   = $User.StudentID

        # Simulate AD check
        $exists = $false
        if ($exists) {
            Write-Log "User $DisplayName ($SamAccount) already exists, skipping user" "WARNING"
            continue
        }

        # Simulate creating the user
        Write-Log "Successfully created user: $DisplayName ($SamAccount)"
    }
    catch {
        Write-Log "Error for user $DisplayName : $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "test script stopped"
