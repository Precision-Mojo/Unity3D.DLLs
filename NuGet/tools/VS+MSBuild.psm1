<#
VS+MSBuild.psm1 - Visual Studio and MSBuild utilities.

Copyright (c) 2013 Precision Mojo, LLC.

This file is part of the Unity3D.DLLs project (< URL >) which is distributed under the MIT License.
Refer to the LICENSE.MIT.md document located in the project directory for licensing terms.

Several functions are copied from scripts found in David Fowler's NuGetPowerTools package (https://github.com/davidfowl/NuGetPowerTools).
NuGetPowerTools is licensed under the Apache License 2.0 (https://nuget.codeplex.com/license).
#>

function Get-ProjectFromName
{
	param (
		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]]$projectName
	)

	if ($projectName)
	{
		$projects = Get-Project $projectName
	}
	else
	{
		$projects = Get-Project
	}

	$projects
}

function Get-MSBuildProject
{
	param (
		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]]$projectName
	)

	process
	{
		(Get-ProjectFromName $projectName) | % {
			$path = $_.FullName
			@([Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.GetLoadedProjects($path))[0]
		}
	}
}
