# Unity3D.DLLs

[NuGet][2] package for managing assembly references to installed [Unity3D][3] DLLs.

Copyright (c) 2013 [Precision Mojo, LLC][1] and [Contributors](CONTRIBUTORS.md).

The Unity3D.DLLs project is distributed under the [MIT License](LICENSE.MIT.md).

[1]: http://www.precisionmojo.com/
[2]: https://www.nuget.org/
[3]: http://unity3d.com/

## Overview

The Unity3D.DLLs NuGet package provides a convenient way for developers to collaborate on projects that reference Unity3D
managed assemblies. These projects include Unity3D plugins and editor extensions which usually depend on the UnityEngine and
UnityEditor assemblies that are installed with Unity3D. Instead of requiring developers to manually add or update
references to these assemblies, the Unity3D.DLLs package will automatically detect the location of the installed Unity3D
assemblies, add them to a project, and ensure that they are found when the project is built. By using the NuGet [Package
Restore](#package-restore) feature in combination with the Unity3D.DLLs package, projects that are distributed to other
developers are guaranteed to build without modification.

The Unity3D.DLLs package also adds [commands](#powershell-commands) to the NuGet Package Manager Console that make it easy
to add, remove, and update references to Unity3D assemblies.

## Installation

Install the Unity3D.DLLs package through the Manage NuGet Packages dialog box or the Package Manager Console.

### Manage NuGet Packages

* Open the Solution Explorer and right click the project where Unity3D.DLLs is to be installed.
* Select the "Manage NuGet Packages..." menu item to open the Manage NuGet Packages dialog box.
* Select the Online category on the left, then type `Unity3D.DLLs` in the "Search Online" text box.
* Locate the Unity3D.DLLs package in the list and click Install.

### Package Manager Console

Open the Package Manager Console, select the desired project from the "Default project:" dropdown, and enter the
following command at the prompt:

    Install-Package Unity3D.DLLs

## Package Restore

The NuGet Package Restore feature can be used to ensure that the source to a Unity3D plugin or extension project will build
out-of-the-box when distributed to other developers across an organization or the Internet. The only requirement for a
developer receiving a project with Package Restore enabled is a valid Unity3D installation.

To enable Package Restore for your solution follow the instructions given
[here](https://docs.nuget.org/docs/workflows/using-nuget-without-committing-packages). Note that Automatic Package Restore
is enabled by default in NuGet 2.7 and later.

***IMPORTANT***
If your project is under source control, under no circumstances should you ever check in your **packages** folder! The
**packages** folder contains package metadata, assemblies, and other files for all installed packages. These files don't
need to be stored under source control because they are installed during the Package Restore process. For a detailed
explaination of Package Restore refer to the [NuGet documentation](http://docs.nuget.org/docs/reference/package-restore).

## PowerShell Commands

The Unity3D.DLLs package comes with a PowerShell module that contains several useful commands that can be used within the
Package Manage Console. Here is a brief synopsis of the available commands, for detailed information, use the `Get-Help`
command:

    Get-Help Add-Unity3DReference -Detailed

### Add-Unity3DReference

    Add-Unity3DReference [[-AssemblyName] <String>] [[-ProjectName] <String[]>] [<CommonParameters>]

Adds an assembly reference to a Unity3D managed DLL.

### Remove-Unity3DReference

    Remove-Unity3DReference [-ReferenceName] <String> [[-ProjectName] <String[]>] [<CommonParameters>]

Removes a Unity 3D assembly reference from a project.

### Update-Unity3DReferences

    Update-Unity3DReferences [[-ProjectName] <String[]>] [<CommonParameters>]

Updates assembly references to Unity 3D managed DLLs.

### Get-Unity3DEditorPath

    Get-Unity3DEditorPath [<CommonParameters>]

Returns the path to the Unity 3D editor application.

### Get-Unity3DProjectProperties

    Get-Unity3DProjectProperties [-ProjectName] <String> [<CommonParameters>]

Returns a hashtable with the Unity3D.DLLs properties collected for the specified project.

## Todo

* Test / get working in MonoDevelop.
* Test / get working in Xamarin Studio.
* Test / get working on OSX.

## About

The Unity3D.DLLs project was created by [Precision Mojo][1] for the benefit of the Unity3D development community. It is
currently maintained by [Marcus R. Brown](https://github.com/igetgames)
([@igetgames](https://twitter.com/#!/igetgames) on Twitter). Send feedback to unity3d.dlls@precisionmojo.com.
