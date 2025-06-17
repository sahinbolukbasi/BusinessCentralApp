#install bccontainerhelper
Write-Host "##[command]Installing BcContainerHelper"
Install-Module -Name bccontainerhelper -Force
$module = Get-InstalledModule -Name bccontainerhelper -ErrorAction Ignore
$versionStr = $module.Version.ToString()
Write-Host "##[section]BcContainerHelper $VersionStr installed"
#install bccontainerhelper

#creating container
$RepositoryDirectory = Get-Location

$ContainerName = 'Sandbox'
$password = ConvertTo-SecureString 'SecurePassword123$' -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ('admin', $password)

$artifactUrl = Get-BCArtifactUrl -country at -select Latest -storageAccount bcartifacts -type Sandbox

$AdditionalParameters = @()
$AdditionalParameters += '--volume "{0}:{1}"' -f $RepositoryDirectory, 'c:\sources'

$Params = @{}
$Params += @{ accept_eula = $true }
$Params += @{ artifactUrl = $artifactUrl }
$Params += @{ containerName = $ContainerName }
$Params += @{ auth = 'NavUserPassword' }
$Params += @{ credential = $Credential }
$Params += @{ isolation = 'process' }
$Params += @{ accept_outdated = $true }
$Params += @{ useBestContainerOS = $true }
$Params += @{ additionalParameters = $AdditionalParameters }

New-BcContainer @Params -shortcuts None
#creating container

#increase app version
$app = (Get-Content "app.json" -Encoding UTF8 | ConvertFrom-Json)
$existingVersion = $app.version -as [version]
$versionBuild = Get-Date -Format "yyyyMMdd"
$versionRevision = Get-Date -Format "HHmmss"
$nextVersion = [version]::new($existingVersion.Major, $existingVersion.Minor, $versionBuild, $versionRevision)
$app.version = "$nextVersion"
$app | ConvertTo-Json | Set-Content app.json
write-host "##[section]Version increased to $nextVersion"
#increase app version

#compile app
param(
    [string]$Version = ""
)

Write-Host "Business Central uygulama derleme işlemi başlatılıyor..."

if ($Version) {
    Write-Host "Hedef versiyon: $Version"
}

try {
    # Docker container'ı başlat ve uygulamayı derle
    Write-Host "Docker container başlatılıyor..."
    
    # AL Language extension ile derleme
    $dockerImage = "mcr.microsoft.com/businesscentral/sandbox:latest"
    
    # Container'ı çalıştır ve uygulamayı derle
    docker run --rm -v "${PWD}:C:\Source" $dockerImage powershell -Command "
        Set-Location C:\Source;
        Import-Module 'C:\Run\NavContainerHelper.psm1' -Force;
        Compile-AppInNavContainer -containerName 'bcserver' -appProjectFolder 'C:\Source' -credential (New-Object System.Management.Automation.PSCredential('admin', (ConvertTo-SecureString 'admin' -AsPlainText -Force)));
    "
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Uygulama başarıyla derlendi!" -ForegroundColor Green
        
        # Artifact'ları staging directory'ye kopyala
        if (Test-Path "*.app") {
            Copy-Item "*.app" $env:BUILD_STAGINGDIRECTORY
            Write-Host "App dosyaları staging directory'ye kopyalandı."
        }
    } else {
        Write-Error "Derleme işlemi başarısız oldu!"
        exit 1
    }
    
} catch {
    Write-Error "Derleme sırasında hata oluştu: $_"
    exit 1
}

Write-Host "Derleme işlemi tamamlandı."
#compile app

#copy app to build staging directory
write-host "##[section]Moving app to build staging directory"
Copy-Item -Path (Join-Path $RepositoryDirectory -ChildPath("\output\" + $app.publisher + "_" + $app.Name + "_" + $app.Version + ".app")) -Destination $env:Build_StagingDirectory
Copy-Item -Path (Join-Path $RepositoryDirectory -ChildPath("PublishApp.ps1")) -Destination $env:Build_StagingDirectory
write-host "##[section]Staging directory $env:Build_StagingDirectory"
#copy app to build staging directory

#updating build pipeline number
Write-Host "##vso[build.updatebuildnumber]$nextVersion"
#updating build pipeline number
