# Big thanks to Teemaw for putting this together !

param(
    [string]$Configuration = "Release",
    [string]$ProjectPath = ".\GDWeave.Sample\pondportal.csproj",
    [string]$GDWeavePath = "C:\Program Files (x86)\Steam\steamapps\common\WEBFISHING\GDWeave"
)

# Clean and build
$env:GDWeavePath = $GDWeavePath
dotnet clean $ProjectPath --configuration $Configuration
dotnet restore $ProjectPath
dotnet build $ProjectPath --configuration $Configuration --no-restore

# Update Thunderstore manifest
$ThunderstoreManifestPath = ".\thunderstore\manifest.json"
$GDWeaveManifestPath = ".\GDWeave.Sample\manifest.json"
$version = (Get-Content $GDWeaveManifestPath | ConvertFrom-Json).Metadata.Version
$manifest = Get-Content $ThunderstoreManifestPath | ConvertFrom-Json
$manifest.version_number = $version
$manifest | ConvertTo-Json -Depth 1 | Set-Content $ThunderstoreManifestPath

cp ".\gd\pondportal.pck" ".\thunderstore\GDWeave\mods"
cp ".\GDWeave.Sample\bin\Release\net8.0\pondportal.dll" ".\thunderstore\GDWeave\mods\"
cp ".\GDWeave.Sample\bin\Release\net8.0\manifest.json" ".\thunderstore\GDWeave\mods\"
cp ".\LICENSE" ".\thunderstore"

# Zip it up
$gitTagOrHash = if (git describe --exact-match --tags HEAD 2>$null) {
    git describe --exact-match --tags HEAD
} else {
    git rev-parse --short HEAD
}
$zipPath = ".\thunderstore\pondportal_$gitTagOrHash.zip"
Compress-Archive -Path @(
   ".\thunderstore\GDWeave",
   ".\thunderstore\icon.png",
   ".\thunderstore\manifest.json",
   ".\thunderstore\CHANGELOG.md",
   ".\thunderstore\README.md"
   ".\thunderstore\LICENSE"
) -DestinationPath $zipPath -Force


rm ".\thunderstore\GDWeave\mods\pondportal.pck"
rm ".\thunderstore\GDWeave\mods\pondportal.dll"
rm ".\thunderstore\GDWeave\mods\manifest.json"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed LASTEXITCODE=$LASTEXITCODE"
    exit $LASTEXITCODE
}