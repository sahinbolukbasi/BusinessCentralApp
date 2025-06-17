param(
    [string]$AppJsonPath = "app.json",
    [string]$VersionType = "patch" # major, minor, patch
)

Write-Host "Versiyon güncelleme işlemi başlatılıyor..."

# app.json dosyasını oku
if (-not (Test-Path $AppJsonPath)) {
    Write-Error "app.json dosyası bulunamadı: $AppJsonPath"
    exit 1
}

$appContent = Get-Content $AppJsonPath -Raw | ConvertFrom-Json

# Mevcut versiyonu al
$currentVersion = $appContent.version
Write-Host "Mevcut versiyon: $currentVersion"

# Versiyon numarasını parçala
$versionParts = $currentVersion.Split('.')
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$patch = [int]$versionParts[2]
$build = [int]$versionParts[3]

# Branch'e göre versiyon tipini belirle
$branchName = $env:BUILD_SOURCEBRANCHNAME
if ($branchName -like "release/*") {
    $VersionType = "minor"
} elseif ($branchName -eq "main") {
    $VersionType = "major"
} else {
    $VersionType = "patch"
}

# Versiyonu güncelle
switch ($VersionType) {
    "major" {
        $major++
        $minor = 0
        $patch = 0
        $build = 0
    }
    "minor" {
        $minor++
        $patch = 0
        $build = 0
    }
    "patch" {
        $patch++
        $build = 0
    }
    default {
        $build++
    }
}

$newVersion = "$major.$minor.$patch.$build"
Write-Host "Yeni versiyon: $newVersion"

# app.json'ı güncelle
$appContent.version = $newVersion
$updatedJson = $appContent | ConvertTo-Json -Depth 10

# UTF-8 encoding ile dosyayı kaydet
[System.IO.File]::WriteAllText($AppJsonPath, $updatedJson, [System.Text.Encoding]::UTF8)

Write-Host "app.json dosyası başarıyla güncellendi."

# Pipeline değişkenini ayarla
Write-Host "##vso[task.setvariable variable=AppVersion]$newVersion"
Write-Host "##vso[task.setvariable variable=AppVersion;isOutput=true]$newVersion"
