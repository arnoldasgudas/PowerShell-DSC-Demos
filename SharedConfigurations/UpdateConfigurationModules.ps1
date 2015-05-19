$modulePath = Resolve-Path $env:ProgramFiles\WindowsPowerShell\Modules
$configurationFolder = Resolve-Path $PSScriptRoot\Modules\*
Copy-Item -Path $configurationFolder -Destination $modulePath -Recurse -Force -Verbose

$ManifestFile = Join-Path $modulePath '\MyCustomResources\MyCustomResources.psd1'
$ModuleVersion = '1.0.0.0'
$Author = 'Arnoldas Gudas'
$Description = 'Module with my custom resources for website setup'
New-ModuleManifest -Path $ManifestFile -ModuleVersion $ModuleVersion -Author $Author -Description $Description -Verbose
New-ModuleManifest -Path $modulePath\MyCustomResources\DSCResources\DevWebsite\DevWebsite.psd1 -RootModule DevWebsite.schema.psm1 -Verbose