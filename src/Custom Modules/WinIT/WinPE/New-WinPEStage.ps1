<#
.SYNOPSIS
    Create a new WinPE directory at a given path.
.DESCRIPTION
    This function will create a new WinPE directory at the default path, or a custom path, if provided.
    If the directory already exists, it will be deleted and recreated.

    Disclaimer: This script is provided "AS IS" with no warranties, confers no rights and
    is not supported by the author or HomeSource.
.EXAMPLE
    New-WinPEStage
.EXAMPLE
    New-WinPEStage -Path "C:\WinPE_amd64"
.PARAMETER Path
    The path where the WinPE directory should be created. Default is "C:\WinPE_amd64".
.PARAMETER Architecture
    The architecture of the WinPE directory to create. Default is "amd64".
.PARAMETER IncludeCustomFolder
    Include the custom folder in the WinPE directory. Default is $true.
#>

function New-WinPEStage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path = "C:\WinPE_amd64",
        [Parameter(Mandatory = $false)]
        [string]$Architecture = "amd64",
        [switch]$IncludeCustomFolder
    )

    #Requires -RunAsAdministrator
    
    # Load the Deployment and Imaging Tools Environment
    Set-DandIEnvironment

    Set-Location -Path $env:DandIRoot

    # First, check if the directory already exists and remove it if it does
    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
    }

    # Second, call the New-WinPEMedia function to create the WinPE directory and files
    New-WinPEMedia -Architecture $Architecture -Destination $Path

    # If the -IncludeCustomFolder switch is used, create the custom folder to the WinPE\media directory
    if ($IncludeCustomFolder) {
        $CustomFolder = Join-Path $Path "media\custom"
        New-Item -Path $CustomFolder -ItemType Directory -Force
    }

}
function Set-DandIEnvironment {
    #Requires -RunAsAdministrator

    # Check if the Deployment and Imaging Tools environment is already loaded
    if ($env:DandIEnvironmentLoaded -eq "true") {
        Write-Host "Deployment and Imaging Tools environment is already loaded."
        return
    }

    # Set env variable to indicate the environment is not loaded
    [Environment]::SetEnvironmentVariable("DandIEnvironmentLoaded", "false", "Process")

    Write-Host "Loading the Deployment and Imaging Tools environment into this session..."

    # set $SystemArch according to the architecture of the current system
    # First handle x86
    if ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
        # Set the architecture to $env:PROCESSOR_ARCHITEW6432 if it is not null
        if ($null -ne $env:PROCESSOR_ARCHITEW6432) {
            $SystemArch = $env:PROCESSOR_ARCHITEW6432
        }
        else {
            $SystemArch = $env:PROCESSOR_ARCHITECTURE
        }
    } 
    # Next handle arm
    elseif ($env:PROCESSOR_ARCHITECTURE -eq "arm") {
        # Set the architecture to $env:PROCESSOR_ARCHITEW6432 if it is not null
        if ($null -ne $env:PROCESSOR_ARCHITEW6432) {
            $SystemArch = $env:PROCESSOR_ARCHITEW6432
        }
        else {
            $SystemArch = $env:PROCESSOR_ARCHITECTURE
        }
    }
    # Next handle amd64
    elseif ($env:PROCESSOR_ARCHITECTURE -eq "amd64") {
        $SystemArch = $env:PROCESSOR_ARCHITECTURE
    }
    # Next handle arm64
    elseif ($env:PROCESSOR_ARCHITECTURE -eq "arm64") {
        $SystemArch = $env:PROCESSOR_ARCHITECTURE
    }
    # Finally, stop and raise an error if the architecture is not recognized
    else {
        throw "Unknown architecture: $($env:PROCESSOR_ARCHITECTURE). Please set the SystemArch variable manually."
    }

    Write-Host "System architecture: $SystemArch"

    $RegKeyPath32 = "HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots"
    $RegKeyPath64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots"
    $KitsRootRegValueName = "KitsRoot10"

    # Set $RegKeyPath. Prefer 64-bit registry key if it exists.
    if (Test-Path $RegKeyPath64) {
        $RegKeyPath = $RegKeyPath64
    }
    elseif (Test-Path $RegKeyPath32) {
        $RegKeyPath = $RegKeyPath32
    }
    else {
        throw "Windows ADK not found. Please set the KitsRoot variable manually."
    }

    # Set $KitsRoot to the value of the registry key
    if ($null -ne $RegKeyPath) {
        $KitsRoot = (Get-ItemProperty -Path $RegKeyPath -Name $KitsRootRegValueName).$KitsRootRegValueName
    }

    # Build the D&I Root from the queried KitsRoot
    $DandIRoot = Join-Path $KitsRoot "Assessment and Deployment Kit" "Deployment Tools"

    # Construct the path to WinPE directory, architecture-independent
    $WinPERoot = Join-Path $KitsRoot "Assessment and Deployment Kit" "Windows Preinstallation Environment"
    $WinPeRootNoArch = $WinPERoot

    # Construct the path to Setup and USMT, architecture-independent
    $WindowsSetupRootNoArch = Join-Path $KitsRoot "Assessment and Deployment Kit" "Windows Setup"
    $USMTRootNoArch = Join-Path $KitsRoot "Assessment and Deployment Kit" "User State Migration Tool"

    # Constructing root paths to DISM, BCDBoot, Imaging, OSCDImg, and Wdsmcast relevant to the current Processor Architecture
    $DISMRoot = Join-Path $DandIRoot $SystemArch "DISM"
    $BCDBootRoot = Join-Path $DandIRoot $SystemArch "BCDBoot"
    $ImagingRoot = Join-Path $DandIRoot $SystemArch "Imaging"
    $OSCDImgRoot = Join-Path $DandIRoot $SystemArch "OSCDImg"
    $WdsmcastRoot = Join-Path $DandIRoot $SystemArch "Wdsmcast"

    # Now construct the root paths for HelpIndexer, WSIMRoot (x86 only), and ICDRoot (x86 Only) which are architecture-independent
    $HelpIndexerRoot = Join-Path $DandIRoot "HelpIndexer"
    $WSIMRoot = Join-Path $DandIRoot "WSIM"
    $ICDRoot = Join-Path $KitsRoot "Assessment and Deployment Kit" "Imaging and Configuration Designer"

    # Add all of the root paths to the $env:PATH
    $env:PATH = "$DandIRoot;$DISMRoot;$BCDBootRoot;$ImagingRoot;$OSCDImgRoot;$WdsmcastRoot;$HelpIndexerRoot;$WSIMRoot;$ICDRoot;" + $env:PATH

    # Set environment variables for RegKeyPath, KitsRoot, and SystemArch for this session
    [Environment]::SetEnvironmentVariable("RegKeyPath", $RegKeyPath, "Process")
    [Environment]::SetEnvironmentVariable("KitsRoot", $KitsRoot, "Process")
    [Environment]::SetEnvironmentVariable("SystemArch", $SystemArch, "Process")

    # Set environment variables for the root paths for this session
    [Environment]::SetEnvironmentVariable("DandIRoot", $DandIRoot, "Process")
    [Environment]::SetEnvironmentVariable("WinPERoot", (Join-Path $WinPERoot $SystemArch), "Process")
    [Environment]::SetEnvironmentVariable("WinPeRootNoArch", $WinPeRootNoArch, "Process")
    [Environment]::SetEnvironmentVariable("WindowsSetupRootNoArch", $WindowsSetupRootNoArch, "Process")
    [Environment]::SetEnvironmentVariable("USMTRootNoArch", $USMTRootNoArch, "Process")
    [Environment]::SetEnvironmentVariable("DISMRoot", $DISMRoot, "Process")
    [Environment]::SetEnvironmentVariable("BCDBootRoot", $BCDBootRoot, "Process")
    [Environment]::SetEnvironmentVariable("ImagingRoot", $ImagingRoot, "Process")
    [Environment]::SetEnvironmentVariable("OSCDImgRoot", $OSCDImgRoot, "Process")
    [Environment]::SetEnvironmentVariable("WdsmcastRoot", $WdsmcastRoot, "Process")
    [Environment]::SetEnvironmentVariable("HelpIndexerRoot", $HelpIndexerRoot, "Process")
    [Environment]::SetEnvironmentVariable("WSIMRoot", $WSIMRoot, "Process")
    [Environment]::SetEnvironmentVariable("ICDRoot", $ICDRoot, "Process")

    # Run WimMountAdkSetup to install the wimmount.sys and wofadk.sys file system filter drivers
    $WimMountAdkSetup = Join-Path $DISMRoot "WimMountAdkSetup$SystemArch.exe"
    Start-Process -FilePath $WimMountAdkSetup -ArgumentList "/repair", "/q", "log", "$env:WINDIR\Logs\DISM\WimMountAdkSetup.log" -Wait -NoNewWindow

    # Set env variable to indicate the environment is loaded
    [Environment]::SetEnvironmentVariable("DandIEnvironmentLoaded", "true", "Process")
}


