<#
VSProject.psm1 - Visual Studio project utilities.

Copyright (c) 2013 Precision Mojo, LLC.
Copyright (c) 2017 Marcus R. Brown <me@igetgam.es>

This file is part of the Unity3D.DLLs project (http://precisionmojo.github.io/Unity3D.DLLs/) which is distributed
under the MIT License. Refer to the LICENSE.MIT.md document located in the project directory for licensing terms.

Some functions are based on code found in David Fowler's NuGetPowerTools package (https://github.com/davidfowl/NuGetPowerTools).
NuGetPowerTools is licensed under the Apache License 2.0 (https://nuget.codeplex.com/license).
#>

function Get-ProjectReferencePath
{
	param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[String] $ProjectName,
		[switch] $UseMSBuildProject
	)

	if ($UseMSBuildProject)
	{
		$pathProperty = Get-MSBuildProperty "ReferencePath" $ProjectName

		if ($pathProperty)
		{
			return $pathProperty.UnevaluatedValue
		}
	}
	else
	{
		(Resolve-ProjectName $ProjectName).Properties.Item("ReferencePath").Value
	}
}

function Set-ProjectReferencePath
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)]
		[string] $ReferencePath,
		[Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
		[String] $ProjectName,
		[switch] $UseMSBuildProject
	)

	if ($UseMSBuildProject)
	{
		Set-MSBuildProperty "ReferencePath" $ReferencePath $ProjectName -SpecifyUserProject
	}
	else
	{
		(Resolve-ProjectName $ProjectName).Properties.Item("ReferencePath").Value = $ReferencePath
	}
}

if ($Host.Name -eq "Package Manager Host")
{
    'Get-ProjectReferencePath', 'Set-ProjectReferencePath' | %{
        Register-TabExpansion $_ @{
            ProjectName = { Get-Project -All | Select -ExpandProperty Name }
        }
    }
}

Export-ModuleMember Get-ProjectReferencePath, Set-ProjectReferencePath
