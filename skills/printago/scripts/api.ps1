<#
.SYNOPSIS
    Printago API wrapper - handles authentication automatically

.DESCRIPTION
    Makes authenticated requests to the Printago API.
    Credentials are loaded from environment variables or Windows Credential Manager.

.PARAMETER Method
    HTTP method: GET, POST, PATCH, PUT, DELETE

.PARAMETER Endpoint
    API endpoint path (e.g., /v1/parts)

.PARAMETER Body
    Optional JSON body for POST/PATCH/PUT requests

.EXAMPLE
    ./api.ps1 GET /v1/parts

.EXAMPLE
    ./api.ps1 GET "/v1/parts?limit=5"

.EXAMPLE
    ./api.ps1 POST /v1/parts '{"name":"Test","type":"stl",...}'

.NOTES
    Environment variables:
      PRINTAGO_API_URL   Base URL (default: https://api.printago.io)
      PRINTAGO_API_KEY    API key (or use credential manager)
      PRINTAGO_STORE_ID   Store ID (or use credential manager)

    Examples:
      $env:PRINTAGO_API_URL = "http://localhost:3001"   # Local dev
      $env:PRINTAGO_API_URL = "https://api.printago.io" # Production (default)

    To store credentials in Windows Credential Manager:
      cmdkey /generic:Printago_apiKey /user:apiKey /pass:your-api-key
      cmdkey /generic:Printago_storeId /user:storeId /pass:your-store-id
#>

param(
    [Parameter(Position=0)]
    [string]$Method,

    [Parameter(Position=1)]
    [string]$Endpoint,

    [Parameter(Position=2)]
    [string]$Body
)

# Function to get credential from Windows Credential Manager
function Get-PrintagoCredential {
    param([string]$Name)

    try {
        # Use .NET to access Windows Credential Manager
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class CredentialManager {
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool CredRead(string target, int type, int flags, out IntPtr credential);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool CredFree(IntPtr credential);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public int AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public static string GetCredential(string target) {
        IntPtr credPtr;
        if (CredRead(target, 1, 0, out credPtr)) {
            CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            string password = Marshal.PtrToStringUni(cred.CredentialBlob, cred.CredentialBlobSize / 2);
            CredFree(credPtr);
            return password;
        }
        return null;
    }
}
"@ -ErrorAction SilentlyContinue

        return [CredentialManager]::GetCredential("Printago_$Name")
    } catch {
        return $null
    }
}

# Function to get credentials from env vars or credential manager
function Get-Credentials {
    # Try environment variables first
    if ($env:PRINTAGO_API_KEY -and $env:PRINTAGO_STORE_ID) {
        return @{
            ApiKey = $env:PRINTAGO_API_KEY
            StoreId = $env:PRINTAGO_STORE_ID
            Source = "env"
        }
    }

    # Try Windows Credential Manager
    $apiKey = Get-PrintagoCredential -Name "apiKey"
    $storeId = Get-PrintagoCredential -Name "storeId"

    if ($apiKey -and $storeId) {
        return @{
            ApiKey = $apiKey
            StoreId = $storeId
            Source = "credential_manager"
        }
    }

    return $null
}

# Help
if (-not $Method -or $Method -eq "--help" -or $Method -eq "-h") {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    Write-Host ""
    Write-Host "To store credentials in Windows Credential Manager:"
    Write-Host "  cmdkey /generic:Printago_apiKey /user:apiKey /pass:your-api-key"
    Write-Host "  cmdkey /generic:Printago_storeId /user:storeId /pass:your-store-id"
    exit 0
}

# Validate arguments
if (-not $Endpoint) {
    Write-Error "Error: METHOD and ENDPOINT required"
    Write-Host "Usage: ./api.ps1 METHOD ENDPOINT [BODY]"
    Write-Host "Run with --help for examples"
    exit 1
}

# Get credentials
$creds = Get-Credentials
if (-not $creds) {
    Write-Error "Error: No credentials found"
    Write-Host ""
    Write-Host "Set credentials via environment variables:"
    Write-Host "  `$env:PRINTAGO_API_KEY = 'your-api-key'"
    Write-Host "  `$env:PRINTAGO_STORE_ID = 'your-store-id'"
    Write-Host ""
    Write-Host "Or store in Windows Credential Manager:"
    Write-Host "  cmdkey /generic:Printago_apiKey /user:apiKey /pass:your-api-key"
    Write-Host "  cmdkey /generic:Printago_storeId /user:storeId /pass:your-store-id"
    exit 1
}

# API base URL (default to production)
$apiUrl = if ($env:PRINTAGO_API_URL) { $env:PRINTAGO_API_URL } else { "https://api.printago.io" }

# Auto-inject hints=true for GET requests (provides next-action suggestions)
if ($Method -eq "GET") {
    if ($Endpoint.Contains("?")) {
        $Endpoint = "$Endpoint&hints=true"
    } else {
        $Endpoint = "$Endpoint`?hints=true"
    }
}

$headers = @{
    "Authorization" = "ApiKey $($creds.ApiKey)"
    "X-Printago-StoreId" = $creds.StoreId
    "Content-Type" = "application/json"
}

$uri = "$apiUrl$Endpoint"

$params = @{
    Method = $Method
    Uri = $uri
    Headers = $headers
}

if ($Body) {
    $params.Body = $Body
}

try {
    $response = Invoke-RestMethod @params
    $response | ConvertTo-Json -Depth 20
} catch {
    Write-Error $_.Exception.Message
    if ($_.ErrorDetails.Message) {
        $_.ErrorDetails.Message | ConvertFrom-Json | ConvertTo-Json -Depth 10
    }
    exit 1
}
