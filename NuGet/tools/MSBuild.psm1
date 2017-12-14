<#
MSBuild.psm1 - MSBuild utilities.

Copyright (c) 2013 Precision Mojo, LLC.
Copyright (c) 2017 Marcus R. Brown <me@igetgam.es>

This file is part of the Unity3D.DLLs project (http://precisionmojo.github.io/Unity3D.DLLs/) which is distributed
under the MIT License. Refer to the LICENSE.MIT.md document located in the project directory for licensing terms.

Some functions are based on code found in David Fowler's NuGetPowerTools package (https://github.com/davidfowl/NuGetPowerTools).
NuGetPowerTools is licensed under the Apache License 2.0 (https://nuget.codeplex.com/license).
#>

function Get-MSBuildProject
{
	param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]] $ProjectName,
		[switch] $SpecifyUserProject
	)

	process
	{
		(Resolve-ProjectName $ProjectName) | % {
			if ($SpecifyUserProject)
			{
				$path = $_.FullName + ".user"
			}
			else
			{
				$path = $_.FullName
			}

			@([Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.GetLoadedProjects($path))[0]
		}
	}
}

function Get-MSBuildProperty
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)]
		$PropertyName,
		[Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
		[String[]] $ProjectName
	)

	$buildProject = Get-MSBuildProject $ProjectName
	$buildProject.GetProperty($PropertyName)
}

function Set-MSBuildProperty
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)]
		[string] $PropertyName,
		[Parameter(Position=1, Mandatory=$true)]
		[string] $PropertyValue,
		[Parameter(Position=2, ValueFromPipelineByPropertyName=$true)]
		[String[]] $ProjectName,
		[switch] $SpecifyUserProject
	)

	process
	{
		(Resolve-ProjectName $ProjectName) | % {
			$buildProject = $_ | Get-MSBuildProject -SpecifyUserProject:$SpecifyUserProject
			$buildProject.SetProperty($PropertyName, $PropertyValue) | Out-Null
			$_.Save()
		}
	}
}

if ($Host.Name -eq "Package Manager Host")
{
    'Get-MSBuildProject', 'Set-MSBuildProperty' | %{
        Register-TabExpansion $_ @{
            ProjectName = { Get-Project -All | Select -ExpandProperty Name }
        }
    }

    Register-TabExpansion 'Get-MSBuildProperty' @{
        ProjectName = { Get-Project -All | Select -ExpandProperty Name }
        PropertyName = {
            param($context)

            if ($context.ProjectName)
            {
                $buildProject = Get-MSBuildProject $context.ProjectName
            }

            if (!$buildProject)
            {
                $buildProject = Get-MSBuildProject
            }

            $buildProject.Xml.Properties | Sort Name | Select -ExpandProperty Name -Unique
        }
    }
}

Export-ModuleMember Get-MSBuildProject, Get-MSBuildProperty, Set-MSBuildProperty
