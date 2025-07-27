# docker
$dockerPath = Get-Command -Name docker -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if ($dockerPath) {
    Set-Alias -Name di -Value docker-image
    Set-Alias -Name dils -Value docker-images
    Set-Alias -Name dirm -Value docker-image-remove
    Set-Alias -Name dc -Value docker-container
    Set-Alias -Name dcls -Value docker-containers
    Set-Alias -Name dcrm -Value docker-container-remove
    Set-Alias -Name dp -Value docker-pull
    Set-Alias -Name db -Value docker-build
    Set-Alias -Name dr -Value docker-run
}