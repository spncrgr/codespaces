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

$installedFullPath = ''
$appProcessName = ''
Get-ChildItem -Filter "*.json" | ForEach-Object {
   $jsonInfo = (Get-Content $_.fullname | ConvertFrom-Json)
   $installedFullPath = $jsonInfo.installedFullPath;  
   $appProcessName = $jsonInfo.appProcessName;
}
Write-Host "AppProcessName:$appProcessName"
Write-Host "InstalledPath:$installedFullPath"

# Step 1: Launch the application
# begin section Commands
# For example: Start-Process -FilePath "$env:comspec" -ArgumentList "/c dir `"%systemdrive%\program files`""
log("Launch Application")
# Change the $exePath to your execution path, add -ArgumentList if need.
$exePath = $installedFullPath
Start-Process -FilePath $exePath

Start-Sleep -Seconds 3

# Step 2: Check if the application launched successfully
# begin section Verify
# Examples of common commands
#    - Check if a process existed: Get-Process -Name appName
#    - Check if a window existed: get-process | where {$_.MainWindowTitle -like "*Notepad*"} 
$PROCESS_NAME = $appProcessName
Get-Process | findstr $PROCESS_NAME > $null
if ($? -eq "True") {
   Log("Launch successfully $PROCESS_NAME...")
   $exit_code = 0
}
else {
   Log("Not launched $PROCESS_NAME...")
   $exit_code = 1
}

Log("Launch script finished as $exit_code")
Pop-Location
exit $exit_code
