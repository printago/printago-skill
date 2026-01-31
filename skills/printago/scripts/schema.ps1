<#
.SYNOPSIS
    Fetch Printago API schemas (no auth required)

.DESCRIPTION
    Retrieves type or path schemas from the Printago API.

.PARAMETER Command
    Either "types" or "paths"

.PARAMETER Name
    Optional: specific type or path name

.EXAMPLE
    ./schema.ps1 types
    # List all available type names

.EXAMPLE
    ./schema.ps1 types Part
    # Get full schema for Part type

.EXAMPLE
    ./schema.ps1 types PrintJob
    # Get full schema for PrintJob type

.EXAMPLE
    ./schema.ps1 paths
    # List all API paths

.EXAMPLE
    ./schema.ps1 paths v1/parts
    # Get schema for /v1/parts endpoint

.EXAMPLE
    ./schema.ps1 paths v2/builds
    # Get schema for /v2/builds endpoint

.NOTES
    Environment variables:
      PRINTAGO_API_URL   Base URL (default: https://api.printago.io)
#>

param(
    [Parameter(Position=0)]
    [string]$Command,

    [Parameter(Position=1)]
    [string]$Name
)

# Help
if (-not $Command -or $Command -eq "--help" -or $Command -eq "-h") {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# Validate command
if ($Command -ne "types" -and $Command -ne "paths") {
    Write-Error "Error: Unknown command '$Command'. Use 'types' or 'paths'."
    exit 1
}

$apiUrl = if ($env:PRINTAGO_API_URL) { $env:PRINTAGO_API_URL } else { "https://api.printago.io" }
$uri = "$apiUrl/v1/hints/schema/$Command"
if ($Name) {
    $uri = "$uri/$Name"
}

try {
    $response = Invoke-RestMethod -Uri $uri -Method GET
    $response | ConvertTo-Json -Depth 20
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
