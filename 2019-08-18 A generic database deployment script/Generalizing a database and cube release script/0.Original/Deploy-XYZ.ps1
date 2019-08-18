[string]$deployChannel = $env:DeployChannel

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
	Publish-ProjectDatabase -DacpacPath "$dbPath\MyCompany.XYZ.TheReleasedApp.Retail.ReconDB.dacpac" -ProfilePath "$dbPath\MyCompany.XYZ.TheReleasedApp.Retail.ReconDB.$deployChannel.publish.xml" -parameters '/TargetServerName:IKOLBE-LTP','/TargetDatabaseName:XYZReconVAS'
}

function Update-SSASCubeAsdatabaseFile {
	param (
		[string]$SSASCubeAsdatabasePath,
		[string]$DeploymentTargetConfigPath
	)
	
	try {
		if ([string]::IsNullOrEmpty($SSASCubeAsdatabasePath)) {
			Write-Host "$SSASCubeAsdatabasePath not found" -fore red
			exit 1
		}

		if ([string]::IsNullOrEmpty($DeploymentTargetConfigPath)) {
			Write-Host "$DeploymentTargetConfigPath not found" -fore red
			exit 1
		}

		$SSASCubeAsdatabaseFileName = [IO.Path]::GetFileName($SSASCubeAsdatabasePath)
		Write-Host "Updating $SSASCubeAsdatabaseFileName..."

		[xml]$SSASCubeAsdatabaseFile = Get-Content "$SSASCubeAsdatabasePath"
		[xml]$deploymentTargetConfigFile = Get-Content "$DeploymentTargetConfigPath"

		$SSASCubeAsdatabaseFile.Database.ID = $deploymentTargetConfigFile.DeploymentTarget.Database
		$SSASCubeAsdatabaseFile.Database.Name = $deploymentTargetConfigFile.DeploymentTarget.Database

		$SSASCubeAsdatabaseFile.Save("$SSASCubeAsdatabasePath")

		Write-Host "$SSASCubeAsdatabaseFileName datasource updated..."
	} catch {
		Log "Update-SSASCubeAsdatabaseFile failed: $_" -Error
	}
}

function Update-SSASCubeDeploymentOptions {
	param (
		[string]$SSASCubeDeploymentOptionsPath,
		[string]$DeploymentOptionsConfigPath
	)

	try {
		if ([string]::IsNullOrEmpty($SSASCubeDeploymentOptionsPath)) {
			Write-Host "$SSASCubeDeploymentOptionsPath not found" -fore red
			exit 1
		}

		if ([string]::IsNullOrEmpty($DeploymentOptionsConfigPath)) {
			Write-Host "$DeploymentOptionsConfigPath not found" -fore red
			exit 1
		}

		$SSASdeploymentOptionsFileName = [IO.Path]::GetFileName($SSASCubeDeploymentOptionsPath)
		Write-Host "Updating $SSASdeploymentOptionsFileName..."

		[xml]$SSASCubeDeploymentOptionsFile = Get-Content "$SSASCubeDeploymentOptionsPath"
		[xml]$deploymentOptionsConfigFile = Get-Content "$DeploymentOptionsConfigPath"
		
		$SSASCubeDeploymentOptions = $SSASCubeDeploymentOptionsFile.DeploymentOptions.ChildNodes
		$deploymentOptions = $deploymentOptionsConfigFile.DeploymentOptions.ChildNodes

		foreach ($deploymentOption in $deploymentOptions) {
			$SSASCubeDeploymentOption = $SSASCubeDeploymentOptions | Where-Object { $_.Name -eq $deploymentOption.Name }

			if ($null -ne $SSASCubeDeploymentOption) {
				$SSASCubeDeploymentOption.InnerText = $deploymentOption.InnerText
			}
		}

		$SSASCubeDeploymentOptionsFile.Save("$SSASCubeDeploymentOptionsPath")

		Write-Host "$SSASdeploymentOptionsFileName datasource updated..."
	}
	catch {
		Log "Update-SSASCubeDeploymentOptions failed: $_" -Error
	}
}


