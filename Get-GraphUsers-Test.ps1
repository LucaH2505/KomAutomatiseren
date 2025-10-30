Write-Output "Starting test run..."

# Simulate loading config
$CsvOutput = ".\GraphUsers_Test.csv"

Write-Output "Config loaded (simulated):"
Write-Output "  TenantId     = 00000000-0000-0000-0000-000000000000"
Write-Output "  ClientId     = 11111111-1111-1111-1111-111111111111"
Write-Output "  ClientSecret = [hidden]"
Write-Output "  CsvOutput    = $CsvOutput"

# Mock Functions

function Get-GraphToken {
    Write-Output "Simulating token fetch..."
    return "FAKE_TOKEN_12345"
}

function Get-AllUsers {
    param(
        [string]$Url = "https://graph.microsoft.com/v1.0/users"
    )

    Write-Output "Simulating Graph API user fetch..."
    
    # Mock fake user data
    $fakeUsers = @(
        @{ displayName="John Doe";  userPrincipalName="john.doe@contoso.com";  mail="john.doe@contoso.com";  id="1111-aaaa" },
        @{ displayName="Jane Smith";userPrincipalName="jane.smith@contoso.com";mail="jane.smith@contoso.com";id="2222-bbbb" },
        @{ displayName="Tom Brown"; userPrincipalName="tom.brown@contoso.com"; mail="tom.brown@contoso.com"; id="3333-cccc" },
        @{ displayName="Alice Blue";userPrincipalName="alice.blue@contoso.com";mail="alice.blue@contoso.com";id="4444-dddd" }
    )

    return $fakeUsers
}

# Simulated main logic
try {
    Write-Output "Fetching users..."
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

Write-Output "Test run complete, fake Graph user data exported"