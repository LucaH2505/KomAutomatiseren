Write-Output "Starting test run"

# Mock data

# Fake user registration / MFA info
$mfaData = @(
    @{ userDisplayName="John Doe";   userPrincipalName="john.doe@contoso.com";   isMfaRegistered=$false },
    @{ userDisplayName="Jane Smith"; userPrincipalName="jane.smith@contoso.com"; isMfaRegistered=$true  },
    @{ userDisplayName="Tom Brown";  userPrincipalName="tom.brown@contoso.com";  isMfaRegistered=$false }
)

# Fake user accounts with sign in info
$users = @(
    @{ displayName="John Doe";   userPrincipalName="john.doe@contoso.com";   accountEnabled=$true;  signInActivity=@{ lastSignInDateTime="2024-04-10T00:00:00Z" } },
    @{ displayName="Jane Smith"; userPrincipalName="jane.smith@contoso.com"; accountEnabled=$false; signInActivity=@{ lastSignInDateTime="2024-09-01T00:00:00Z" } },
    @{ displayName="Tom Brown";  userPrincipalName="tom.brown@contoso.com";  accountEnabled=$true;  signInActivity=@{ lastSignInDateTime="2025-09-20T00:00:00Z" } },
    @{ displayName="Alice Blue"; userPrincipalName="alice.blue@contoso.com"; accountEnabled=$true;  signInActivity=@{ lastSignInDateTime=$null } }
)

# Report 1 - Users without MFA
Write-Output "Fetching users without MFA..."
$usersWithoutMFA = $mfaData | Where-Object { -not $_.isMfaRegistered }

if ($usersWithoutMFA.Count -gt 0) {
    $usersWithoutMFA |
        Select-Object userDisplayName, userPrincipalName, isMfaRegistered |
        Export-Csv -Path ".\UsersWithoutMFA.csv" -NoTypeInformation -Encoding UTF8

    $usersWithoutMFA |
        ConvertTo-Json -Depth 4 |
        Out-File ".\UsersWithoutMFA.json" -Encoding UTF8

    Write-Output "Report 'UsersWithoutMFA' saved (CSV & JSON)"
} else {
    Write-Output "No users without MFA found"
}

# Report 2 - Deactivated or inactive accounts
Write-Output "Fetching deactivated or inactive users..."
$thresholdDate = (Get-Date).AddDays(-90)

$inactiveUsers = $users | Where-Object {
    ($_."accountEnabled" -eq $false) -or
    (
        $_.signInActivity.lastSignInDateTime -and
        ([datetime]$_.signInActivity.lastSignInDateTime -lt $thresholdDate)
    )
}

if ($inactiveUsers.Count -gt 0) {
    $inactiveUsers |
        Select-Object displayName, userPrincipalName, accountEnabled,
            @{n='lastSignInDateTime';e={$_.signInActivity.lastSignInDateTime}} |
        Export-Csv -Path ".\InactiveOrDisabledUsers.csv" -NoTypeInformation -Encoding UTF8

    $inactiveUsers |
        ConvertTo-Json -Depth 4 |
        Out-File ".\InactiveOrDisabledUsers.json" -Encoding UTF8

    Write-Output "Report 'InactiveOrDisabledUsers' saved (CSV & JSON)"
} else {
    Write-Output "No deactivated or inactive accounts found"
}

Write-Output "Test run complete, fake reports generated in the current directory"