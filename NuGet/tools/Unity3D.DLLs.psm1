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
		$Unity3DManagedDllNames = GetUnity3DManagedDllNames

		if (($Unity3DManagedDllNames -isnot [array]) -or ($Unity3DManagedDllNames.Length -eq 0))
		{
			Write-Warning "Couldn't get a list of Unity 3D managed DLLs."
			return
		}
	}

	process
	{
		(Get-Projects $ProjectName) | % {
			$buildProject = $_ | Get-MSBuildProject
			$projectProperties = $_ | GetUnity3DProjectProperties

			foreach ($itemGroup in $buildProject.Xml.ItemGroups)
			{
				foreach ($item in $itemGroup.Items)
				{
					if (($item.ItemType -eq "Reference") -and ($Unity3DManagedDllNames -contains $item.Include))
					{
						Write-Host $item.Include "(" ($item.Metadata | % { $_.Name + '="' + $_.Value + '",' }) ")"
					}
				}
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

function GetUnity3DManagedDllNames
{
	GetUnity3DManagedDlls | Split-Path -Leaf | % {[System.IO.Path]::GetFileNameWithoutExtension($_) }
}

function GetUnity3DManagedDlls
{
	$InstalledUnity3DEditorPath = Get-Unity3DEditorPath
	$Unity3DManagedPath = Join-Path $InstalledUnity3DEditorPath "Data\Managed"

	if (!(Test-Path $Unity3DManagedPath))
	{
		Write-Warning "Couldn't locate the path to installed Unity 3D managed DLLs."
		return @()
	}

	Get-ChildItem (Join-Path $Unity3DManagedPath "*") -Include "Unity*.dll" | % { Join-Path $Unity3DManagedPath $_.Name }
}

function GetUnity3DProjectProperties
{
	param
	(
		[Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		[String] $ProjectName
	)

	$projectProperties = $DefaultUnity3DProjectProperties
	$buildProject = Get-MSBuildProject $ProjectName

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
