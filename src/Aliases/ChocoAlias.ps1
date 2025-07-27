# docker
$chocoPath = Get-Command -Name choco -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if ($chocoPath) {
    Set-Alias -Name cinst -Value choco-install
    Set-Alias -Name clist -Value choco-list
    Set-Alias -Name csearch -Value choco-search
    Set-Alias -Name cinfo -Value choco-info
    Set-Alias -Name cu -Value choco-uninstall
    Set-Alias -Name cup -Value choco-upgrade
    Set-Alias -Name cupl -Value choco-upgrade-list
    Set-Alias -Name cuppa -Value choco-upgrade-all
	Set-Alias -Name cf -Value choco-feature
	Set-Alias -Name cfe -Value choco-feature-enable
}