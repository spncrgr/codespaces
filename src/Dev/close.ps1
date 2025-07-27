Push-Location $PSScriptRoot
$exit_code = 0
$script_name = $myinvocation.mycommand.name

# Root folder
$root_dir = "$PSScriptRoot\..\.."
# Log folder
$log_dir = "$root_dir\logs"

$log_file = "$log_dir\$script_name.log"

if(-not (test-path -path $log_dir )) {
    new-item -itemtype directory -path $log_dir
}

Function log {
   Param ([string]$log_string)
   write-host $log_string
   add-content $log_file -value $log_string
}

$appProcessName = ''
Get-ChildItem -Filter "*.json" | ForEach-Object {
   $jsonInfo = (Get-Content $_.fullname | ConvertFrom-Json)
   $appProcessName = $jsonInfo.appProcessName;  
}
Write-Host "AppProcessName:$appProcessName"

# Step 1: Stop the application
# begin section Commands
$PROCESS_NAME = $appProcessName
if (Get-Process -Name $PROCESS_NAME) {
   Log("Stopping $PROCESS_NAME...")
   Stop-Process -Name $PROCESS_NAME
}
# end section Commands


# Step 2: Check application is stopped successfully
# begin section Verify
$appclosed = Get-Process -Name $PROCESS_NAME
if ($appclosed.HasExited) {
   log("close succesful $($appclosed.HasExited)")
}
else {
   log("Error: close failed as $($appclosed.ExitCode)")
   $exit_code = $appclosed.ExitCode
}
# end section Verify

log("close script finished as $exit_code")
Pop-Location
exit $exit_code
