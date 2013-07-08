param($installPath, $toolsPath, $package, $project)

# Remove the sentinel file used to ensure that the package is installed per project.
# From http://danlimerick.wordpress.com/2011/10/01/getting-around-nugets-external-package-dependency-problem/
$project.ProjectItems | ForEach { if ($_.Name -eq "8CFAF032-C5F2-49A3-B8F6-07EF68F4623D.txt") { $_.Remove() } }
$projectPath = Split-Path $project.FullName -Parent
Join-Path $projectPath "8CFAF032-C5F2-49A3-B8F6-07EF68F4623D.txt" | Remove-Item

# Update Unity 3D references.
$project | Update-Unity3DReferences
