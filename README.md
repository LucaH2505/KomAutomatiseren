# PowerShell Automation Scripts

De repository bestaat uit PowerShell scripts die gemaakt zijn voor gebruikersbeheer en rapportages in Active Directory en Microsoft 365 (gebruik van Graph API). De scripts zijn opgebouwd en kunnen dus in productie en in tests gebruikt worden.

---

## Scripts Overzicht

### 1. **Get-GraphUsers.ps1**

* Haalt alle gebruikers op uit Microsoft 365 via de Graph API
* Ondersteunt paginatie en exporteert resultaten naar CSV en JSON
* Configuratie via `config.json` (TenantId, ClientId, ClientSecret en een outputpad)

### 2. **Generate-Reports.ps1**

* Maakt rapportages van gebruikers:

  * Gebruikers zonder MFA
  * Gedeactiveerde of inactieve accounts (90+ dagen)
* Resultaten worden automatisch geëxporteerd naar CSV en JSON bestanden.
* Vereist Graph API toegang en permissie.
* Voor testdoeleinden kan een **offline testversie** gebruikt worden met nepdata.

### 3. **UserManagement.ps1**

* Importeert een CSV van nieuwe gebruikers en maakt ze aan in Active Directory.
* Controleert of gebruikers al bestaan en logt acties.
* Logbestand (`UserCreation.log`) houdt alle acties en fouten bij.
* Offline testversie beschikbaar zonder AD-toegang.

### 4. **Update-UserProperties.ps1**

* Past eigenschappen van bestaande Microsoft 365-gebruikers aan (bijv. afdeling, telefoonnummer).
* Voert bulk updates uit op basis van een CSV-bestand.
* Iedere wijziging wordt gelogd in een auditbestand.
* Vereist Graph API toegang.
* Offline testversie beschikbaar met nepdata voor veilige tests.

---

## Configuratie

### config.json (voor Graph scripts)

```json
{
  "TenantId": "xxx-xxx-xxx",
  "ClientId": "xxx-xxx-xxx",
  "ClientSecret": "xxx-xxx-xxx",
  "CsvOutputPath": ".\\GraphUsers.csv",
  "InputCsvPath": ".\\UserUpdates.csv",
  "AuditLogPath": ".\\AuditLog.txt"
}
```

* Graph scripts gebruiken deze gegevens voor authenticatie en paden.
* AD scripts gebruiken hardcoded paden en Windows-credentials, **geen config.json nodig**.

---

## Testen

* Voor elk script is er een **offline testversie** met nepdata.
* Testversies loggen acties naar aparte logbestanden (`*_Test.log`) en maken fake CSV-bestanden aan indien nodig.
* Zo kun je de workflow en logging testen zonder echte gebruikers aan te passen.

---

## Logging

* Alle scripts gebruiken een `Write-Log` functie.
* Logs bevatten timestamps, niveau (INFO/WARNING/ERROR) en een duidelijke beschrijving van acties of fouten.
* Voor auditdoeleinden worden wijzigingen en fouten altijd weggeschreven naar een logbestand.

---

## Gebruik

1. Plaats de scripts en bijbehorende CSV/config bestanden in dezelfde map.
2. Pas `config.json` aan voor Graph scripts.
3. Start het script via PowerShell:

```powershell
. .\Generate-Reports.ps1
```

4. Bekijk de logbestanden voor details van de uitgevoerde acties.
