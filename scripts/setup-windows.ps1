# One-time REA environment setup for Claude Code on Windows x64.
# Run in PowerShell from the repository folder:
#   powershell -ExecutionPolicy Bypass -File scripts\setup-windows.ps1
$ErrorActionPreference = 'Stop'

$GhidraVersion = '12.1.4'
$GhidraZip = "ghidra_${GhidraVersion}_PUBLIC_20260921.zip"
$GhidraSha256 = 'ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db'
$ReaVersion = '6.7.0'
$ToolsDir = Join-Path $env:LOCALAPPDATA 'Programs\rea-tools'
$GhidraDir = Join-Path $ToolsDir "ghidra_${GhidraVersion}_PUBLIC"

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
              [Environment]::GetEnvironmentVariable('Path', 'User')
}
function Winget-Install($id) {
  winget install --id $id -e --silent --accept-source-agreements --accept-package-agreements
  Refresh-Path
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  throw 'winget is required (App Installer from the Microsoft Store).'
}

# Node.js >= 22.19
Step 'Node.js'
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node -or [version](node -p 'process.versions.node') -lt [version]'22.19.0') {
  Winget-Install 'OpenJS.NodeJS.LTS'
}
node --version

# JDK 21 (Ghidra 12.1 requires JDK 21+)
Step 'JDK 21'
$jdk = Get-ChildItem 'C:\Program Files\Microsoft' -Directory -Filter 'jdk-21*' -ErrorAction SilentlyContinue |
  Sort-Object Name -Descending | Select-Object -First 1
if (-not $jdk) {
  Winget-Install 'Microsoft.OpenJDK.21'
  $jdk = Get-ChildItem 'C:\Program Files\Microsoft' -Directory -Filter 'jdk-21*' |
    Sort-Object Name -Descending | Select-Object -First 1
}
[Environment]::SetEnvironmentVariable('JAVA_HOME', $jdk.FullName, 'User')
$env:JAVA_HOME = $jdk.FullName

# Ghidra
Step "Ghidra $GhidraVersion"
if (-not (Test-Path (Join-Path $GhidraDir 'support\analyzeHeadless.bat'))) {
  New-Item -ItemType Directory -Force $ToolsDir | Out-Null
  $zip = Join-Path $env:TEMP $GhidraZip
  Invoke-WebRequest -UseBasicParsing -OutFile $zip `
    "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GhidraVersion}_build/$GhidraZip"
  $hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
  if ($hash -ne $GhidraSha256) { throw "Ghidra SHA-256 mismatch: $hash" }
  Expand-Archive $zip -DestinationPath $ToolsDir -Force
  Remove-Item $zip
}
[Environment]::SetEnvironmentVariable('GHIDRA_INSTALL_DIR', $GhidraDir, 'User')
$env:GHIDRA_INSTALL_DIR = $GhidraDir

# UPX and asar
Step 'UPX'
if (-not (Get-Command upx -ErrorAction SilentlyContinue)) { Winget-Install 'UPX.UPX' }
Step '@electron/asar'
if (-not (Get-Command asar -ErrorAction SilentlyContinue)) { npm install -g @electron/asar }

# Register REA for this repo (local scope overrides .mcp.json; Windows needs cmd /c for npx)
Step 'Register REA with Claude Code'
if (Get-Command claude -ErrorAction SilentlyContinue) {
  Remove-Item Env:CLAUDE_CONFIG_DIR -ErrorAction SilentlyContinue
  try { cmd.exe /d /c "claude mcp remove --scope local rea >nul 2>&1" } catch { }
  claude mcp add --scope local rea `
    -e "GHIDRA_INSTALL_DIR=$GhidraDir" -e "JAVA_HOME=$($jdk.FullName)" `
    -- cmd.exe /d /c npx -y "rea-agents@$ReaVersion" mcp
} else {
  Write-Warning 'claude command not found. Install Claude Code, then run this script again.'
}

Step 'Check'
npx -y "rea-agents@$ReaVersion" doctor --provider ghidra --json
Write-Host 'Done (Xong). Reopen PowerShell, then run "claude" in the repo folder.' -ForegroundColor Green
