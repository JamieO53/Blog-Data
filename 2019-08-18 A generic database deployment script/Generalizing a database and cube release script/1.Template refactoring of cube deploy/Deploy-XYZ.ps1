[string]$deployChannel = $env:DeployChannel
[string]$devBase = $env:DevBase

if ([string]::IsNullOrEmpty($deployChannel)) {
	Write-Host "DeployChannel environment variable not set" -fore red
	exit
}

if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}

Import-Module "$PSScriptRoot\PowerShell\NugetDbPacker.psd1"
$deployRoot = "$PSScriptRoot"
$dbPath = "$PSScriptRoot\Databases"
$ssasPath = "$PSScriptRoot\Runtime\SSAS"
$ssasDBPath = "$ssasPath\Databases"

# # # # Databases # # # #
Publish-ProjectDatabase -DacpacPath "$dbPath\MyCompany.XYZ.TheReleasedApp.Retail.AuthentDB.dacpac" -ProfilePath "$dbPath\MyCompany.XYZ.TheReleasedApp.Retail.AuthentDB.$deployChannel.publish.xml"
Publish-ProjectDatabase -DacpacPath "$dbPath\MyCompany.XYZ.TheReleasedApp.Retail.IrisDB.dacpac" -ProfilePath "$dbPath\MyCompany.XYZ.TheReleasedApp.Retail.IrisDB.$deployChannel.publish.xml"
Publish-ProjectDatabase -DacpacPath "$dbPath\MyCompany.XYZ.TRA.Retail.NotificaitonsDB.dacpac" -ProfilePath "$dbPath\MyCompany.XYZ.TRA.Retail.NotificaitonsDB.$deployChannel.publish.xml"
Publish-ProjectDatabase -DacpacPath "$dbPath\MyCompany.XYZ.TheReleasedApp.Retail.StagingDB.dacpac" -ProfilePath "$dbPath\MyCompany.XYZ.TheReleasedApp.Retail.StagingDB.$deployChannel.publish.xml"
Publish-ProjectDatabase -DacpacPath "$dbPath\MyCompany.XYZ.TRA.Retail.ExportManagerDB.dacpac" -ProfilePath "$dbPath\MyCompany.XYZ.TRA.Retail.ExportManagerDB.$deployChannel.publish.xml"
Publish-ProjectDatabase -DacpacPath "$dbPath\MyCompany.XYZ.TheReleasedApp.Retail.ReconDB.dacpac" -ProfilePath "$dbPath\MyCompany.XYZ.TheReleasedApp.Retail.ReconDB.$deployChannel.publish.xml"

if ($deployChannel -in "UAT", "PROD") {
# if (1 -eq 1) {
	Publish-ProjectDatabase 
		-DacpacPath "$dbPath\MyCompany.XYZ.TheReleasedApp.Retail.ReconDB.dacpac"
		-ProfilePath "$dbPath\MyCompany.XYZ.TheReleasedApp.Retail.ReconDB.$deployChannel.publish.xml" 
		-parameters '/TargetServerName:IKOLBE-LTP','/TargetDatabaseName:XYZReconVAS'
}

# # # # Cubes # # # #
if (Test-Path $ssasPath) {
	try {
		Push-Location "$ssasPath\DeploymentUtility\"

		Publish-SSASCubeDatabase
			-CubeFolder "$ssasDBPath\Recon EFT"
			-CubeName "MyCompany.Recon.EFT.SSASCube"
			-ConfigSharedFolder "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Shared"
			-ConfigFolder "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Recon EFT"
			-DatabaseName "Retail Recon EFT"
			-DeploymentError "Deploying EFT SSAS database failed"

		Publish-SSASCubeDatabase
			-CubeFolder "$ssasDBPath\Recon VAS"
			-CubeName "MyCompany.Recon.VAS.SSASCube"
			-ConfigSharedFolder "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Shared"
			-ConfigFolder "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Recon VAS"
			-DatabaseName "Retail Recon VAS"
			-DeploymentError "Deploying VAS SSAS database failed"

		Publish-SSASCubeDatabase
			-CubeFolder "$ssasDBPath\Recon Fee"
			-CubeName "MyCompany.TheReleasedApp.FeeSSASDB"
			-ConfigSharedFolder "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Shared"
			-ConfigFolder "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Recon Fee"
			-DatabaseName "Retail Recon Fee"
			-DeploymentError "Deploying Fee SSAS database failed"
	} catch {
		Log "SSAS DeploymentUtility failed: $_" -Error
		exit 1
	} finally {
		Pop-Location
	}
}