function Update-SSASCubeDeploymentTarget {
	param (
		[string]$SSASCubeDeploymentTargetsPath,
		[string]$DeploymentTargetConfigPath
	)

	try {
		if ([string]::IsNullOrEmpty($SSASCubeDeploymentTargetsPath)) {
			Write-Host "$SSASCubeDeploymentTargetsPath not found" -fore red
			exit 1
		}

		if ([string]::IsNullOrEmpty($DeploymentTargetConfigPath)) {
			Write-Host "$DeploymentTargetConfigPath not found" -fore red
			exit 1
		}

		$SSASdeploymentTargetsFileName = [IO.Path]::GetFileName($SSASCubeDeploymentTargetsPath)
		Write-Host "Updating $SSASdeploymentTargetsFileName..."

		[xml]$SSASCubeDeploymentTargetsFile = Get-Content "$SSASCubeDeploymentTargetsPath"
		[xml]$deploymentTargetConfigFile = Get-Content "$DeploymentTargetConfigPath"

		$SSASCubeDeploymentTargetsFile.DeploymentTarget.Database = $deploymentTargetConfigFile.DeploymentTarget.Database
		$SSASCubeDeploymentTargetsFile.DeploymentTarget.Server = $deploymentTargetConfigFile.DeploymentTarget.Server
		$SSASCubeDeploymentTargetsFile.DeploymentTarget.ConnectionString = $deploymentTargetConfigFile.DeploymentTarget.ConnectionString

		$SSASCubeDeploymentTargetsFile.Save("$SSASCubeDeploymentTargetsPath")

		Write-Host "$SSASdeploymentTargetsFileName datasource updated..."
	}
	catch {
		Log "Update-SSASCubeDeploymentTarget failed: $_" -Error
	}
}

function Update-SSASCubeDataSource {
	param (
		[string]$SSASCubeConfigSettingsPath,
		[string]$DataSourceConfigPath
	)

	try {
		if ([string]::IsNullOrEmpty($SSASCubeConfigSettingsPath)) {
			Write-Host "$SSASCubeConfigSettingsPath not found" -fore red
			exit 1
		}

		if ([string]::IsNullOrEmpty($DataSourceConfigPath)) {
			Write-Host "$DataSourceConfigPath not found" -fore red
			exit 1
		}

		$SSASCubeConfigSettingsFileName = [IO.Path]::GetFileName($SSASCubeConfigSettingsPath)
		Write-Host "Updating $SSASCubeConfigSettingsFileName..."
		
		[xml]$SSASCubeConfigSettingsFile = Get-Content "$SSASCubeConfigSettingsPath"
		[xml]$dataSourceConfigFile = Get-Content "$DataSourceConfigPath"

		$configSettingsDataSources = $SSASCubeConfigSettingsFile.ConfigurationSettings.Database.DataSources.DataSource
		
		foreach ($dataSource in $dataSourceConfigFile.DataSources.DataSource) {
			$configSettingDataSource = $configSettingsDataSources | Where-Object { $_.ID -eq $dataSource.ID }
			$configSettingDataSource.ConnectionString = $dataSource.ConnectionString
		}

		$SSASCubeConfigSettingsFile.Save("$SSASCubeConfigSettingsPath")

		Write-Host "$SSASCubeConfigSettingsFileName datasource updated..."
	}
	catch {
		Log "Update-SSASCubeDetails failed: $_" -Error
	}
}

