[CmdletBinding()]
param(
  [string]$ProjectRoot = (Join-Path $PSScriptRoot ".."),
  [string]$OutputRoot,
  [string]$RuntimeDir,
  [string]$NodeExePath,
  [string]$InnoSetupCompilerPath,
  [int]$Port = 20128,
  [switch]$SkipBuild,
  [switch]$SkipInstaller,
  [switch]$SkipZip
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "[build-win-installer] $Message" -ForegroundColor Cyan
}

function Resolve-AbsolutePath {
  param([string]$PathValue)

  return (Resolve-Path -LiteralPath $PathValue).Path
}

function Ensure-PathExists {
  param(
    [string]$PathValue,
    [string]$Label
  )

  if (-not (Test-Path -LiteralPath $PathValue)) {
    throw "Khong tim thay $Label tai '$PathValue'."
  }
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

function New-ZipArchive {
  param(
    [string]$SourceDir,
    [string]$DestinationPath
  )

  $tarCommand = Get-Command tar -ErrorAction SilentlyContinue
  if ($tarCommand) {
    Write-Step "Dang nen portable bang tar.exe..."
    Push-Location $SourceDir
    try {
      & $tarCommand.Source -a -cf $DestinationPath .
      if ($LASTEXITCODE -ne 0) {
        throw "Lenh tar that bai voi ma $LASTEXITCODE."
      }

      return
    }
    finally {
      Pop-Location
    }
  }

  Write-Step "Dang nen portable bang Compress-Archive..."
  Compress-Archive -Path (Join-Path $SourceDir "*") -DestinationPath $DestinationPath -Force
}

function Copy-DirectoryContents {
  param(
    [string]$SourceDir,
    [string]$DestinationDir
  )

  Ensure-PathExists -PathValue $SourceDir -Label "thu muc nguon"
  Ensure-Directory -PathValue $DestinationDir

  Copy-Item -Path (Join-Path $SourceDir "*") -Destination $DestinationDir -Recurse -Force
}

function Get-InnoSetupCompiler {
  param([string]$PreferredPath)

  if ($PreferredPath) {
    $resolvedPreferred = Resolve-AbsolutePath -PathValue $PreferredPath
    Ensure-PathExists -PathValue $resolvedPreferred -Label "ISCC.exe"
    return $resolvedPreferred
  }

  $candidatePaths = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
  )

  foreach ($candidate in $candidatePaths) {
    if (Test-Path -LiteralPath $candidate) {
      return $candidate
    }
  }

  return $null
}

function Restore-EnvironmentValue {
  param(
    [string]$Name,
    [AllowNull()][string]$Value
  )

  if ($null -eq $Value) {
    Remove-Item -Path ("Env:{0}" -f $Name) -ErrorAction SilentlyContinue
    return
  }

  Set-Item -Path ("Env:{0}" -f $Name) -Value $Value
}

