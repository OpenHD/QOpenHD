param(
    [Parameter(Mandatory = $true)]
    [string]$TargetDir,

    [Parameter(Mandatory = $true)]
    [string]$QtDir,

    [Parameter(Mandatory = $true)]
    [string]$MingwBin,

    [Parameter(Mandatory = $true)]
    [string]$QmlDir,

    [string]$FfmpegBin = ""
)

$ErrorActionPreference = "Stop"

function Copy-ExistingFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (Test-Path -LiteralPath $Source -PathType Leaf) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $Destination) -Force | Out-Null
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    } else {
        Write-Warning "Missing deploy file: $Source"
    }
}

function Copy-ExistingDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (Test-Path -LiteralPath $Source -PathType Container) {
        if (Test-Path -LiteralPath $Destination -PathType Container) {
            Remove-Item -LiteralPath $Destination -Recurse -Force
        }
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        Get-ChildItem -LiteralPath $Source -Recurse -File |
            Where-Object { $_.Name -notmatch '\.(debug|pdb|lib|exp)$' } |
            ForEach-Object {
                $relative = $_.FullName.Substring($Source.Length).TrimStart('\', '/')
                $target = Join-Path $Destination $relative
                New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
                Copy-Item -LiteralPath $_.FullName -Destination $target -Force
            }
    } else {
        Write-Warning "Missing deploy directory: $Source"
    }
}

$TargetDir = (Resolve-Path -LiteralPath $TargetDir).Path
$QtDir = (Resolve-Path -LiteralPath $QtDir).Path
$MingwBin = (Resolve-Path -LiteralPath $MingwBin).Path

$qtBin = Join-Path $QtDir "bin"
$qtPlugins = Join-Path $QtDir "plugins"
$qtQml = Join-Path $QtDir "qml"

$qtDlls = @(
    "Qt5Core.dll",
    "Qt5Gui.dll",
    "Qt5Network.dll",
    "Qt5Qml.dll",
    "Qt5QmlModels.dll",
    "Qt5QmlWorkerScript.dll",
    "Qt5Quick.dll",
    "Qt5QuickControls2.dll",
    "Qt5QuickTemplates2.dll",
    "Qt5Widgets.dll",
    "Qt5Charts.dll",
    "Qt5Location.dll",
    "Qt5Positioning.dll",
    "Qt5PositioningQuick.dll",
    "Qt5OpenGL.dll",
    "Qt5PrintSupport.dll",
    "Qt5QuickShapes.dll",
    "Qt5QuickWidgets.dll",
    "Qt5Svg.dll",
    "Qt5Xml.dll"
)

foreach ($dll in $qtDlls) {
    Copy-ExistingFile (Join-Path $qtBin $dll) (Join-Path $TargetDir $dll)
}

foreach ($dll in @("libEGL.dll", "libGLESv2.dll", "d3dcompiler_47.dll", "opengl32sw.dll")) {
    Copy-ExistingFile (Join-Path $qtBin $dll) (Join-Path $TargetDir $dll)
}

foreach ($dll in @("libgcc_s_dw2-1.dll", "libstdc++-6.dll", "libwinpthread-1.dll")) {
    Copy-ExistingFile (Join-Path $MingwBin $dll) (Join-Path $TargetDir $dll)
}

if ($FfmpegBin -and (Test-Path -LiteralPath $FfmpegBin -PathType Container)) {
    Get-ChildItem -LiteralPath $FfmpegBin -Filter "*.dll" -File |
        Copy-Item -Destination $TargetDir -Force
}

foreach ($pluginDir in @("platforms", "imageformats", "styles", "iconengines", "geoservices", "position", "bearer")) {
    Copy-ExistingDirectory (Join-Path $qtPlugins $pluginDir) (Join-Path $TargetDir $pluginDir)
}

foreach ($qmlImport in @("Qt", "QtCharts", "QtGraphicalEffects", "QtLocation", "QtPositioning", "QtQml", "QtQuick", "QtQuick.2")) {
    Copy-ExistingDirectory (Join-Path $qtQml $qmlImport) (Join-Path (Join-Path $TargetDir "qml") $qmlImport)
}

Write-Host "Windows deployment files copied to $TargetDir"
