# Sets the PROCESSOR_ARCHITECTURE according to native platform.
if ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
    # Set the "right" processor architecture
    if ($env:PROCESSOR_ARCHITEW6432 -ne "") {
        $env:PROCESSOR_ARCHITECTURE = $env:PROCESSOR_ARCHITEW6432
    }
}
elseif ($env:PROCESSOR_ARCHITECTURE -eq "arm") {
    # Set the "right" processor architecture
    if ($env:PROCESSOR_ARCHITEW6432 -ne "") {
        $env:PROCESSOR_ARCHITECTURE = $env:PROCESSOR_ARCHITEW6432
    }
}
elseif ($env:PROCESSOR_ARCHITECTURE -eq "amd64" -or $env:PROCESSOR_ARCHITECTURE -eq "arm64") {
    # Nothing to do
}
else {
    Write-Host "Not implemented for PROCESSOR_ARCHITECTURE of $($env:PROCESSOR_ARCHITECTURE)."
    return
}

# Query the 32-bit and 64-bit Registry hive for KitsRoot
$regKeyPathFound = $true
$wowRegKeyPathFound = $true
$KitsRootRegValueName = "KitsRoot10"

if (!(Test-Path "HKLM:\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" -ErrorAction SilentlyContinue)) {
    $wowRegKeyPathFound = $false
}
if (!(Test-Path "HKLM:\Software\Microsoft\Windows Kits\Installed Roots" -ErrorAction SilentlyContinue)) {
    $regKeyPathFound = $false
}

if (-not $wowRegKeyPathFound) {
    if (-not $regKeyPathFound) {
        Write-Host "KitsRoot not found, can't set common path for Deployment Tools"
        return
    }
    else {
        $regKeyPath = "HKLM:\Software\Microsoft\Windows Kits\Installed Roots"
    }
}
else {
    $regKeyPath = "HKLM:\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots"
}

$KitsRoot = Get-ItemPropertyValue -Path $regKeyPath -Name $KitsRootRegValueName

# Build the D&I Root from the queried KitsRoot
$DandIRoot = Join-Path $KitsRoot "Assessment and Deployment Kit\Deployment Tools"

# Construct the path to WinPE directory, architecture-independent
$WinPERoot = Join-Path $KitsRoot "Assessment and Deployment Kit\Windows Preinstallation Environment"
$WinPERootNoArch = Join-Path $KitsRoot "Assessment and Deployment Kit\Windows Preinstallation Environment"

# Construct the path to DISM, Setup and USMT, architecture-independent
$WindowsSetupRootNoArch = Join-Path $KitsRoot "Assessment and Deployment Kit\Windows Setup"
$USMTRootNoArch = Join-Path $KitsRoot "Assessment and Deployment Kit\User State Migration Tool"

# Constructing tools paths relevant to the current Processor Architecture
$DISMRoot = Join-Path $DandIRoot $env:PROCESSOR_ARCHITECTURE "DISM"
$BCDBootRoot = Join-Path $DandIRoot $env:PROCESSOR_ARCHITECTURE "BCDBoot"
$ImagingRoot = Join-Path $DandIRoot $env:PROCESSOR_ARCHITECTURE "Imaging"
$OSCDImgRoot = Join-Path $DandIRoot $env:PROCESSOR_ARCHITECTURE "Oscdimg"
$WdsmcastRoot = Join-Path $DandIRoot $env:PROCESSOR_ARCHITECTURE "Wdsmcast"

# Now do the paths that apply to all architectures...
# Note that the last one in this list should not have a trailing semi-colon to avoid duplicate semi-colons on the last entry when the final path is assembled.
$HelpIndexerRoot = Join-Path $DandIRoot "HelpIndexer"

# Set WSIMRoot. WSIM is x86 only
$WSIMRoot = Join-Path $DandIRoot "WSIM\x86"

# Set ICDRoot. ICD is x86 only
$ICDRoot = Join-Path $KitsRoot "Assessment and Deployment Kit\Imaging and Configuration Designer\x86"

# Now build the master path from the various tool root folders...
# Note that each fragment above should have any required trailing semi-colon as a delimiter so we do not put any here.
# Note the last one appended to $NewPath should be the last one set above in the arch. neutral section which also should not have a trailing semi-colon.
$NewPath = "$DISMRoot;$ImagingRoot;$BCDBootRoot;$OSCDImgRoot;$WdsmcastRoot;$HelpIndexerRoot;$WSIMRoot;$WinPERoot;$ICDRoot"

$env:PATH = $NewPath + ";" + $env:PATH

# Set current directory to DandIRoot
Set-Location -Path $DandIRoot

# Run WimMountAdkSetup to install the wimmount.sys and wofadk.sys file system filter drivers.
$WimMountAdkSetup = Join-Path $DISMRoot "WimMountAdkSetup$($env:PROCESSOR_ARCHITECTURE).exe"
& $WimMountAdkSetup /q /install /driverfile="$DISMRoot\wimmount.sys" /driverfile="$DISMRoot\wofadk.sys"