function Invoke-NextStandaloneBuild {
  param([string]$RootDir)

  $nextCliPath = Join-Path $RootDir "node_modules\next\dist\bin\next"
  if (-not (Test-Path -LiteralPath $nextCliPath)) {
    throw "Khong tim thay Next local trong '$nextCliPath'. Hay chay 'npm install' tai repo truoc khi build source."
  }

  $fakeHomeRoot = Join-Path $RootDir ".fakehome"
  $fakeAppData = Join-Path $fakeHomeRoot "AppData\Roaming"
  $fakeLocalAppData = Join-Path $fakeHomeRoot "AppData\Local"
  Ensure-Directory -PathValue $fakeHomeRoot
  Ensure-Directory -PathValue $fakeAppData
  Ensure-Directory -PathValue $fakeLocalAppData

  $previousHome = $env:HOME
  $previousUserProfile = $env:USERPROFILE
  $previousAppData = $env:APPDATA
  $previousLocalAppData = $env:LOCALAPPDATA
  $previousNodeEnv = $env:NODE_ENV
  $previousNextTelemetryDisabled = $env:NEXT_TELEMETRY_DISABLED

  Write-Step "Dang build Next standalone..."
  Push-Location $RootDir
  try {
    $env:HOME = $fakeHomeRoot
    $env:USERPROFILE = $fakeHomeRoot
    $env:APPDATA = $fakeAppData
    $env:LOCALAPPDATA = $fakeLocalAppData
    $env:NODE_ENV = "production"
    $env:NEXT_TELEMETRY_DISABLED = "1"
    & node $nextCliPath build --webpack
    if ($LASTEXITCODE -ne 0) {
      throw "Lenh build Next standalone that bai voi ma $LASTEXITCODE."
    }
  }
  finally {
    Restore-EnvironmentValue -Name "HOME" -Value $previousHome
    Restore-EnvironmentValue -Name "USERPROFILE" -Value $previousUserProfile
    Restore-EnvironmentValue -Name "APPDATA" -Value $previousAppData
    Restore-EnvironmentValue -Name "LOCALAPPDATA" -Value $previousLocalAppData
    Restore-EnvironmentValue -Name "NODE_ENV" -Value $previousNodeEnv
    Restore-EnvironmentValue -Name "NEXT_TELEMETRY_DISABLED" -Value $previousNextTelemetryDisabled
    Pop-Location
  }
}

$resolvedProjectRoot = Resolve-AbsolutePath -PathValue $ProjectRoot
if (-not $OutputRoot) {
  $OutputRoot = Join-Path $resolvedProjectRoot "build\windows"
}

$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$packageJsonPath = Join-Path $resolvedProjectRoot "package.json"
$installerScriptPath = Join-Path $resolvedProjectRoot "installer\windows\9router.iss"
$resolvedRuntimeDir = $null
$standaloneRoot = Join-Path $resolvedProjectRoot ".next\standalone"
$standaloneServerPath = Join-Path $standaloneRoot "server.js"
$staticRoot = Join-Path $resolvedProjectRoot ".next\static"
$publicRoot = Join-Path $resolvedProjectRoot "public"
$openSseRoot = Join-Path $resolvedProjectRoot "open-sse"
$srcRoot = Join-Path $resolvedProjectRoot "src"
$iconSourcePath = Join-Path $resolvedProjectRoot "src\app\favicon.ico"
$installerAssetsRoot = Join-Path $resolvedProjectRoot "installer\windows"
$stagingRoot = Join-Path $resolvedOutputRoot "staging"
$appRoot = Join-Path $stagingRoot "app"
$artifactsRoot = Join-Path $resolvedOutputRoot "artifacts"

Ensure-PathExists -PathValue $packageJsonPath -Label "package.json"
Ensure-PathExists -PathValue $installerScriptPath -Label "file Inno Setup"
Ensure-PathExists -PathValue $installerAssetsRoot -Label "thu muc installer"

$packageJson = Get-Content -LiteralPath $packageJsonPath -Raw | ConvertFrom-Json
$appVersion = [string]$packageJson.version
if (-not $appVersion) {
  throw "Khong doc duoc version tu package.json."
}

$zipOutputPath = Join-Path $artifactsRoot ("9router-portable-v{0}.zip" -f $appVersion)

if (-not $NodeExePath) {
  $nodeCommand = Get-Command node -ErrorAction Stop
  $NodeExePath = $nodeCommand.Source
}

$resolvedNodeExePath = Resolve-AbsolutePath -PathValue $NodeExePath
Ensure-PathExists -PathValue $resolvedNodeExePath -Label "node.exe"

if ($RuntimeDir) {
  $resolvedRuntimeDir = Resolve-AbsolutePath -PathValue $RuntimeDir
  Ensure-PathExists -PathValue $resolvedRuntimeDir -Label "runtime dir"
  Ensure-PathExists -PathValue (Join-Path $resolvedRuntimeDir "server.js") -Label "runtime server.js"
} elseif (-not $SkipBuild) {
  Invoke-NextStandaloneBuild -RootDir $resolvedProjectRoot
}

