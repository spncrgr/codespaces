$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)

&pac complete -s "$($commandAst.ToString())" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -Native -CommandName pac -ScriptBlock $scriptblock
