# In a standard PS Core session, this file is referenced by the following built-in variable:
# $PROFILE.CurrentUserAllHosts

## Path Updates

# Add the CustomModules directory to the PSModulePath
$env:PSModulePath += "$PSScriptRoot\CustomModules"

## Imports

Get-ChildItem -Path $PSScriptRoot\Imports\*.ps1 | ForEach-Object { . $_.FullName }
# Source all files in the Functions directory
###### NOTE: The functions must be imported before the aliases ######
Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 | ForEach-Object { . $_.FullName }
# Source all files in the Aliases directory
Get-ChildItem -Path $PSScriptRoot\Aliases\*.ps1 | ForEach-Object { . $_.FullName }
# Source all the files in the Completions directory
Get-ChildItem -Path $PSScriptRoot\Completions\*.ps1 | ForEach-Object { . $_.FullName }
