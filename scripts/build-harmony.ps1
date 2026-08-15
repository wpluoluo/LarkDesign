[CmdletBinding()]
param(
    [ValidateSet('assembleHap', 'assembleApp', 'clean', 'ohpm-install')]
    [string]$Task = 'assembleHap',
    [string]$DevEcoHome = $env:DEVECO_HOME,
    [string]$SdkHome = $env:DEVECO_SDK_HOME
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($DevEcoHome)) {
    $DevEcoHome = 'C:\Program Files\Huawei\DevEco Studio'
}
if ([string]::IsNullOrWhiteSpace($SdkHome)) {
    $SdkHome = 'D:\DevEco Studio\sdk'
}

$hvigorHome = Join-Path $DevEcoHome 'tools\hvigor\hvigor'
$hvigorBin = Join-Path $DevEcoHome 'tools\hvigor\bin'
$ohpmBin = Join-Path $DevEcoHome 'tools\ohpm\bin'
$nodeHome = Join-Path $DevEcoHome 'tools\node'
$nodeExe = Join-Path $nodeHome 'node.exe'
$hvigorJs = Join-Path $hvigorHome 'bin\hvigor.js'

foreach ($path in @($nodeExe, $hvigorJs)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "未找到 DevEco 构建工具: $path。请传入 -DevEcoHome 或配置 DEVECO_HOME。"
    }
}

$env:PATH = "$hvigorBin;$ohpmBin;$nodeHome;$env:PATH"
$env:DEVECO_SDK_HOME = $SdkHome
$env:HOS_SDK_HOME = Join-Path $SdkHome 'default\openharmony'
$env:HOS_SDK_DIR = Join-Path $SdkHome 'default'
$env:OHOS_SDK_HOME = $env:HOS_SDK_HOME
$env:OHOS_SDK_DIR = $env:HOS_SDK_DIR

Push-Location (Join-Path $PSScriptRoot '..')
try {
    if ($Task -eq 'ohpm-install') {
        & (Join-Path $ohpmBin 'ohpm.bat') install
    } else {
        & $nodeExe $hvigorJs $Task '--no-daemon'
    }
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
