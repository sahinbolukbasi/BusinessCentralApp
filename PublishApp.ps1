#install bccontainerhelper
Write-Host "##[command]Installing BcContainerHelper"
Install-Module -Name bccontainerhelper -Force
$module = Get-InstalledModule -Name bccontainerhelper -ErrorAction Ignore
$versionStr = $module.Version.ToString()
Write-Host "##[section]BcContainerHelper $VersionStr installed"
#install bccontainerhelper

$authContext = New-BcAuthContext -refreshToken $env:refreshToken -tenantID $env:TENANTID

$ArtifactsDirectory = (Join-Path -Path $env:System_ArtifactsDirectory -ChildPath ($env:Release_PrimaryArtifactSourceAlias + '\Artifacts'))
$AppFile = Get-ChildItem -Path $ArtifactsDirectory -Filter "*.app"
write-host "##[section]App file" $AppFile.FullName
write-host "##[section]Publishing app to tenant:" $env:TENANTID "Environment:" $env:ENVIRONMENT
Publish-PerTenantExtensionApps `
    -bcAuthContext $authContext `
    -environment $env:ENVIRONMENT `
    -appFiles $AppFile.FullName `
    -schemaSyncMode Force