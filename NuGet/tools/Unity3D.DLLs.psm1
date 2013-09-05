<#
Unity3D.DLLs.psm1 - PowerShell module for using Unity3D.DLLs from the NuGet Package Manager Console.

Copyright (c) 2013 Precision Mojo, LLC.

This file is part of the Unity3D.DLLs project (http://precisionmojo.github.io/Unity3D.DLLs/) which is distributed
under the MIT License. Refer to the LICENSE.MIT.md document located in the project directory for licensing terms.
#>

$Unity3DProjectPropertyNames = @(
	"Unity3DUseReferencePath",
	"Unity3DSkipAutoUpdate"
)

$DefaultUnity3DProjectProperties = @{
	Unity3DUseReferencePath = $true;
	Unity3DSkipAutoUpdate = $false;
}

<#
.SYNOPSIS
	Updates assembly references to Unity 3D managed DLLs.

.DESCRIPTION
	Scans each specified project for references to Unity 3D assemblies. For each Unity 3D assembly reference found,
	either the HintPath metadata is updated to point to the DLL found in the active Unity 3D installation, or the
	specified project's ReferencePath MSBuild property is updated with the Unity 3D managed DLL path. The
	Unity3DUseReferencePath project setting is used to determine whether to update the project's ReferencePath property
	or the reference item's HintPath metadata.

.PARAMETER ProjectName
	The name of the project to update. If omitted, then the default project selected in the Package Manager Console
	is used.
#>
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
			$projectProperties = $_ | Get-Unity3DProjectProperties
			$modified = $false
			$buildProject = $_ | Get-MSBuildProject

			foreach ($item in $buildProject.GetItems("Reference"))
			{
				# Keep only the short assembly name, ignoring anything after a comma.
				$AssemblyName = ($item.EvaluatedInclude.ToUpperInvariant() -split ",")[0].Trim()
				if ($item.IsImported -or !$unity3DManagedDlls.ContainsKey($AssemblyName))
				{
					continue
				}

				$managedDll = $unity3DManagedDlls[$AssemblyName]

				if ($projectProperties.Unity3DUseReferencePath)
				{
					$_ | Join-ReferencePath (Split-Path $managedDll)

					# Because we're using the reference path, strip the HintPath metadata.
					# TODO: Should this be an option?
					$item.RemoveMetadata("HintPath") | Out-Null
				}
				else
				{
					$item.SetMetadataValue("HintPath", $managedDll) | Out-Null
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

<#
.SYNOPSIS
	Adds an assembly reference to a Unity3D managed DLL.

.DESCRIPTION
	Adds the specified Unity 3D assembly to the specified project(s). The name of the assembly is the file name of the
	assembly without the extension, e.g. UnityEngine. The list of available assemblies is based on the contents of the
	Unity editor's Managed directory. If an assembly name is passed that doesn't exist in this folder, a warning is
	output before adding the reference.
	
.PARAMETER AssemblyName
	The name of the Unity 3D assembly. If no name is given, UnityEngine is used.
	
.PARAMETER ProjectName
	The name of the project to add a reference to. If omitted, then the default project selected in the Package Manager
	Console is used.
#>
function Add-Unity3DReference
{
	param
	(
		[string] $AssemblyName,
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
		
		if (!$AssemblyName)
		{
			$AssemblyName = "UnityEngine"
		}
		
		$managedDll = $unity3DManagedDlls[$AssemblyName.ToUpperInvariant()]
		
		if (!$managedDll)
		{
			$managedDll = Join-Path (GetUnity3DManagedPath) ($AssemblyName + ".dll")
			Write-Warning "The assembly named `"$AssemblyName`" was not found in the list of Unity 3D managed DLLs."
			Write-Warning "A reference to `"$AssemblyName`" will be added using the path `"$managedDll`"."
		}
	}

	process
	{
		(Get-Projects $ProjectName) | % {
			$projectProperties = $_ | Get-Unity3DProjectProperties

			if ($projectProperties.Unity3DUseReferencePath)
			{
				# If using the reference path, make sure it's up-to-date as adding a reference will attempt to
				# resolve it.
				$_ | Join-ReferencePath (Split-Path $managedDll)
			}

			# Is there already a reference?
			$ProjectName = $_.ProjectName
			$reference = $_.Object.References | Where-Object { $_.Name -eq $AssemblyName }

			if (!$reference)
			{
				$reference = $_.Object.References.Add($managedDll)
				$_.Save()
				$referenceName = $reference.Name
				$referencePath = $reference.Path
				Write-Host "Added a reference to $referenceName ($referencePath) to $ProjectName."
			}
			else
			{
				$referenceName = $reference.Name
				Write-Warning "The project `"$ProjectName`" already contains a reference to `"$referenceName`". Skipping."
			}
		}
	}
}

<#
.SYNOPSIS
	Removes a Unity 3D assembly reference from a project.

.DESCRIPTION
	Removes the specified assembly reference from the specified project(s).

.PARAMETER ReferenceName
	The name of the assembly reference to remove.

.PARAMETER ProjectName
	The name of the project where the reference will be removed. If omitted, then the default project selected in the
	Package Manager Console is used.
#>
function Remove-Unity3DReference
{
	param
	(
        [Parameter(Position=0, Mandatory=$true)]
        [string] $ReferenceName,
        [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
        [string[]] $ProjectName
	)

	process
	{
		(Get-Projects $ProjectName) | %{
			$ProjectName = $_.ProjectName
			$_.Object.References | Where-Object { $_.Name -eq $ReferenceName } | %{
				$_.Remove()
				Write-Host "Removed the reference to $ReferenceName from $ProjectName."
			}

			$_.Save()
		}
	}
}

<#
.SYNOPSIS
	Returns the path to the Unity 3D editor application.

.DESCRIPTION
	Searches the list of installed programs for the active intallation of Unity, and returns the path to the
	directory containing the Unity editor executable.
#>
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

<#
.SYNOPSIS
	Returns a hashtable with the Unity3D.DLLs properties collected for the specified project.

.DESCRIPTION
	Retrieves all project properties used by the Unity3D.DLLs PowerShell commands and returns a hashtable containing
	the name and value of each property.

.PARAMETER ProjectName
	The name of the project to retrieve Unity3D.DLLs properties.
#>
function Get-Unity3DProjectProperties
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

# Joins (prepends) the specified path to the project's ReferencePath MSBuild property.
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
	$origReferencePath = Get-ProjectReferencePath $ProjectName

	if ($origReferencePath)
	{
		# Ensure the added reference path is the first in the list.
		if (!$origReferencePath.StartsWith($Path))
		{
			$Path = $Path + ";" + $origReferencePath.Replace($Path, "")
		}
		else
		{
			$Path = $origReferencePath
		}
	}

	Set-ProjectReferencePath $Path.TrimEnd(";") $ProjectName
}

# Returns a hashtable with the paths of all Unity 3D managed DLLs that start with "Unity".
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
		$unity3dManagedDlls[$name.ToUpperInvariant()] = $dll
	}

	$unity3dManagedDlls
}

function GetUnity3DManagedPath
{
	Join-Path (Get-Unity3DEditorPath) "Data\Managed"
}

# Normalizes property values: converts "true" to $true, "false" or empty strings to $false, and passes everything else.
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

	$UninstallKeys | Get-ItemProperty | Where-Object { $_.DisplayName -eq $displayName }
}

'Update-Unity3DReferences', 'Get-Unity3DProjectProperties' | % {
	Register-TabExpansion $_ @{
		ProjectName = { Get-Project -All | Select -ExpandProperty Name }
	}
}

Register-TabExpansion Add-Unity3DReference @{
	AssemblyName = { (GetUnity3DManagedDlls).GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value | Split-Path -Leaf | % {[System.IO.Path]::GetFileNameWithoutExtension($_) } }
	ProjectName = { Get-Project -All | Select -ExpandProperty Name }
}

Register-TabExpansion Remove-Unity3DReference @{
	ReferenceName = {
		param($context)

		$project = $context.ProjectName | Get-Projects
		$project.Object.References | Sort-Object Name | %{ $_.Name } | Select-Object -Unique
	}
	ProjectName = { Get-Project -All | Select -ExpandProperty Name }
}

Export-ModuleMember Get-Unity3DEditorPath, Update-Unity3DReferences, Add-Unity3DReference, Remove-Unity3DReference, Get-Unity3DProjectProperties
