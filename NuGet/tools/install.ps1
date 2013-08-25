# Copyright (c) 2013 Precision Mojo, LLC.
#
# This file is part of the Unity3D.DLLs project (http://precisionmojo.github.io/Unity3D.DLLs/) which is distributed
# under the MIT License. Refer to the LICENSE.MIT.md document located in the project directory for licensing terms.

param($installPath, $toolsPath, $package, $project)

# Remove the sentinel file used to ensure that the package is installed per project.
# From http://danlimerick.wordpress.com/2011/10/01/getting-around-nugets-external-package-dependency-problem/
$project.ProjectItems | ForEach { if ($_.Name -eq "8CFAF032-C5F2-49A3-B8F6-07EF68F4623D.txt") { $_.Remove() } }
$projectPath = Split-Path $project.FullName -Parent
Join-Path $projectPath "8CFAF032-C5F2-49A3-B8F6-07EF68F4623D.txt" | Remove-Item

# Add the UnityEngine assembly reference to the project.
$project | Add-Unity3DReference

# Update Unity 3D references if the project's Unity3DSkipAutoUpdate property isn't set to true.
$projectProperties = $project | Get-Unity3DProjectProperties

if (!$projectProperties.Unity3DSkipAutoUpdate)
{
	$project | Update-Unity3DReferences
}
