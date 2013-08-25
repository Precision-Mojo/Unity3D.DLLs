# Copyright (c) 2013 Precision Mojo, LLC.
#
# This file is part of the Unity3D.DLLs project (http://precisionmojo.github.io/Unity3D.DLLs/) which is distributed
# under the MIT License. Refer to the LICENSE.MIT.md document located in the project directory for licensing terms.

param($installPath, $toolsPath, $package, $project)

# Remove the module if it's loaded
if (Get-Module | ? { $_.Name -eq "Unity3D.DLLs" })
{
	Remove-Module Unity3D.DLLs
}

Import-Module (Join-Path $toolsPath Unity3D.DLLs.psd1)

# Update the Unity 3D references on all projects that don't have Unity3DSkipAutoUpdate set to true.
Get-Project -All | % {
	$projectProperties = $_ | Get-Unity3DProjectProperties

	if (!$projectProperties.Unity3DSkipAutoUpdate)
	{
		$_ | Update-Unity3DReferences
	}
}
