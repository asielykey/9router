[CmdletBinding()]
param(
  [string]$ProjectRoot = (Join-Path $PSScriptRoot ".."),
  [string]$OutputRoot,
  [string]$PackageVersion,
  [string]$NodeExePath,
  [string]$InnoSetupCompilerPath,
  [int]$Port = 20128,
  [switch]$SkipInstaller,
  [switch]$SkipZip
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "[build-win-from-npm] $Message" -ForegroundColor Cyan
}

function Resolve-AbsolutePath {
  param([string]$PathValue)

  return (Resolve-Path -LiteralPath $PathValue).Path
}

function Ensure-Directory {
  param([string]$PathValue)

  if (-not (Test-Path -LiteralPath $PathValue)) {
    New-Item -ItemType Directory -Path $PathValue -Force | Out-Null
  }
}

function Reset-Directory {
  param([string]$PathValue)

  if (Test-Path -LiteralPath $PathValue) {
    Remove-Item -LiteralPath $PathValue -Recurse -Force
  }

  New-Item -ItemType Directory -Path $PathValue -Force | Out-Null
}

function Invoke-Checked {
  param(
    [string]$FilePath,
    [string[]]$Arguments,
    [string]$WorkingDirectory
  )

  Push-Location $WorkingDirectory
  try {
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "Lenh '$FilePath' that bai voi ma $LASTEXITCODE."
    }
  }
  finally {
    Pop-Location
  }
}

$resolvedProjectRoot = Resolve-AbsolutePath -PathValue $ProjectRoot
if (-not $OutputRoot) {
  $OutputRoot = Join-Path $resolvedProjectRoot "build\windows"
}

$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$packageJsonPath = Join-Path $resolvedProjectRoot "package.json"
$buildScriptPath = Join-Path $resolvedProjectRoot "scripts\build-win-installer.ps1"
$patchScriptPath = Join-Path $resolvedProjectRoot "scripts\patch-9router-runtime.js"

$packageJson = Get-Content -LiteralPath $packageJsonPath -Raw | ConvertFrom-Json
if (-not $PackageVersion) {
  $PackageVersion = [string]$packageJson.version
}

$runtimeWorkRoot = Join-Path $resolvedOutputRoot "npm-runtime"
$extractRoot = Join-Path $runtimeWorkRoot "extract"
$runtimeDir = Join-Path $extractRoot "package\app"
$betterSqliteVersion = [string]$packageJson.dependencies."better-sqlite3"
if (-not $betterSqliteVersion) {
  $betterSqliteVersion = "12.6.2"
}
$betterSqliteVersion = $betterSqliteVersion.TrimStart("^", "~")
$tarballName = "9router-$PackageVersion.tgz"

Write-Step "Dang tai runtime 9router@$PackageVersion tu npm..."
Reset-Directory -PathValue $runtimeWorkRoot
Invoke-Checked -FilePath "npm" -Arguments @("pack", "9router@$PackageVersion") -WorkingDirectory $runtimeWorkRoot

Write-Step "Dang giai nen package..."
Ensure-Directory -PathValue $extractRoot
Invoke-Checked -FilePath "tar" -Arguments @("-xf", (Join-Path $runtimeWorkRoot $tarballName), "-C", $extractRoot) -WorkingDirectory $runtimeWorkRoot

if (-not (Test-Path -LiteralPath $runtimeDir)) {
  throw "Khong tim thay runtime app sau khi giai nen npm package."
}

Write-Step "Dang sua better-sqlite3 cho Windows..."
Invoke-Checked -FilePath "npm" -Arguments @("install", "better-sqlite3@$betterSqliteVersion", "--no-save") -WorkingDirectory $runtimeDir

Write-Step "Dang kiem tra better-sqlite3..."
Invoke-Checked -FilePath "node" -Arguments @(
  "-e",
  "const Database=require('better-sqlite3'); const db=new Database(':memory:'); db.prepare('select 1 as x').get(); db.close();"
) -WorkingDirectory $runtimeDir

Write-Step "Dang va runtime bundle..."
Invoke-Checked -FilePath "node" -Arguments @($patchScriptPath, "--runtime-dir", $runtimeDir) -WorkingDirectory $resolvedProjectRoot

$builderArguments = @(
  "-NoProfile",
  "-ExecutionPolicy",
  "Bypass",
  "-File",
  $buildScriptPath,
  "-ProjectRoot",
  $resolvedProjectRoot,
  "-OutputRoot",
  $resolvedOutputRoot,
  "-RuntimeDir",
  $runtimeDir,
  "-Port",
  "$Port"
)

if ($NodeExePath) {
  $builderArguments += @("-NodeExePath", $NodeExePath)
}

if ($InnoSetupCompilerPath) {
  $builderArguments += @("-InnoSetupCompilerPath", $InnoSetupCompilerPath)
}

if ($SkipInstaller) {
  $builderArguments += "-SkipInstaller"
}

if ($SkipZip) {
  $builderArguments += "-SkipZip"
}

Write-Step "Dang dong goi Windows runtime..."
Invoke-Checked -FilePath "powershell" -Arguments $builderArguments -WorkingDirectory $resolvedProjectRoot