if (-not $resolvedRuntimeDir) {
  Ensure-PathExists -PathValue $standaloneServerPath -Label "server.js cua Next standalone"
  Ensure-PathExists -PathValue $staticRoot -Label ".next\\static"
  Ensure-PathExists -PathValue $publicRoot -Label "public"
  Ensure-PathExists -PathValue $openSseRoot -Label "open-sse"
  Ensure-PathExists -PathValue $srcRoot -Label "src"
}
Ensure-PathExists -PathValue $iconSourcePath -Label "favicon.ico"

Write-Step "Dang dung thu muc runtime Windows..."
Reset-Directory -PathValue $stagingRoot
Ensure-Directory -PathValue $appRoot
Ensure-Directory -PathValue $artifactsRoot

if ($resolvedRuntimeDir) {
  Copy-DirectoryContents -SourceDir $resolvedRuntimeDir -DestinationDir $appRoot
} else {
  Copy-DirectoryContents -SourceDir $standaloneRoot -DestinationDir $appRoot
  Copy-DirectoryContents -SourceDir $staticRoot -DestinationDir (Join-Path $appRoot ".next\static")
  Copy-DirectoryContents -SourceDir $publicRoot -DestinationDir (Join-Path $appRoot "public")
  Copy-DirectoryContents -SourceDir $openSseRoot -DestinationDir (Join-Path $appRoot "open-sse")
  Copy-DirectoryContents -SourceDir $srcRoot -DestinationDir (Join-Path $appRoot "src")
}

Copy-Item -LiteralPath $resolvedNodeExePath -Destination (Join-Path $appRoot "node.exe") -Force
Copy-Item -LiteralPath $iconSourcePath -Destination (Join-Path $stagingRoot "9router.ico") -Force
Copy-Item -LiteralPath (Join-Path $installerAssetsRoot "9router.cmd") -Destination (Join-Path $stagingRoot "9router.cmd") -Force
Copy-Item -LiteralPath (Join-Path $installerAssetsRoot "9router-background.vbs") -Destination (Join-Path $stagingRoot "9router-background.vbs") -Force
Copy-Item -LiteralPath (Join-Path $installerAssetsRoot "stop-9router.cmd") -Destination (Join-Path $stagingRoot "stop-9router.cmd") -Force

$manifest = [ordered]@{
  appName = "9Router"
  version = $appVersion
  port = $Port
  builtAt = (Get-Date).ToString("s")
  nodeExe = [System.IO.Path]::GetFileName($resolvedNodeExePath)
  nodeSource = $resolvedNodeExePath
  runtimeSource = if ($resolvedRuntimeDir) { $resolvedRuntimeDir } else { $standaloneRoot }
}

$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stagingRoot "build-manifest.json") -Encoding UTF8

if (-not $SkipInstaller) {
  $innoCompiler = Get-InnoSetupCompiler -PreferredPath $InnoSetupCompilerPath
  if (-not $innoCompiler) {
    throw "Khong tim thay ISCC.exe cua Inno Setup 6. Ban co the cai Inno Setup hoac chay voi -SkipInstaller de chi lay ban portable."
  }

  Write-Step "Dang build Setup.exe bang Inno Setup..."
  $installerArguments = @(
    "/DMyAppVersion=$appVersion",
    "/DMySourceDir=$stagingRoot",
    "/DMyOutputDir=$artifactsRoot",
    "/DMyDefaultPort=$Port",
    $installerScriptPath
  )

  & $innoCompiler @installerArguments
  if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup build that bai voi ma $LASTEXITCODE."
  }
}

if (-not $SkipZip) {
  Write-Step "Dang tao goi portable zip..."
  if (Test-Path -LiteralPath $zipOutputPath) {
    Remove-Item -LiteralPath $zipOutputPath -Force
  }

  New-ZipArchive -SourceDir $stagingRoot -DestinationPath $zipOutputPath
}

Write-Step "Hoan tat."
Write-Host "  Runtime staging: $stagingRoot"
Write-Host "  Artifacts: $artifactsRoot"
