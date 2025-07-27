# git
$gitPath = Get-Command -Name git -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if ($gitPath) {
    Set-Alias -Name gco -Value git-checkout
    Set-Alias -Name gpl -Value git-pull
    Set-Alias -Name gpu -Value git-push
    Set-Alias -Name gmr -Value git-merge
    Set-Alias -Name gs -Value git-status
    Set-Alias -Name gdu -Value git-delete-untracked
}