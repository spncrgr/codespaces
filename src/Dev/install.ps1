Push-Location $PSScriptRoot
$exit_code = 0
$script_name = $myinvocation.mycommand.name
# Root folder
$root_dir = "$PSScriptRoot\..\.."
# Bin folder
$bin_dir = "$root_dir\bin"
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

$msiName=''
$appProcessName=''
Get-ChildItem -Filter "*.json" | ForEach-Object {
   $jsonInfo = (Get-Content $_.fullname | ConvertFrom-Json)
   $msiName     = $jsonInfo.msiName; 
   $appProcessName = $jsonInfo.appProcessName;  
}
Write-Host "msiName:$msiName"
Write-Host "AppProcessName:$appProcessName"

# Step 1: Install the application
# begin section Commands
# Call install commands, if the application has dependencies, install them in proper order as well
log("Installing Application")
# Change the current location
Push-Location $bin_dir
if ([Environment]::Is64BitProcess) {
    $installer_name = $msiName
}
else {
    $installer_name = $msiName
}
$arguments = "/i "+$installer_name+" /quiet /L*v "+"$log_dir"+"\$appProcessName-installation.log"
$installer = Start-Process msiexec.exe $arguments -wait -passthru
Pop-Location
# end section Commands

Start-Sleep -Seconds 3

# Step 2: Check if installation is succeeded
# begin section Verify
# Examples of common commands
#    - Check install process exit code: $installer.exitcode -eq 0
#    - Check registy: Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion
#    - Check installed software list: Get-WmiObject -Class Win32_Product | where name -eq "Node.js"
if ($installer.exitcode -eq 0) {
    Log("Installation succesful as $($installer.exitcode)")
}
else {
    Log("Error: Installation failed as $($installer.exitcode)")
    $exit_code = $installer.exitcode
}

Log("Installation script finished as $exit_code")
Pop-Location
exit $exit_code
