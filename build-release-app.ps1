param(
  [string]$DevEcoHome = "D:\application\other\huawei\DevEco Studio"
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path -LiteralPath $PSScriptRoot
$sdkHome = Join-Path $DevEcoHome "sdk"
$hvigor = Join-Path $DevEcoHome "tools\hvigor\bin\hvigorw.bat"
$appOutputDir = Join-Path $projectRoot "build\outputs\default"

if (-not (Test-Path -LiteralPath $sdkHome)) {
  throw "DevEco SDK directory was not found: $sdkHome"
}

if (-not (Test-Path -LiteralPath $hvigor)) {
  throw "hvigor wrapper was not found: $hvigor"
}

$env:DEVECO_SDK_HOME = $sdkHome

Push-Location -LiteralPath $projectRoot
try {
  & $hvigor --mode project -p product=default -p buildMode=release assembleApp --no-daemon

  if ($LASTEXITCODE -ne 0) {
    throw "Release APP build failed with exit code $LASTEXITCODE."
  }

  $signedApp = Get-ChildItem -LiteralPath $appOutputDir -Filter "*-signed.app" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if ($null -eq $signedApp) {
    throw "Build succeeded, but no signed APP was found in $appOutputDir."
  }

  Write-Host ""
  Write-Host "Release APP build succeeded."
  Write-Host "Upload this file:"
  Write-Host $signedApp.FullName
} finally {
  Pop-Location
}
