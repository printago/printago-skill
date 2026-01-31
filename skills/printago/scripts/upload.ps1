<#
.SYNOPSIS
    Upload a file to Printago storage

.DESCRIPTION
    Uploads a file to Printago storage and returns the path for use in Part creation.
    Credentials are loaded from environment variables or Windows Credential Manager.

.PARAMETER File
    Path to the file to upload

.EXAMPLE
    ./upload.ps1 model.stl
    # Returns: uploads/abc123/model.stl

.EXAMPLE
    $path = ./upload.ps1 model.stl
    ./api.ps1 POST /v1/parts "{`"name`":`"My Model`",`"type`":`"stl`",`"fileUris`":[`"$path`"],...}"

.NOTES
    Environment variables:
      PRINTAGO_API_URL   Base URL (default: https://api.printago.io)
      PRINTAGO_API_KEY    API key (or use credential manager)
      PRINTAGO_STORE_ID   Store ID (or use credential manager)

    Run ./api.ps1 --help for credential setup instructions.
#>

param(
    [Parameter(Position=0)]
    [string]$File
)

# Function to get credential from Windows Credential Manager
function Get-PrintagoCredential {
    param([string]$Name)

    try {
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

function Get-Credentials {
    if ($env:PRINTAGO_API_KEY -and $env:PRINTAGO_STORE_ID) {
        return @{
            ApiKey = $env:PRINTAGO_API_KEY
            StoreId = $env:PRINTAGO_STORE_ID
        }
    }

    $apiKey = Get-PrintagoCredential -Name "apiKey"
    $storeId = Get-PrintagoCredential -Name "storeId"

    if ($apiKey -and $storeId) {
        return @{
            ApiKey = $apiKey
            StoreId = $storeId
        }
    }

    return $null
}

# Help
if (-not $File -or $File -eq "--help" -or $File -eq "-h") {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# Validate file
if (-not (Test-Path $File)) {
    Write-Error "Error: File not found: $File"
    exit 1
}

# Get credentials
$creds = Get-Credentials
if (-not $creds) {
    Write-Error "Error: No credentials found"
    Write-Host "Run ./api.ps1 --help for setup instructions"
    exit 1
}

$filename = Split-Path $File -Leaf
$apiUrl = if ($env:PRINTAGO_API_URL) { $env:PRINTAGO_API_URL } else { "https://api.printago.io" }

$headers = @{
    "Authorization" = "ApiKey $($creds.ApiKey)"
    "X-Printago-StoreId" = $creds.StoreId
    "Content-Type" = "application/json"
}

# Step 1: Get signed upload URL
try {
    $body = @{ filenames = @($filename) } | ConvertTo-Json
    $signedResponse = Invoke-RestMethod -Uri "$apiUrl/v1/storage/signed-upload-urls" `
        -Method POST -Headers $headers -Body $body
} catch {
    Write-Error "Error: Failed to get signed URL"
    Write-Error $_.Exception.Message
    exit 1
}

$uploadUrl = $signedResponse.signedUrls[0].uploadUrl
$filePath = $signedResponse.signedUrls[0].path

if (-not $uploadUrl) {
    Write-Error "Error: Failed to get signed URL"
    $signedResponse | ConvertTo-Json -Depth 5 | Write-Error
    exit 1
}

# Step 2: Upload file
try {
    $fileBytes = [System.IO.File]::ReadAllBytes((Resolve-Path $File))
    $uploadHeaders = @{ "Content-Type" = "application/octet-stream" }
    Invoke-RestMethod -Uri $uploadUrl -Method PUT -Headers $uploadHeaders -Body $fileBytes | Out-Null
} catch {
    Write-Error "Error: Upload failed"
    Write-Error $_.Exception.Message
    exit 1
}

# Output just the path
Write-Output $filePath
