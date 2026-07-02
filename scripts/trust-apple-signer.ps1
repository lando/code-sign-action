<#
.SYNOPSIS
Trusts an Apple signing certificate as a Windows test anchor.

.DESCRIPTION
This script imports a base64-encoded Apple signing PFX, exports the public
signing certificate, and imports that public certificate into Windows trust
stores. It is intended for GitHub Actions smoke tests that need signtool verify
to accept a shared Apple Developer ID certificate on Windows.

The script intentionally trusts the leaf signing certificate directly. That
keeps signtool verification enabled while avoiding the Apple Developer ID
intermediate chain that Windows cannot validate because of Apple's critical
extension.

Environment Variables:
APPLE_CERT_DATA        Base64-encoded PFX data. Used when -CertificateData is omitted.
APPLE_CERT_PASSWORD    PFX password. Used when -CertificatePassword is omitted.
CODE_SIGN_ACTION_DEBUG Enables debug output when set.
RUNNER_DEBUG           Enables debug output in GitHub Actions when set.

.EXAMPLE
.\scripts\trust-apple-signer.ps1 -CertificateData $env:APPLE_CERT_DATA -CertificatePassword $env:APPLE_CERT_PASSWORD

.EXAMPLE
.\scripts\trust-apple-signer.ps1 -ExpectedSubject "*466VYKC9T5*" -Debug
#>
param(
  # Base64-encoded Apple signing PFX data.
  [string]$CertificateData = $env:APPLE_CERT_DATA,
  # Password for the Apple signing PFX.
  [string]$CertificatePassword = $env:APPLE_CERT_PASSWORD,
  # Subject pattern used to select the expected signer from the imported PFX.
  [string]$ExpectedSubject = "*",
  # Certificate stores that should directly trust the signer certificate.
  [string[]]$Stores = @(
    "Cert:\LocalMachine\TrustedPeople",
    "Cert:\LocalMachine\TrustedPublisher",
    "Cert:\LocalMachine\Root"
  ),
  # Directory for temporary PFX and CER files.
  [string]$TempDir = $env:TEMP,
  # Leaves temporary files in place for runner debugging.
  [switch]$KeepTempFiles,
  # Shows debug messages.
  [switch]$Debug,
  # Displays this help message.
  [switch]$Help
)

Set-StrictMode -Version 3
$ErrorActionPreference = "Stop"

function Test-Truthy {
  param([AllowNull()][object]$Value)

  $normalized = ""
  if (-not [string]::IsNullOrWhiteSpace([string]$Value)) {
    $normalized = ([string]$Value).Trim().ToLowerInvariant()
  }

  switch ($normalized) {
    "" { return $false }
    "0" { return $false }
    "false" { return $false }
    "no" { return $false }
    "off" { return $false }
    default { return $true }
  }
}

$Debug = $Debug.IsPresent -or (Test-Truthy $env:RUNNER_DEBUG) -or (Test-Truthy $env:CODE_SIGN_ACTION_DEBUG)
$DebugPreference = if ($Debug) { "Continue" } else { $DebugPreference }
if ($DebugPreference -eq "Inquire" -or $DebugPreference -eq "Continue") {
  $Debug = $true
}

try {
  $Host.PrivateData.DebugForegroundColor = "DarkGray"
  $Host.PrivateData.DebugBackgroundColor = $Host.UI.RawUI.BackgroundColor
} catch {
}

if ($Help) {
  Get-Help $MyInvocation.MyCommand.Path -Detailed
  return
}

function Confirm-Value {
  param(
    [Parameter(Mandatory)]
    [AllowNull()]
    [string]$Value,
    [Parameter(Mandatory)]
    [string]$Name
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    throw "$Name is required."
  }
}

function Confirm-Environment {
  Write-Debug "OS is $env:OS"
  if ($env:OS -ne "Windows_NT") {
    throw "This script is only supported on Windows."
  }

  Write-Debug "PowerShell version: $($PSVersionTable.PSVersion.ToString())"
  Write-Debug "Expected subject: $ExpectedSubject"
  Write-Debug "Trust stores: $($Stores -join ', ')"
}

function Import-SignerCertificate {
  param(
    [Parameter(Mandatory)]
    [string]$PfxPath,
    [Parameter(Mandatory)]
    [securestring]$Password
  )

  Write-Host "Importing Apple signing certificate from APPLE_CERT_DATA..."
  Import-PfxCertificate -FilePath $PfxPath -Password $Password -CertStoreLocation "Cert:\LocalMachine\My" | Out-Null

  $signer = Get-ChildItem "Cert:\LocalMachine\My" |
    Where-Object { $_.HasPrivateKey -and $_.Subject -like $ExpectedSubject } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

  if ($null -eq $signer) {
    throw "Could not find a private-key certificate matching '$ExpectedSubject' in Cert:\LocalMachine\My."
  }

  Write-Host "Using signer certificate $($signer.Thumbprint): $($signer.Subject)"
  Write-Debug "Signer issuer: $($signer.Issuer)"
  Write-Debug "Signer expires: $($signer.NotAfter)"

  return $signer
}

function Add-SignerToTrustStores {
  param(
    [Parameter(Mandatory)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$Signer,
    [Parameter(Mandatory)]
    [string]$CertPath
  )

  Export-Certificate -Cert $Signer -FilePath $CertPath | Out-Null
  Write-Debug "Exported public signer certificate to $CertPath"

  foreach ($store in $Stores) {
    Import-Certificate -FilePath $CertPath -CertStoreLocation $store | Out-Null

    $trusted = Get-ChildItem $store |
      Where-Object { $_.Thumbprint -eq $Signer.Thumbprint } |
      Select-Object -First 1

    if ($null -eq $trusted) {
      throw "Signer certificate $($Signer.Thumbprint) was not found in $store after import."
    }

    Write-Host "Trusted signer certificate in ${store}: $($trusted.Thumbprint)"
  }
}

Confirm-Value -Value $CertificateData -Name "CertificateData"
Confirm-Value -Value $CertificatePassword -Name "CertificatePassword"
Confirm-Value -Value $TempDir -Name "TempDir"
Confirm-Environment

$pfxPath = Join-Path $TempDir "apple-signer.p12"
$certPath = Join-Path $TempDir "apple-signer.cer"
$password = ConvertTo-SecureString $CertificatePassword -AsPlainText -Force

try {
  Write-Debug "Writing temporary PFX to $pfxPath"
  [IO.File]::WriteAllBytes($pfxPath, [Convert]::FromBase64String($CertificateData))

  $signer = Import-SignerCertificate -PfxPath $pfxPath -Password $password
  Add-SignerToTrustStores -Signer $signer -CertPath $certPath
} finally {
  if ($KeepTempFiles) {
    Write-Debug "Keeping temporary certificate files in $TempDir"
  } else {
    Remove-Item -Path $pfxPath, $certPath -Force -ErrorAction SilentlyContinue
  }
}
