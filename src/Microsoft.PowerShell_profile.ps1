# In a standard PS Core session, this file is referenced by the following built-in variable:
# $PROFILE
# $PROFILE.CurrentUserCurrentHost

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Add Starship to session
$starshipPath = Get-Command -Name starship -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if ($starshipPath) {
	Invoke-Expression (&starship init powershell) -ErrorAction SilentlyContinue
}

## NPM Settings
$env:NPM_CONFIG_USERCONFIG = 'H:\.npmrc'

## PSReadLine
# Import-Module Az.Tools.Predictor
Set-PSReadLineOption -PredictionSource HistoryAndPlugin

$parameters = @{
  Key = 'Alt+w'
  BriefDescription = 'SaveInHistory'
  LongDescription = 'Save current line in history but do not execute'
  ScriptBlock = {
    param($key, $arg)   # The arguments are ignored in this example

    # GetBufferState gives us the command line (with the cursor position)
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,
      [ref]$cursor)

    # AddToHistory saves the line in history, but does not execute it.
    [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)

    # RevertLine is like pressing Escape.
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
}
}
Set-PSReadLineKeyHandler @parameters

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
. "C:\Users\roachs\OneDrive - Computershare\Documents\PowerShell\gh-copilot.ps1"
