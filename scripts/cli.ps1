# vStats CLI Installer for Windows
# Usage: irm https://vstats.zsoft.cc/cli.ps1 | iex

$ErrorActionPreference = "Stop"

# Configuration
$GithubRepo = "zsai001/vstats-cli"
$BinaryName = "vstats.exe"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Get-Architecture {
    $arch = [System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE")
    switch ($arch) {
        "AMD64" { return "amd64" }
        "ARM64" { return "arm64" }
        default { 
            Write-ColorOutput "Error: Unsupported architecture: $arch" "Red"
            exit 1
        }
    }
}

function Get-LatestVersion {
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$GithubRepo/releases/latest" -Headers @{ "User-Agent" = "PowerShell" }
        return $response.tag_name
    } catch {
        Write-ColorOutput "Warning: Could not fetch latest version, using 'latest'" "Yellow"
        return "latest"
    }
}

function Get-InstallPath {
    $localAppData = [Environment]::GetFolderPath("LocalApplicationData")
    $installDir = Join-Path $localAppData "Programs\vstats"
    
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }
    
    return $installDir
}

function Add-ToPath {
    param([string]$Path)
    
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$Path*") {
        $newPath = "$currentPath;$Path"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        $env:PATH = "$env:PATH;$Path"
        Write-ColorOutput "Added $Path to user PATH" "Green"
    }
}

function Install-VStatsCLI {
    Write-Host ""
    Write-ColorOutput "╔═══════════════════════════════════════════╗" "Blue"
    Write-ColorOutput "║       vStats CLI Installer                ║" "Blue"
    Write-ColorOutput "╚═══════════════════════════════════════════╝" "Blue"
    Write-Host ""
    
    # Detect architecture
    $arch = Get-Architecture
    Write-ColorOutput "Detected architecture: windows-$arch" "Blue"
    
    # Get latest version
    $version = Get-LatestVersion
    Write-ColorOutput "Latest version: $version" "Blue"
    
    # Build download URL
    $downloadUrl = "https://github.com/$GithubRepo/releases/download/$version/vstats-cli-windows-$arch.exe"
    Write-ColorOutput "Downloading from: $downloadUrl" "Blue"
    
    # Get install path
    $installDir = Get-InstallPath
    $installPath = Join-Path $installDir $BinaryName
    
    # Download
    try {
        $tempFile = Join-Path $env:TEMP "vstats-download.exe"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -UseBasicParsing
        Move-Item -Path $tempFile -Destination $installPath -Force
        Write-ColorOutput "✓ Downloaded successfully" "Green"
    } catch {
        Write-ColorOutput "Error: Failed to download vstats CLI" "Red"
        Write-ColorOutput $_.Exception.Message "Red"
        exit 1
    }
    
    # Add to PATH
    Add-ToPath $installDir
    
    # Verify installation
    try {
        $versionOutput = & $installPath version 2>&1
        Write-ColorOutput "✓ Installation verified: $versionOutput" "Green"
    } catch {
        Write-ColorOutput "Warning: Could not verify installation" "Yellow"
    }
    
    # Print usage
    Write-Host ""
    Write-ColorOutput "vStats CLI has been installed!" "Green"
    Write-Host ""
    Write-Host "Quick Start:"
    Write-Host "  vstats login              # Login to vStats Cloud"
    Write-Host "  vstats server list        # List your servers"
    Write-Host "  vstats server create web1 # Create a new server"
    Write-Host "  vstats ssh agent root@srv # Deploy agent via SSH"
    Write-Host ""
    Write-Host "Documentation: https://vstats.zsoft.cc/docs/cli"
    Write-Host ""
    Write-ColorOutput "Note: You may need to restart your terminal for PATH changes to take effect." "Yellow"
}

# Run installer
Install-VStatsCLI

