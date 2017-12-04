<#
Unity3DExtensions.psm1 - PowerShell module for locating and loading Unity 3D extensions.

Copyright (c) 2017 Marcus R. Brown <me@igetgam.es>

This file is part of the Unity3D.DLLs project (http://precisionmojo.github.io/Unity3D.DLLs/) which is distributed
under the MIT License. Refer to the LICENSE.MIT.md document located in the project directory for licensing terms.
#>

$ivyParserPath = $null

$parseFileMethod = $null

function Set-IvyParserPath
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String] $Path
    )

    $script:ivyParserPath = $Path
}

function Get-IvyModule
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String] $ModulePath
    )

    ParseIvyModule($ModulePath)
}

function ParseIvyModule([string] $ModulePath)
{
    if ($script:parseFileMethod -eq $null)
    {
        EnsureUnityIvyParserAssembly
        $script:parseFileMethod = [Unity.PackageManager.Ivy.IvyParser].GetMethod("ParseFile").MakeGenericMethod([Unity.PackageManager.Ivy.IvyModule])
    }

    $script:parseFileMethod.Invoke($null, $ModulePath)
}

function EnsureUnityIvyParserAssembly
{
    if (([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_ -match "Unity.IvyParser" }) -eq $null)
    {
        Add-Type -Path $ivyParserPath
    }
}
