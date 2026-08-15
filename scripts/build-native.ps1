[CmdletBinding()]
param(
    [string]$DevEcoHome = $env:DEVECO_HOME,
    [string]$SdkHome = $env:DEVECO_SDK_HOME,
    [string[]]$Abi = @('arm64-v8a', 'x86_64')
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($DevEcoHome)) { $DevEcoHome = 'D:\DevEco Studio' }
if ([string]::IsNullOrWhiteSpace($SdkHome)) { $SdkHome = Join-Path $DevEcoHome 'sdk' }

$cmake = Join-Path $SdkHome 'default\openharmony\native\build-tools\cmake\bin\cmake.exe'
$ninja = Join-Path $SdkHome 'default\openharmony\native\build-tools\cmake\bin\ninja.exe'
$toolchain = Join-Path $SdkHome 'default\openharmony\native\build\cmake\ohos.toolchain.cmake'
foreach ($path in @($cmake, $ninja, $toolchain)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "未找到 Native 构建工具: $path" }
}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$source = Join-Path $root 'napi'
$outputRoot = Join-Path $source 'build\libs'

foreach ($abiName in $Abi) {
    $buildDir = Join-Path $source ("build\.cmake\$abiName")
    $outputDir = Join-Path $outputRoot $abiName
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    & $cmake -S $source -B $buildDir -G Ninja `
        ("-DCMAKE_MAKE_PROGRAM={0}" -f $ninja) `
        ("-DCMAKE_TOOLCHAIN_FILE={0}" -f $toolchain) `
        ("-DOHOS_ARCH={0}" -f $abiName) `
        '-DOHOS_STL=c++_shared' `
        '-DCMAKE_BUILD_TYPE=Release' `
        ("-DCMAKE_LIBRARY_OUTPUT_DIRECTORY={0}" -f $outputDir)
    if ($LASTEXITCODE -ne 0) { throw "Native $abiName 配置失败" }
    & $cmake --build $buildDir --parallel 4
    if ($LASTEXITCODE -ne 0) { throw "Native $abiName 编译失败" }
    $library = Join-Path $outputDir 'liblark_engine.so'
    if (-not (Test-Path -LiteralPath $library)) { throw "Native $abiName 未产出 liblark_engine.so" }
    Write-Host "Native ${abiName}: $library"
}
