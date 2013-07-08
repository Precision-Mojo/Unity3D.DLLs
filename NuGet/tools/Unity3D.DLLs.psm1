function Update-Unity3DReferences
{
	param (
		[parameter(Mandatory=$true)]
		$project
	)
	
	$Unity3DManagedDllNames = GetUnity3DManagedDllNames

	if (($Unity3DManagedDllNames -isnot [array]) -or ($Unity3DManagedDllNames.Length -eq 0))
	{
		Write-Warning "Couldn't get a list of Unity 3D managed DLLs."
		return
	}

	foreach ($reference in $project.Object.References)
	{
		if (($reference.Type -eq 0) -and ($Unity3DManagedDllNames -contains $reference.Name))
		{
			Write-Host $reference.Name "(" $reference.Path ") = " $reference.Type
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
