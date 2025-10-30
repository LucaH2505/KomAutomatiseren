# Load config
$cfgPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "config.json"

if (Test-Path $cfgPath) {
    $config = Get-Content -Path $cfgPath -Raw | ConvertFrom-Json
    $TenantId     = $config.TenantId
    $ClientId     = $config.ClientId
    $ClientSecret = $config.ClientSecret
    $CsvOutput    = if ($config.CsvOutputPath) { $config.CsvOutputPath } else { ".\GraphUsers.csv" }
} else {
    Write-Error "config.json not found. Add TenantId, ClientId and ClientSecret"
    exit 1
}

# Fetch the OAuth2 token
function Get-GraphToken {
    param()
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

# Fetch all users with pagination
function Get-AllUsers {
    param(
        [string]$Url = "https://graph.microsoft.com/v1.0/users`?\$select=displayName,userPrincipalName,id,mail"
    )

    $allUsers = @()
    $nextUrl = $Url
    $token = Get-GraphToken
    $headers = @{ Authorization = "Bearer $token" }

    while ($nextUrl) {
        try {
            $response = Invoke-RestMethod -Method Get -Uri $nextUrl -Headers $headers -ErrorAction Stop
            if ($response.value) {
                $allUsers += $response.value
            }
            $nextUrl = $response.'@odata.nextLink'
        } catch {
            Write-Warning "Error while fetching users: $($_.Exception.Message) — try again in 3s"
            Start-Sleep -Seconds 3
            $response = Invoke-RestMethod -Method Get -Uri $nextUrl -Headers $headers -ErrorAction Stop
            if ($response.value) { $allUsers += $response.value }
            $nextUrl = $response.'@odata.nextLink'
        }
    }

    return $allUsers
}

# This fetches and exports the users
try {
    Write-Output "Fetching users"
    $users = Get-AllUsers

    if ($users.Count -eq 0) {
        Write-Output "No users found"
    } else {
        $export = $users | Select-Object displayName, userPrincipalName, mail, id
        $export | Export-Csv -Path $CsvOutput -NoTypeInformation -Encoding UTF8
        Write-Output "Users ($($export.Count)) saved in $CsvOutput"
    }
} catch {
    Write-Error "Error while fetching/exporting: $($_.Exception.Message)"
}