# # # # Cubes # # # #
if (Test-Path $ssasPath) {
	try {
		Push-Location "$ssasPath\DeploymentUtility\"

		if (Test-Path "$ssasDBPath\Recon EFT") {
			Update-SSASCubeAsdatabaseFile `
				-SSASCubeAsdatabasePath "$ssasDBPath\Recon EFT\MyCompany.Recon.EFT.SSASCube.asdatabase" `
				-DeploymentTargetConfigPath "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Recon EFT\MyCompany.Recon.EFT.SSASCube.deploymenttargets"

			Update-SSASCubeDeploymentOptions `
				-SSASCubeDeploymentOptionsPath "$ssasDBPath\Recon EFT\MyCompany.Recon.EFT.SSASCube.deploymentoptions" `
				-DeploymentOptionsConfigPath "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Shared\default.deploymentoptions"

			Update-SSASCubeDeploymentTarget `
				-SSASCubeDeploymentTargetsPath "$ssasDBPath\Recon EFT\MyCompany.Recon.EFT.SSASCube.deploymenttargets" `
				-DeploymentTargetConfigPath "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Recon EFT\MyCompany.Recon.EFT.SSASCube.deploymenttargets"

			Update-SSASCubeDataSource `
				-SSASCubeConfigSettingsPath "$ssasDBPath\Recon EFT\MyCompany.Recon.EFT.SSASCube.configsettings" `
				-DataSourceConfigPath "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Recon EFT\DataSources.configsettings"

			Invoke-Trap -Command ".\Microsoft.AnalysisServices.Deployment.ps1 `"$ssasDBPath\Recon EFT\MyCompany.Recon.EFT.SSASCube.asdatabase`" `"Retail Recon EFT`"" -Message "Deploying EFT SSAS database failed" -Fatal
		}
	
		if (Test-Path "$ssasDBPath\Recon VAS") {
			Update-SSASCubeAsdatabaseFile `
				-SSASCubeAsdatabasePath "$ssasDBPath\Recon VAS\MyCompany.Recon.VAS.SSASCube.asdatabase" `
				-DeploymentTargetConfigPath "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Recon VAS\MyCompany.Recon.VAS.SSASCube.deploymenttargets"

			Update-SSASCubeDeploymentOptions `
				-SSASCubeDeploymentOptionsPath "$ssasDBPath\Recon VAS\MyCompany.Recon.VAS.SSASCube.deploymentoptions" `
				-DeploymentOptionsConfigPath "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Shared\default.deploymentoptions"

			Update-SSASCubeDeploymentTarget `
				-SSASCubeDeploymentTargetsPath "$ssasDBPath\Recon VAS\MyCompany.Recon.VAS.SSASCube.deploymenttargets" `
				-DeploymentTargetConfigPath "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Recon VAS\MyCompany.Recon.VAS.SSASCube.deploymenttargets"

			Update-SSASCubeDataSource `
				-SSASCubeConfigSettingsPath "$ssasDBPath\Recon VAS\MyCompany.Recon.VAS.SSASCube.configsettings" `
				-DataSourceConfigPath "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Recon VAS\DataSources.configsettings"

			Invoke-Trap -Command ".\Microsoft.AnalysisServices.Deployment.ps1 `"$ssasDBPath\Recon VAS\MyCompany.Recon.VAS.SSASCube.asdatabase`" `"Retail Recon VAS`"" -Message "Deploying VAS SSAS database failed" -Fatal
		}

		if (Test-Path "$ssasDBPath\Recon Fee") {
			Update-SSASCubeAsdatabaseFile `
				-SSASCubeAsdatabasePath "$ssasDBPath\Recon Fee\MyCompany.TheReleasedApp.FeeSSASDB.asdatabase" `
				-DeploymentTargetConfigPath "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Recon Fee\MyCompany.TheReleasedApp.FeeSSASDB.deploymenttargets"

			Update-SSASCubeDeploymentOptions `
				-SSASCubeDeploymentOptionsPath "$ssasDBPath\Recon Fee\MyCompany.TheReleasedApp.FeeSSASDB.deploymentoptions" `
				-DeploymentOptionsConfigPath "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Shared\default.deploymentoptions"

			Update-SSASCubeDeploymentTarget `
				-SSASCubeDeploymentTargetsPath "$ssasDBPath\Recon Fee\MyCompany.TheReleasedApp.FeeSSASDB.deploymenttargets" `
				-DeploymentTargetConfigPath "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Recon Fee\MyCompany.TheReleasedApp.FeeSSASDB.deploymenttargets"

			Update-SSASCubeDataSource `
				-SSASCubeConfigSettingsPath "$ssasDBPath\Recon Fee\MyCompany.TheReleasedApp.FeeSSASDB.configsettings" `
				-DataSourceConfigPath "$PSScriptRoot\Runtime\Config\$deployChannel\SSAS\Databases\Recon Fee\DataSources.configsettings"

			Invoke-Trap -Command ".\Microsoft.AnalysisServices.Deployment.ps1 `"$ssasDBPath\Recon Fee\MyCompany.TheReleasedApp.FeeSSASDB.asdatabase`" `"Retail Recon Fee`"" -Message "Deploying Fee SSAS database failed" -Fatal
		}
	} catch {
		Log "SSAS DeploymentUtility failed: $_" -Error
		exit 1
	} finally {
		Pop-Location
	}
}