[CmdletBinding()]
param(
    [string]$CompilerPath,
    [string]$OutputPath,
    [string]$Version
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$releaseVersion = $null

if ($Version) {
    $releaseVersion = $Version.Trim()
    if ($releaseVersion.StartsWith("v", [System.StringComparison]::OrdinalIgnoreCase)) {
        $releaseVersion = $releaseVersion.Substring(1)
    }
    if ($releaseVersion -notmatch '^\d+\.\d+\.\d+\.\d+$') {
        throw "Version must use four numeric components, for example v1.4.2026.718."
    }
    foreach ($component in $releaseVersion.Split('.')) {
        if ([int64]$component -gt 65535) {
            throw "Each version component must be between 0 and 65535: $releaseVersion"
        }
    }
}

if (-not $OutputPath) {
    $OutputPath = Join-Path $projectRoot "dist\D3keyHelper.exe"
}

function Find-Ahk2Exe {
    param([string]$RequestedPath)

    $candidates = @()
    if ($RequestedPath) {
        $candidates += $RequestedPath
    }
    if ($env:AHK2EXE) {
        $candidates += $env:AHK2EXE
    }
    if ($env:ProgramFiles) {
        $candidates += (Join-Path $env:ProgramFiles "AutoHotkey\Compiler\Ahk2Exe.exe")
    }
    if (${env:ProgramFiles(x86)}) {
        $candidates += (Join-Path ${env:ProgramFiles(x86)} "AutoHotkey\Compiler\Ahk2Exe.exe")
    }

    $command = Get-Command "Ahk2Exe.exe" -ErrorAction SilentlyContinue
    if ($command) {
        $candidates += $command.Source
    }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Ahk2Exe.exe was not found. Install AutoHotkey v1.1 or pass -CompilerPath."
}

$sourcePath = Join-Path $projectRoot "src\d3keyhelper.ahk"
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Source file was not found: $sourcePath"
}

$compiler = Find-Ahk2Exe -RequestedPath $CompilerPath
$compilerDirectory = Split-Path -Parent $compiler
$baseFile = Join-Path $compilerDirectory "Unicode 64-bit.bin"
if (-not (Test-Path -LiteralPath $baseFile -PathType Leaf)) {
    throw "AutoHotkey v1 Unicode 64-bit.bin was not found beside Ahk2Exe.exe. AutoHotkey v2 cannot compile this project."
}

$compileSourcePath = $sourcePath
$temporarySourcePath = $null
if ($releaseVersion) {
    $sourceContents = [System.IO.File]::ReadAllText($sourcePath)
    $fileVersionPattern = '(?m)^;@Ahk2Exe-SetFileVersion\s+.*$'
    $productVersionPattern = '(?m)^;@Ahk2Exe-SetProductVersion\s+.*$'
    if (-not [regex]::IsMatch($sourceContents, $fileVersionPattern) -or
        -not [regex]::IsMatch($sourceContents, $productVersionPattern)) {
        throw "Version directives were not found in the AutoHotkey source."
    }
    $versionedSource = [regex]::Replace($sourceContents, $fileVersionPattern, ";@Ahk2Exe-SetFileVersion $releaseVersion")
    $versionedSource = [regex]::Replace($versionedSource, $productVersionPattern, ";@Ahk2Exe-SetProductVersion $releaseVersion")
    $temporarySourcePath = Join-Path ([System.IO.Path]::GetTempPath()) "D3KeyHelper-$([guid]::NewGuid().ToString('N')).ahk"
    $utf8WithBom = [System.Text.UTF8Encoding]::new($true)
    [System.IO.File]::WriteAllText($temporarySourcePath, $versionedSource, $utf8WithBom)
    $compileSourcePath = $temporarySourcePath
}

if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $projectRoot $OutputPath
}
$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)

Write-Host "Compiling $sourcePath"
Write-Host "Compiler: $compiler"
if ($releaseVersion) {
    Write-Host "Version: $releaseVersion"
}

$compilerArguments = '/in "{0}" /out "{1}" /bin "{2}"' -f $compileSourcePath, $OutputPath, $baseFile
try {
    $compilerProcess = Start-Process -FilePath $compiler -ArgumentList $compilerArguments -Wait -PassThru
    if ($compilerProcess.ExitCode -ne 0) {
        throw "Ahk2Exe failed with exit code $($compilerProcess.ExitCode)."
    }
}
finally {
    if ($temporarySourcePath -and (Test-Path -LiteralPath $temporarySourcePath)) {
        Remove-Item -LiteralPath $temporarySourcePath -Force
    }
}
if (-not (Test-Path -LiteralPath $OutputPath -PathType Leaf)) {
    throw "Ahk2Exe completed without creating the expected output: $OutputPath"
}

$fileVersion = (Get-Item -LiteralPath $OutputPath).VersionInfo.FileVersion
if (-not $fileVersion -or $fileVersion -notmatch '^\d+\.\d+\.\d+\.\d+$') {
    throw "The compiled executable has an invalid file version: $fileVersion"
}
if ($releaseVersion -and $fileVersion -ne $releaseVersion) {
    throw "Compiled file version '$fileVersion' does not match requested version '$releaseVersion'."
}
$productVersion = (Get-Item -LiteralPath $OutputPath).VersionInfo.ProductVersion
if (-not $productVersion -or $productVersion -notmatch '^\d+\.\d+\.\d+\.\d+$') {
    throw "The compiled executable has an invalid product version: $productVersion"
}
if ($releaseVersion -and $productVersion -ne $releaseVersion) {
    throw "Compiled product version '$productVersion' does not match requested version '$releaseVersion'."
}

$archiveName = "D3keyHelper-v$fileVersion-windows-x64.zip"
$archivePath = Join-Path $outputDirectory $archiveName
Compress-Archive -LiteralPath $OutputPath -DestinationPath $archivePath -CompressionLevel Optimal -Force

Write-Host "Build completed: $OutputPath" -ForegroundColor Green
Write-Host "Package created: $archivePath" -ForegroundColor Green