<#
.SYNOPSIS
  Creates working directories for WinPE image customization and media creation.

.DESCRIPTION
  This script copies the necessary boot files and WinPE WIM to the specified working directory for customization and media creation.

.PARAMETER Architecture
  The processor architecture (amd64, x86, arm, arm64).

.PARAMETER Destination
  The destination directory where the working directories will be created.

.EXAMPLE
  .\copype.ps1 -Architecture amd64 -Destination C:\WinPE_amd64
#>

function New-WinPEMedia {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("amd64", "x86", "arm", "arm64")]
        [string]$Architecture,
  
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )
  
    #Requires -RunAsAdministrator

    # Load the Deployment and Imaging Tools Environment
    Set-DandIEnvironment

    $ErrorActionPreference = "Stop"
  
    $TEMPL = "media"
    $FWFILES = "fwfiles"
    $Source = "$env:WinPERoot"
    $FWFilesRoot = "$env:OSCDImgRoot"
    $WIMSourcePath = "$Source\en-us\winpe.wim"
  
    try {
        
        if (-not (Test-Path -Path $Source)) {
            Write-Host "ERROR: The following processor architecture was not found: $Architecture."
            exit 1
        }
  
        if (-not (Test-Path -Path $FWFilesRoot)) {
            Write-Host "ERROR: The following path for firmware files was not found: $FWFilesRoot."
            exit 1
        }
  
        if (-not (Test-Path -Path $WIMSourcePath)) {
            Write-Host "ERROR: WinPE WIM file does not exist: $WIMSourcePath."
            exit 1
        }
  
        if (Test-Path -Path $Destination) {
            Write-Host "ERROR: Destination directory exists: $Destination."
            exit 1
        }
  
        New-Item -ItemType Directory -Path $Destination
        Write-Host
        Write-Host "==================================================="
        Write-Host "Creating Windows PE customization working directory"
        Write-Host
        Write-Host "    $Destination"
        Write-Host "==================================================="
        Write-Host
  
        New-Item -ItemType Directory -Path "$Destination\$TEMPL"
        New-Item -ItemType Directory -Path "$Destination\mount"
        New-Item -ItemType Directory -Path "$Destination\$FWFILES"
  
        Copy-Item -Recurse -Path "$Source\Media" -Destination "$Destination\$TEMPL\"
        New-Item -ItemType Directory -Path "$Destination\$TEMPL\sources"
        Copy-Item -Path $WIMSourcePath -Destination "$Destination\$TEMPL\sources\boot.wim"
  
        Copy-Item -Path "$FWFilesRoot\efisys.bin" -Destination "$Destination\$FWFILES"
        if (Test-Path -Path "$FWFilesRoot\etfsboot.com") {
            Copy-Item -Path "$FWFilesRoot\etfsboot.com" -Destination "$Destination\$FWFILES"
        }
  
        Write-Host
        Write-Host "Success"
        Write-Host
  
    }
    catch {
        Write-Host "Failed!"
        exit 1
    }
}