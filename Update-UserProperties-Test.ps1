# Paths for test CSV and log
$InputCsv = ".\UserUpdates_Test.csv"
$AuditLog = ".\AuditLog_Test.txt"

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp [$Level] $Message"
    Add-Content -Path $AuditLog -Value $LogMessage
    Write-Output $LogMessage
}

# Mock token function
function Get-GraphToken {
    Write-Output "Simulating token fetch..."
    return "FAKE_TOKEN_123"
}

# Mock update function
function Update-UserProperty {
    param(
        [string]$UserId,
        [string]$Property,
        [string]$NewValue,
        [string]$Token
    )

    # Simulate update without an API call
    Write-Log "Updated $Property for $UserId to '$NewValue'"
}

# Create a fake CSV if it does not exist
if (-not (Test-Path $InputCsv)) {
@"
userId,property,newValue
john.doe@contoso.com,department,Finance
jane.smith@contoso.com,department,Marketing
tom.brown@contoso.com,mobilePhone,+32 488 00 11 22
"@ | Out-File -FilePath $InputCsv -Encoding UTF8
    Write-Output "Created fake $InputCsv for testing."
}

# Main test logic
$usersToUpdate = Import-Csv -Path $InputCsv
$token = Get-GraphToken

Write-Log "Starting test bulk user property update for $($usersToUpdate.Count) users"

foreach ($user in $usersToUpdate) {
    Update-UserProperty -UserId $user.userId -Property $user.property -NewValue $user.newValue -Token $token
}

Write-Log "Completed test bulk update"
