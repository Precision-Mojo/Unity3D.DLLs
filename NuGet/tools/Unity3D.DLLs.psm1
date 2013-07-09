<#
Unity3D.DLLs.psm1 - PowerShell module for using Unity3D.DLLs from the NuGet Package Manager Console.

Copyright (c) 2013 Precision Mojo, LLC.

This file is part of the Unity3D.DLLs project (< URL >) which is distributed under the MIT License.
Refer to the LICENSE.MIT.md document located in the project directory for licensing terms.
#>

$Unity3DProjectPropertyNames = @(
	"Unity3DUseReferencePath"
)

$DefaultUnity3DProjectProperties = @{
	Unity3DUseReferencePath = $true;
}

function Update-Unity3DReferences
{
	param
	(
		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]] $ProjectName
	)

	begin
	{
		$unity3DManagedDlls = GetUnity3DManagedDlls

		if ($unity3DManagedDlls.Length -eq 0)
		{
			Write-Warning "Couldn't get a list of Unity 3D managed DLLs."
			return
		}
	}

	process
	{
		(Get-Projects $ProjectName) | % {
			$projectProperties = $_ | GetUnity3DProjectProperties
			$modified = $false
			$buildProject = $_ | Get-MSBuildProject

			foreach ($item in $buildProject.GetItems("Reference"))
			{
				if ($item.IsImported -or !$unity3DManagedDlls.ContainsKey($item.EvaluatedInclude))
				{
					continue
				}

				$managedDll = $unity3DManagedDlls[$item.EvaluatedInclude]

				if ($projectProperties.Unity3DUseReferencePath)
				{
					$_ | Join-ReferencePath (Split-Path $managedDll)

					# Because we're using the reference path, strip the HintPath metadata.
					# TODO: Should this be an option?
					$item.RemoveMetadata("HintPath") | Out-Null
				}
				else
				{
					$item.SetMetadataValue("HintPath", $managedDll)
				}

				$modified = $true
			}

			if ($modified)
			{
				$_.Save()
			}
		}
	}
}

function Get-Unity3DEditorPath
{
	$InstalledUnity = GetInstalledSoftware32("Unity")

	if ($InstalledUnity -and ($InstalledUnity.DisplayIcon -or $InstalledUnity.UninstallString))
	{
	    if (Test-Path $InstalledUnity.DisplayIcon)
	    {
	        Split-Path $InstalledUnity.DisplayIcon
	    }
	    else
	    {
	        Split-Path $InstalledUnity.UninstallString
	    }
	}
}

function Join-ReferencePath
{
	param
	(
		[Parameter(Mandatory=$true)]
		[String] $Path,
		[Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		[String] $ProjectName
	)

	# Ensure a trailing slash.
	$Path = $Path.TrimEnd("\") + "\"
	$pathProperty = Get-MSBuildProperty "ReferencePath" $ProjectName

	if ($pathProperty)
	{
		# Ensure the added reference path is the first in the list.
		$origReferencePath = $pathProperty.UnevaluatedValue

		if (!$origReferencePath.StartsWith($Path))
		{
			$Path = $Path + ";" + $origReferencePath.Replace($Path, "").TrimEnd(";")
		}
		else
		{
			$Path = $origReferencePath
		}
	}

	Set-MSBuildProperty "ReferencePath" $Path $ProjectName -SpecifyUserProject
}

function GetUnity3DManagedDlls
{
	$Unity3DManagedPath = GetUnity3DManagedPath

	if (!(Test-Path $Unity3DManagedPath))
	{
		Write-Warning "Couldn't locate the path to installed Unity 3D managed DLLs."
		return @()
	}

	$managedDlls = Get-ChildItem (Join-Path $Unity3DManagedPath "*") -Include "Unity*.dll" | % { Join-Path $Unity3DManagedPath $_.Name }
	$unity3dManagedDlls = @{}

	foreach ($dll in $managedDlls)
	{
		$name = $dll | Split-Path -Leaf | % {[System.IO.Path]::GetFileNameWithoutExtension($_) }
		$unity3dManagedDlls[$name] = $dll
	}

	$unity3dManagedDlls
}

function GetUnity3DManagedPath
{
	Join-Path (Get-Unity3DEditorPath) "Data\Managed"
}

function GetUnity3DProjectProperties
{
	param
	(
		[Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		[String] $ProjectName
	)

	$projectProperties = $DefaultUnity3DProjectProperties

	foreach ($name in $Unity3DProjectPropertyNames)
	{
		$property = Get-MSBuildProperty $name $ProjectName

		if ($property)
		{
			$projectProperties[$name] = NormalizePropertyValue($property.EvaluatedValue)
		}
	}

	$projectProperties
}

function NormalizePropertyValue([string] $value)
{
	$value = $value.Trim()

	if ($value -ieq "true")
	{
		return $true
	}
	elseif (($value.Length -eq 0) -or ($value -ieq "false"))
	{
		return $false
	}

	$value
}

function GetInstalledSoftware32([parameter(Mandatory=$true)]$displayName)
{
	if (Test-Path HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\)
	{
	    $UninstallKeys = Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\
	}
	else
	{
	    $UninstallKeys = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\
	}

	$UninstallKeys | Get-ItemProperty | Where-Object -Property DisplayName -EQ $displayName
}

Export-ModuleMember Get-Unity3DEditorPath, Update-Unity3DReferences
