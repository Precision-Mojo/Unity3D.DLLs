<#
VS.psm1 - Visual Studio utilities.

Copyright (c) 2013 Precision Mojo, LLC.
Copyright (c) 2017 Marcus R. Brown <me@igetgam.es>

This file is part of the Unity3D.DLLs project (http://precisionmojo.github.io/Unity3D.DLLs/) which is distributed
under the MIT License. Refer to the LICENSE.MIT.md document located in the project directory for licensing terms.

Some functions are based on code found in David Fowler's NuGetPowerTools package (https://github.com/davidfowl/NuGetPowerTools).
NuGetPowerTools is licensed under the Apache License 2.0 (https://nuget.codeplex.com/license).
#>

function Resolve-ProjectName
{
	param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]] $ProjectName
	)

	if ($ProjectName)
	{
		$projects = Get-Project $ProjectName
	}
	else
	{
		$projects = Get-Project
	}

	$projects
}

Export-ModuleMember Resolve-ProjectName
