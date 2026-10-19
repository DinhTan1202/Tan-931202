# Cài một lần môi trường REA cho Claude Code trên Windows x64.
# Chạy trong PowerShell từ thư mục repo:
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
  throw 'Cần winget (App Installer từ Microsoft Store).'
}

# Node.js >= 22.19
Step 'Node.js'
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node -or [version](node -p 'process.versions.node') -lt [version]'22.19.0') {
  Winget-Install 'OpenJS.NodeJS.LTS'
}
node --version

# JDK 21 (Ghidra 12.1 cần JDK 21+)
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
  if ($hash -ne $GhidraSha256) { throw "Sai SHA-256 của Ghidra: $hash" }
  Expand-Archive $zip -DestinationPath $ToolsDir -Force
  Remove-Item $zip
}
[Environment]::SetEnvironmentVariable('GHIDRA_INSTALL_DIR', $GhidraDir, 'User')
$env:GHIDRA_INSTALL_DIR = $GhidraDir

# UPX và asar
Step 'UPX'
if (-not (Get-Command upx -ErrorAction SilentlyContinue)) { Winget-Install 'UPX.UPX' }
Step '@electron/asar'
if (-not (Get-Command asar -ErrorAction SilentlyContinue)) { npm install -g @electron/asar }

# Đăng ký REA cho repo này (scope local ghi đè .mcp.json; Windows cần cmd /c cho npx)
Step 'Đăng ký REA với Claude Code'
if (Get-Command claude -ErrorAction SilentlyContinue) {
  Remove-Item Env:CLAUDE_CONFIG_DIR -ErrorAction SilentlyContinue
  claude mcp remove --scope local rea 2>$null
  claude mcp add --scope local rea `
    -e "GHIDRA_INSTALL_DIR=$GhidraDir" -e "JAVA_HOME=$($jdk.FullName)" `
    -- cmd.exe /d /c npx -y "rea-agents@$ReaVersion" mcp
} else {
  Write-Warning 'Chưa có lệnh claude. Cài Claude Code rồi chạy lại script này.'
}

Step 'Kiểm tra'
npx -y "rea-agents@$ReaVersion" doctor --provider ghidra --json
Write-Host 'Xong. Mở lại terminal rồi chạy "claude" trong thư mục repo.' -ForegroundColor Green
