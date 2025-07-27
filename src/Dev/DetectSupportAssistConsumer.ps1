<#
Return Codes:
Exit 0: SupportAssist Consumer is not detected
Exit 1: SupportAssist Consumer is detected - Remediation neeeded
#>

$ProgressPreference = "SilentlyContinue"

# Define the name of the application
$AppName = "Detect SupportAssist for Home PCs"
New-EventLog -LogName Application -Source $AppName -ErrorAction SilentlyContinue

try {
    $results = @(Get-ItemProperty -Path HKLM:\SOFTWARE\DELL\SupportAssistAgent -ErrorAction SilentlyContinue | Where-Object { $_.Type -eq "Consumer" } )
    if (($results -ne $null)) {
        Write-EventLog -LogName Application -Source $AppName -EntryType Information -EventID 0 -Message "SupportAssist for Home PCs was detected. Remediation is needed."
        [System.Environment]::Exit(1)
    }
    else {
        Write-Host "SupportAssist Consumer is not detected"
        Write-EventLog -LogName Application -Source $AppName -EntryType Information -EventID 0 -Message "SupportAssist for Home PCs was not detected"
        [System.Environment]::Exit(0)
    }
}
catch {
    $errMsg = $_.Exception.Message
    Write-EventLog -LogName Application -Source $AppName -EntryType Error -EventID 1 -Message "Detection failed: $errMsg"
    [System.Environment]::Exit(1)
}
