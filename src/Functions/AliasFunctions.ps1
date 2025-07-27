# Git
function git-checkout { & (Get-Command git).Source checkout $args }
function git-pull { & (Get-Command git).Source pull $args }
function git-push { & (Get-Command git).Source push $args }
function git-merge { & (Get-Command git).Source merge $args }
function git-status { & (Get-Command git).Source status $args }
function git-delete-untracked {
    # Store the location of the git executable
    $gitPath = (Get-Command git).Source
    # Run git fetch with --prune to mark branches that have been deleted on the remote
    & $gitPath fetch --prune
    # Get a list of all branches that have been deleted on the remote
    $deletedBranches = & $gitPath branch -vv | 
    Where-Object { $_ -match ': gone]' } |
    ForEach-Object {
        $_.Trim().Split()[0]
    }
    # If any of the deleted branches have the name '*', write an error message and exit
    if ($deletedBranches -contains '*') {
        Write-Host 'Error: Cannot delete branch named "*". Please ensure you are not on a branch that should be deleted.'
        return
    }

    # If there are any deleted branches, delete them locally
    if ($deletedBranches) {
        foreach ($branch in $deletedBranches) {
            & $gitPath branch -D $branch
        }
    }
    else {
        Write-Host 'No branches to delete.'
    }
}

# Docker
function docker-image { & (Get-Command docker).Source image $args }
function docker-images { & (Get-Command docker).Source image ls $args }
function docker-image-remove { & (Get-Command docker).Source image rm $args }
function docker-container { & (Get-Command docker).Source container $args }
function docker-containers { & (Get-Command docker).Source container ls $args }
function docker-container-remove { & (Get-Command docker).Source container rm $args }
function docker-pull { & (Get-Command docker).Source pull $args }
function docker-build { & (Get-Command docker).Source build $args }
function docker-run { & (Get-Command docker).Source run $args }


# winget 
function winget-command { & (Get-Command winget).Source $args }
function winget-install { & (Get-Command winget).Source install $args }
function winget-list { & (Get-Command winget).Source list $args }
function winget-search { & (Get-Command winget).Source search $args }
function winget-settings { & (Get-Command winget).Source settings $args }
function winget-show { & (Get-Command winget).Source show $args }
function winget-uninstall { & (Get-Command winget).Source uninstall $args }
function winget-upgrade { & (Get-Command winget).Source upgrade $args }


# Chocolatey
function choco-install { & (Get-Command choco).Source install $args }
function choco-list { & (Get-Command choco).Source list $args }
function choco-search { & (Get-Command choco).Source search $args }
function choco-info { & (Get-Command choco).Source info $args }
function choco-uninstall { & (Get-Command choco).Source uninstall $args }
function choco-upgrade { & (Get-Command choco).Source upgrade $args }
function choco-feature { & (Get-Command choco).Source feature $args }
function choco-feature-enable { & (Get-Command choco).Source feature enable -n $args }
function choco-upgrade-all { & (Get-Command choco).Source upgrade all $args }
function choco-upgrade-list { & choco-upgrade-all --noop $args }

# k8s
function oc-config-use-context { & (Get-Command oc).Source config use-context $args }
function oc-login {
    $ocPath = (Get-Command oc).Source
    & (Get-Command oc).Source login $args *>$null
    if (!$?) { 
        Write-Host 'Token Required. Using web authentication...'
        & (Get-Command oc).Source login --web $args
    }
}
function oc-logout { & (Get-Command oc).Source logout $args }
function oc-config-get-contexts { & (Get-Command oc).Source config get-contexts $args }
function oc-config-view { & (Get-Command oc).Source config view }

## Gradle
function gradle-runner {
    $gradlePath = Get-GradlePath
    if ($gradlePath) {
        & $gradlePath $args
    }
    else {
        Write-Host 'Gradle not found. Please ensure it is installed and available in the PATH, or execute this command from a directory containing a gradlew.bat file.'
    }
}

## General Functions
# Utility function for easily creating aliases when PowerShell starts.
# It takes the name of a command (*.exe, *.cmd, *.bat, etc.) and the desired name
# for the alias. It then searches for the command and, if found, creates an alias to it's location
function Set-CommandAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $AliasName,

        [Parameter(Mandatory = $true)]
        [string] $CommandName
    )

    $cmd = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    if ($cmd) {
        # Check if the alias already exists and, if not, create it
        $alias = Get-Alias -Name $AliasName -ErrorAction SilentlyContinue
        if (!$alias) {
            Set-Alias -Name $AliasName -Value $cmd.Source -Scope Global
        }
    }
}

function Get-GradlePath {
    $localGradle = Get-Item -Path '.\gradlew.bat' -ErrorAction SilentlyContinue
    if ($localGradle) {
        return $localGradle.FullName
    }
    else {
        $globalGradle = Get-Command gradle -ErrorAction SilentlyContinue
        if ($globalGradle) {
            return $globalGradle.Source
        }
        else {
            return $null
        }
    }
}