[CmdletBinding()]
param(
    [ValidateSet('assembleHap', 'assembleApp', 'clean', 'ohpm-install', 'test')]
    [string]$Task = 'assembleHap',
    [string]$DevEcoHome = $env:DEVECO_HOME,
    [string]$SdkHome = $env:DEVECO_SDK_HOME
)

$ErrorActionPreference = 'Stop'

# DevEco installations are not interchangeable: Hvigor and the OHOS plugin
# must come from the same installation. Prefer the current 6.x installation,
# then derive the root from an explicitly supplied SDK path.
if ([string]::IsNullOrWhiteSpace($DevEcoHome) -and -not [string]::IsNullOrWhiteSpace($SdkHome)) {
    $sdkCandidate = [System.IO.DirectoryInfo]$SdkHome
    if ($sdkCandidate.Name -eq 'sdk') {
        $DevEcoHome = $sdkCandidate.Parent.FullName
    }
}
if ([string]::IsNullOrWhiteSpace($DevEcoHome)) {
    $devEcoCandidates = @(
        'D:\DevEco Studio',
        'C:\Program Files\Huawei\DevEco Studio'
    )
    $DevEcoHome = $devEcoCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($SdkHome)) {
    $SdkHome = Join-Path $DevEcoHome 'sdk'
}
if ([string]::IsNullOrWhiteSpace($DevEcoHome)) {
    throw '未找到 DevEco Studio。请配置 DEVECO_HOME，或传入 -DevEcoHome。'
}

$hvigorHome = Join-Path $DevEcoHome 'tools\hvigor\hvigor'
$hvigorBin = Join-Path $DevEcoHome 'tools\hvigor\bin'
$ohpmBin = Join-Path $DevEcoHome 'tools\ohpm\bin'
$nodeHome = Join-Path $DevEcoHome 'tools\node'
$cmakeBin = Join-Path $SdkHome 'default\openharmony\native\build-tools\cmake\bin'
$nodeExe = Join-Path $nodeHome 'node.exe'
$hvigorJs = Join-Path $hvigorHome 'bin\hvigor.js'
$ohpmExe = Join-Path $ohpmBin 'ohpm.bat'
$hvigorPackage = Join-Path $hvigorHome 'package.json'
$pluginPackage = Join-Path $DevEcoHome 'tools\hvigor\hvigor-ohos-plugin\package.json'

foreach ($path in @($nodeExe, $hvigorJs, $SdkHome, $hvigorPackage, $pluginPackage, $cmakeBin)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "未找到 DevEco 构建环境: $path。请确认 DevEco/Hvigor/SDK 来自同一安装。"
    }
}

$hvigorVersion = (Get-Content -Raw $hvigorPackage | ConvertFrom-Json).version
$pluginVersion = (Get-Content -Raw $pluginPackage | ConvertFrom-Json).version
if ($hvigorVersion -ne $pluginVersion) {
    throw "Hvigor 版本不一致: @ohos/hvigor=$hvigorVersion, @ohos/hvigor-ohos-plugin=$pluginVersion。"
}

$configPath = Join-Path $PSScriptRoot '..\hvigor\hvigor-config.json5'
$configText = Get-Content -Raw $configPath
$configuredPlugin = [regex]::Match($configText, '"@ohos/hvigor-ohos-plugin"\s*:\s*"([^"]+)"').Groups[1].Value
if ($configuredPlugin -and $configuredPlugin -ne $pluginVersion) {
    throw "项目插件版本 $configuredPlugin 与本机插件版本 $pluginVersion 不一致。"
}

Write-Host "DevEcoHome: $DevEcoHome"
Write-Host "SDK: $SdkHome"
Write-Host "Hvigor: $hvigorVersion"
Write-Host "OHOS plugin: $pluginVersion"

$env:PATH = "$hvigorBin;$ohpmBin;$nodeHome;$cmakeBin;$env:PATH"
$env:DEVECO_SDK_HOME = $SdkHome
$env:HOS_SDK_HOME = Join-Path $SdkHome 'default\openharmony'
$env:HOS_SDK_DIR = Join-Path $SdkHome 'default'
$env:OHOS_SDK_HOME = $env:HOS_SDK_HOME
$env:OHOS_SDK_DIR = $env:HOS_SDK_DIR

Push-Location (Join-Path $PSScriptRoot '..')
try {
    if ($Task -eq 'ohpm-install') {
        if (-not (Test-Path -LiteralPath $ohpmExe)) {
            throw "未找到 ohpm: $ohpmExe"
        }
        & $ohpmExe install
    } elseif ($Task -eq 'test') {
        & $nodeExe $hvigorJs test '--mode' module '-p' 'module=entry@default' '--no-daemon'
    } elseif ($Task -ne 'clean') {
        & (Join-Path $PSScriptRoot 'build-native.ps1') -DevEcoHome $DevEcoHome -SdkHome $SdkHome
        if ($LASTEXITCODE -ne 0) { throw 'Native 构建失败，停止 HAP 构建。' }
        & $nodeExe $hvigorJs $Task '--no-daemon'
    } else {
        & $nodeExe $hvigorJs $Task '--no-daemon'
    }
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
