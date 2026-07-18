[CmdletBinding()]
param(
    [string]$CompilerPath,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

if (-not $OutputPath) {
    $OutputPath = Join-Path $PSScriptRoot "dist\D3keyHelper.exe"
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

$sourcePath = Join-Path $PSScriptRoot "d3keyhelper.ahk"
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Source file was not found: $sourcePath"
}

$compiler = Find-Ahk2Exe -RequestedPath $CompilerPath
$compilerDirectory = Split-Path -Parent $compiler
$baseFile = Join-Path $compilerDirectory "Unicode 64-bit.bin"
if (-not (Test-Path -LiteralPath $baseFile -PathType Leaf)) {
    throw "AutoHotkey v1 Unicode 64-bit.bin was not found beside Ahk2Exe.exe. AutoHotkey v2 cannot compile this project."
}

if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot $OutputPath
}
$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)

Write-Host "Compiling $sourcePath"
Write-Host "Compiler: $compiler"

$compilerArguments = '/in "{0}" /out "{1}" /bin "{2}"' -f $sourcePath, $OutputPath, $baseFile
$compilerProcess = Start-Process -FilePath $compiler -ArgumentList $compilerArguments -Wait -PassThru
if ($compilerProcess.ExitCode -ne 0) {
    throw "Ahk2Exe failed with exit code $($compilerProcess.ExitCode)."
}
if (-not (Test-Path -LiteralPath $OutputPath -PathType Leaf)) {
    throw "Ahk2Exe completed without creating the expected output: $OutputPath"
}

$fileVersion = (Get-Item -LiteralPath $OutputPath).VersionInfo.FileVersion
if (-not $fileVersion -or $fileVersion -notmatch '^\d+\.\d+\.\d+\.\d+$') {
    throw "The compiled executable has an invalid file version: $fileVersion"
}

$archiveName = "D3keyHelper-v$fileVersion-windows-x64.zip"
$archivePath = Join-Path $outputDirectory $archiveName
Compress-Archive -LiteralPath $OutputPath -DestinationPath $archivePath -CompressionLevel Optimal -Force

Write-Host "Build completed: $OutputPath" -ForegroundColor Green
Write-Host "Package created: $archivePath" -ForegroundColor Green
