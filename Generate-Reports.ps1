# path to config.json
$cfgPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config.json"

if (-not (Test-Path $cfgPath)) {
    Write-Error "config.json not found. Add TenantId, ClientId and ClientSecret."
    exit 1
}

# load the config
$config = Get-Content -Path $cfgPath -Raw | ConvertFrom-Json
$TenantId     = $config.TenantId
$ClientId     = $config.ClientId
$ClientSecret = $config.ClientSecret

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

# call graph API with pagination
function Get-GraphData {
    param(
        [string]$Url
    )
    $token = Get-GraphToken
    $headers = @{ Authorization = "Bearer $token" }
    $allData = @()

    while ($Url) {
        $resp = Invoke-RestMethod -Uri $Url -Headers $headers -Method Get
        $allData += $resp.value
        $Url = $resp.'@odata.nextLink'
    }

    return $allData
}

# Report 1 - users without MFA ===
Write-Output "==> Fetching users without MFA..."
$mfaUrl = "https://graph.microsoft.com/v1.0/reports/credentialUserRegistrationDetails"
$mfaData = Get-GraphData -Url $mfaUrl

$usersWithoutMFA = $mfaData | Where-Object { -not $_.isMfaRegistered }

if ($usersWithoutMFA.Count -gt 0) {
    $usersWithoutMFA | Select-Object userDisplayName, userPrincipalName, isMfaRegistered |
        Export-Csv -Path ".\UsersWithoutMFA.csv" -NoTypeInformation -Encoding UTF8
    $usersWithoutMFA | ConvertTo-Json -Depth 4 | Out-File ".\UsersWithoutMFA.json" -Encoding UTF8
    Write-Output "Report 'UsersWithoutMFA' saved (CSV & JSON)"
} else {
    Write-Output "No users without MFA found"
}

# report 2 - deactivated or inactive accounts
Write-Output "==> fetching deactivated or inactive users..."
$inactiveUrl = "https://graph.microsoft.com/v1.0/users?`$select=displayName,userPrincipalName,accountEnabled,signInActivity"

$users = Get-GraphData -Url $inactiveUrl

# Filter accounts that are deactivated or inactive for 90+ days
$thresholdDate = (Get-Date).AddDays(-90)
$inactiveUsers = $users | Where-Object {
    ($_."accountEnabled" -eq $false) -or
    ([datetime]$_.signInActivity.lastSignInDateTime -lt $thresholdDate)
}

if ($inactiveUsers.Count -gt 0) {
    $inactiveUsers | Select-Object displayName, userPrincipalName, accountEnabled, @{n='lastSignInDateTime';e={$_.signInActivity.lastSignInDateTime}} |
        Export-Csv -Path ".\InactiveOrDisabledUsers.csv" -NoTypeInformation -Encoding UTF8
    $inactiveUsers | ConvertTo-Json -Depth 4 | Out-File ".\InactiveOrDisabledUsers.json" -Encoding UTF8
    Write-Output "Report 'InactiveOrDisabledUsers' saved (CSV & JSON)"
} else {
    Write-Output "No deactivated or inactive accounts found"
}

Write-Output "Successfully generated reports"
