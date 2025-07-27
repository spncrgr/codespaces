<#
.SYNOPSIS
    Create a new WinPE directory at a given path.
.DESCRIPTION
    This function will create a new WinPE directory at the default path, or a custom path, if provided.
    If the directory already exists, it will be deleted and recreated.

    Original script by Johan Arwidmark, DeploymentResearch.com

    Disclaimer: This script is provided "AS IS" with no warranties, confers no rights and
    is not supported by the author or HomeSource.
.EXAMPLE
    Add-WinPEPowerShell
.EXAMPLE
    Add-WinPEPowerShell -PSEdition Desktop
.PARAMETER PathToSource
    The path to the zip file containing the PowerShell source files.
.PARAMETER WinPEPath
    The path where the WinPE directory exists. Default is "C:\WinPE_amd64".
.PARAMETER PSEditionToInstall
    The edition of PowerShell to add to the WinPE image. Default is Core.
#>
function Add-PowerShellToWinPE {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PathToSource,

        [Parameter(Mandatory = $false)]
        [string]$WinPEPath = "C:\WinPE_amd64",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Core", "Desktop")]
        [string]$PSEditionToInstall = "Core"
    )

    # Load the Deployment and Imaging Tools Environment if not already loaded
    if ([Environment]::GetEnvironmentVariable("DandIEnvironmentLoaded", "Process") -ne "true") {
        Set-DandIEnvironment
    }

    # DISM EXE (from the ADK)
    $dismExe = Join-Path $env:DISMRoot "dism.exe"
    $OCPath = Join-Path $env:WinPERoot "WinPE_OCs"

    # If the edition is Desktop, write a message that it is not supported yet, then exit
    if ($PSEditionToInstall -eq "Desktop") {
        Write-Warning "Desktop edition of PowerShell is not supported yet."
        return
    }

    # Set variables for the media, mount, and custom folders
    $MediaFolder = Join-Path $WinPEPath "media"
    $MountFolder = Join-Path $WinPEPath "mount"
    $CustomFolder = Join-Path $MediaFolder "custom"

    # Set the variable for the WinPE WIM file
    $WimFile = Join-Path $MediaFolder "sources" "boot.wim"

    # Mount the WinPE image
    Write-Host "Mounting WinPE image..."
    Mount-WindowsImage -ImagePath $WimFile -Path $MountFolder -Index 1

    # Pre-requisite OCs to add
    $OptionalComponents = @(
        "WinPE-WMI",
        "WinPE-NetFx",
        "WinPE-PowerShell"
        "WinPE-Scripting",
        "WinPE-StorageWMI",
        "WinPE-DismCmdlets"
    )

    # Add native WinPE optional components (using ADK version of dism.exe instead of Add-WindowsPackage)
    foreach ($OC in $OptionalComponents) {
        Write-Host "Adding $OC to WinPE image..."
        $args1 = "/Image:`"$MountFolder`" /Add-Package /PackagePath:`"$OCPath\$OC.cab`""
        $args2 = "/Image:`"$MountFolder`" /Add-Package /PackagePath:`"$OCPath\en-us\$OC_en-us.cab`""

        $process1 = Start-Process -FilePath $dismExe -ArgumentList $args1 -NoNewWindow -PassThru -Wait
        if ($process1.ExitCode -ne 0) {
            Write-Error "Failed to add package $OC.cab. Exit code: $($process1.ExitCode)"
            return
        }

        $process2 = Start-Process -FilePath $dismExe -ArgumentList $args2 -NoNewWindow -PassThru -Wait
        if ($process2.ExitCode -ne 0) {
            Write-Error "Failed to add package $OC_en-us.cab. Exit code: $($process2.ExitCode)"
            return
        }
    }

    # Unzip the PowerShell source files to the WinPE Program Files folder
    Write-Host "Unzipping PowerShell source files to the WinPE Program Files folder..."
    Expand-Archive -Path $PathToSource -Destination "$MountFolder\Program Files\PowerShell\7" -Force

    # Update the offline environment PATH for PowerShell 7
    Write-Host "Updating the offline environment PATH for PowerShell 7..."
    $HivePath = "$MountFolder\Windows\System32\config\SYSTEM"
    reg load "HKLM\OfflineWinPE" $HivePath
    Start-Sleep -Seconds 5

    # Add PowerShell 7 Paths to Path and PSModulePath environment variables
    $RegistryKey = "HKLM:\OfflineWinPE\ControlSet001\Control\Session Manager\Environment"
    $CurrentPathVar = (Get-Item -Path $RegistryKey).GetValue("Path", "", "DoNotExpandEnvironmentNames")
    $NewPath = $CurrentPathVar + ";%ProgramFiles%\PowerShell\7\"
    New-ItemProperty -Path $RegistryKey -Name "Path" -Value $NewPath -PropertyType ExpandString -Force

    $CurrentPSModulePathVar = (Get-Item -Path $RegistryKey).GetValue("PSModulePath", "", "DoNotExpandEnvironmentNames")
    $NewPSModulePath = $CurrentPSModulePathVar + ";%ProgramFiles%\PowerShell\;%ProgramFiles%\PowerShell\7\;%SystemRoot%\system32\config\systemprofile\Documents\PowerShell\Modules\"
    # Prepend the custom modules directory to the PSModulePath
    $NewPSModulePath = "$CustomFolder\PowerShell\CustomModules" + ";" + $NewPSModulePath
    New-ItemProperty -Path $RegistryKey -Name "PSModulePath" -Value $NewPSModulePath -PropertyType ExpandString -Force

    # Add additional environment variables for PowerShell Gallery Support
    $APPDATA = "%SystemRoot%\System32\Config\SystemProfile\AppData\Roaming"
    New-ItemProperty -Path $RegistryKey -Name "APPDATA" -Value $APPDATA -PropertyType String -Force

    $HOMEDRIVE = "%SystemDrive%"
    New-ItemProperty -Path $RegistryKey -Name "HOMEDRIVE" -Value $HOMEDRIVE -PropertyType String -Force

    $HOMEPATH = "%SystemRoot%\System32\Config\SystemProfile"
    New-ItemProperty -Path $RegistryKey -Name "HOMEPATH" -Value $HOMEPATH -PropertyType String -Force

    $LOCALAPPDATA = "%SystemRoot%\System32\Config\SystemProfile\AppData\Local"
    New-ItemProperty -Path $RegistryKey -Name "LOCALAPPDATA" -Value $LOCALAPPDATA -PropertyType String -Force

    # Cleanup (to prevent errors when unloading the registry hive)
    Get-Variable RegistryKey | Remove-Variable
    Get-Variable CurrentPathVar | Remove-Variable
    Get-Variable $CurrentPSModulePathVar | Remove-Variable
    [gc]::collect()
    Start-Sleep -Seconds 5

    # Unload the registry hive
    reg unload "HKLM\OfflineWinPE"

    # Write winpeshl.ini that launches PowerShell 7
    Write-Host "Setting PowerShell Core to load automatically in WinPE..."
    @'
[LaunchApps]
%WINDIR%\System32\wpeinit.exe
%ProgramFiles%\PowerShell\7\pwsh.exe
'@ | Out-File "$MountFolder\Windows\System32\winpeshl.ini" -Force

    # Write unattend.xml file to change screen resolution
    @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <Display>
                <ColorDepth>32</ColorDepth>
                <HorizontalResolution>1280</HorizontalResolution>
                <RefreshRate>60</RefreshRate>
                <VerticalResolution>720</VerticalResolution>
            </Display>
        </component>
    </settings>
</unattend>
'@ | Out-File "$MountFolder\Unattend.xml" -Encoding utf8 -Force

    # Unmount the WinPE image
    Write-Host "Unmounting WinPE image..."
    Dismount-WindowsImage -Path $MountFolder -Save

    Write-Host "PowerShell 7 has been added to the WinPE image."
}