# generate self-sigend certificate to terminate at the ALB
# run from PowerShell on Windows (ensure OpenSSL is installed and in PATH)
# If having problems running ps1 scripts, run the following command in PowerShell:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

$domain = "localhost.localhost.com"
$certDir = "certs"
$crtPath = "$certDir\$domain.crt"
$keyPath = "$certDir\$domain.key"

# Create certs directory if it doesn't exist
if (-Not (Test-Path $certDir)) {
    New-Item -ItemType Directory -Path $certDir | Out-Null
}

# Generate CRT and KEY using OpenSSL
openssl req -x509 -nodes -days 365 `
  -newkey rsa:2048 `
  -keyout $keyPath `
  -out $crtPath `
  -subj "/CN=$domain"

# Display output
if ((Test-Path $crtPath) -and (Test-Path $keyPath)) {
    Write-Host "Self-signed certificate and private key generated successfully."
    Write-Host "Certificate: $crtPath"
    Write-Host "Private Key: $keyPath"

    # Print expiration date
    $endDate = & openssl x509 -in $crtPath -noout -enddate
    Write-Host "Certificate expiration date: $($endDate -replace 'notAfter=', '')"

    # Print fingerprint
    $fingerprint = & openssl x509 -in $crtPath -noout -fingerprint -sha256
    Write-Host "Certificate fingerprint: $($fingerprint -replace 'SHA256 Fingerprint=', '')"
} else {
    Write-Error "Failed to generate certificate and private key."
    exit 1
}
