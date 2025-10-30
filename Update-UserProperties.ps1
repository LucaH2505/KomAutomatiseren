# Load config
$cfgPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config.json"

if (-not (Test-Path $cfgPath)) {
    Write-Error "config.json not found. Add TenantId, ClientId and ClientSecret."
    exit 1
}

$config = Get-Content -Path $cfgPath -Raw | ConvertFrom-Json
$TenantId     = $config.TenantId
$ClientId     = $config.ClientId
$ClientSecret = $config.ClientSecret
$InputCsv     = if ($config.InputCsvPath) { $config.InputCsvPath } else { ".\UserUpdates.csv" }
$AuditLog     = if ($config.AuditLogPath) { $config.AuditLogPath } else { ".\AuditLog.txt" }

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

# Fetch access token
function Get-GraphToken {
    $tokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $body = @{
        client_id     = $ClientId
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $ClientSecret
        grant_type    = "client_credentials"
    }

    try {
        $resp = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -Body $body -ErrorAction Stop
        return $resp.access_token
    } catch {
        Write-Error "Error while fetching token: $($_.Exception.Message)"
        exit 1
    }
}

# Update user property
function Update-UserProperty {
    param(
        [string]$UserId,
        [string]$Property,
        [string]$NewValue,
        [string]$Token
    )

    $url = "https://graph.microsoft.com/v1.0/users/$($UserId)"
    $headers = @{ Authorization = "Bearer $Token"; "Content-Type" = "application/json" }
    $body = @{ $Property = $NewValue } | ConvertTo-Json

    try {
        Invoke-RestMethod -Method Patch -Uri $url -Headers $headers -Body $body -ErrorAction Stop
        Write-Log "Updated $Property for $UserId to '$NewValue'"
    } catch {
        Write-Log "Failed to update $UserId : $($_.Exception.Message)" "ERROR"
    }
}

# Main script
if (-not (Test-Path $InputCsv)) {
    Write-Log "Input CSV not found: $InputCsv" "ERROR"
    exit 1
}

$usersToUpdate = Import-Csv -Path $InputCsv
$token = Get-GraphToken

Write-Log "Starting bulk user property update for $($usersToUpdate.Count) users"

foreach ($user in $usersToUpdate) {
    Update-UserProperty -UserId $user.userId -Property $user.property -NewValue $user.newValue -Token $token
}

Write-Log "Completed bulk update"
