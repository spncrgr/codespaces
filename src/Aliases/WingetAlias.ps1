# Set WinGet aliases if winget is installed
$wingetPath = Get-Command -Name winget -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if ($wingetPath) {
    Set-Alias -Name wg -Value winget-command
    Set-Alias -Name wi -Value winget-install
    Set-Alias -Name winst -Value winget-install
    Set-Alias -Name wl -Value winget-list
    Set-Alias -Name wlist -Value winget-list
    Set-Alias -Name ws -Value winget-search
    Set-Alias -Name wsh -Value winget-show
    Set-Alias -Name wu -Value winget-uninstall
    Set-Alias -Name wset -Value winget-settings
    Set-Alias -Name wup -Value winget-upgrade
}
