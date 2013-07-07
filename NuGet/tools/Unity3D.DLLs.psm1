$InstalledUnity3DEditorPath = ""

function Get-Unity3DEditorPath
{
	$InstalledUnity = GetInstalledSoftware32("Unity")

	if ($InstalledUnity -and ($InstalledUnity.DisplayIcon -or $InstalledUnity.UninstallString))
	{
	    if (Test-Path $InstalledUnity.DisplayIcon)
	    {
	        $InstalledUnity3DEditorPath = Split-Path $InstalledUnity.DisplayIcon
	    }
	    else
	    {
	        $InstalledUnity3DEditorPath = Split-Path $InstalledUnity.UninstallString
	    }
	}

	$InstalledUnity3DEditorPath
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

Export-ModuleMember @('Get-Unity3DEditorPath') -Variable 'InstalledUnity3DEditorPath'
