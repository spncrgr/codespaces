#Requires -RunAsAdministrator

function Get-TS { return "{0:HH:mm:ss}" -f [DateTime]::Now }

Write-Output "$(Get-TS): Starting media refresh"

# Declare Dynamic Update packages
$LCU_PATH        = "C:\MediaRefresh\packages\LCU.msu"
$SETUP_DU_PATH   = "C:\MediaRefresh\packages\Setup_DU.cab"
$SAFE_OS_DU_PATH = "C:\MediaRefresh\packages\SafeOS_DU.cab"
$DOTNET_CU_PATH  = "C:\MediaRefresh\packages\DotNet_CU.msu"

# Declare folders for mounted images and temp files
$MEDIA_OLD_PATH  = "C:\MediaRefresh\oldMedia"
$MEDIA_NEW_PATH  = "C:\MediaRefresh\newMedia"
$WORKING_PATH    = "C:\MediaRefresh\temp"
$MAIN_OS_MOUNT   = "C:\MediaRefresh\temp\MainOSMount"
$WINRE_MOUNT     = "C:\MediaRefresh\temp\WinREMount"
$WINPE_MOUNT     = "C:\MediaRefresh\temp\WinPEMount"

# Mount the Features on Demand ISO
Write-Output "$(Get-TS): Mounting FOD ISO"
$FOD_ISO_DRIVE_LETTER = (Mount-DiskImage -ImagePath $FOD_ISO_PATH -ErrorAction stop | Get-Volume).DriveLetter

# Note: Starting with Windows 11, version 21H2, the correct path for main OS language and optional features
# moved to \LanguagesAndOptionalFeatures instead of the root. For Windows 10, use $FOD_PATH = $FOD_ISO_DRIVE_LETTER + ":\"
$FOD_PATH = $FOD_ISO_DRIVE_LETTER + ":\LanguagesAndOptionalFeatures"

# Declare language related cabs
$WINPE_OC_PATH              = "$FOD_ISO_DRIVE_LETTER`:\Windows Preinstallation Environment\x64\WinPE_OCs"
$WINPE_OC_LANG_PATH         = "$WINPE_OC_PATH\$LANG"
$WINPE_OC_LANG_CABS         = Get-ChildItem $WINPE_OC_LANG_PATH -Name
$WINPE_OC_LP_PATH           = "$WINPE_OC_LANG_PATH\lp.cab"
$WINPE_FONT_SUPPORT_PATH    = "$WINPE_OC_PATH\WinPE-FontSupport-$LANG.cab"
$WINPE_SPEECH_TTS_PATH      = "$WINPE_OC_PATH\WinPE-Speech-TTS.cab"
$WINPE_SPEECH_TTS_LANG_PATH = "$WINPE_OC_PATH\WinPE-Speech-TTS-$LANG.cab"
$OS_LP_PATH                 = "$FOD_PATH\Microsoft-Windows-Client-Language-Pack_x64_$LANG.cab"

# Create folders for mounting images and storing temporary files
New-Item -ItemType directory -Path $WORKING_PATH -ErrorAction Stop | Out-Null
New-Item -ItemType directory -Path $MAIN_OS_MOUNT -ErrorAction stop | Out-Null
New-Item -ItemType directory -Path $WINRE_MOUNT -ErrorAction stop | Out-Null
New-Item -ItemType directory -Path $WINPE_MOUNT -ErrorAction stop | Out-Null

# Keep the original media, make a copy of it for the new, updated media.
Write-Output "$(Get-TS): Copying original media to new media path"
Copy-Item -Path $MEDIA_OLD_PATH"\*" -Destination $MEDIA_NEW_PATH -Force -Recurse -ErrorAction stop | Out-Null
Get-ChildItem -Path $MEDIA_NEW_PATH -Recurse | Where-Object { -not $_.PSIsContainer -and $_.IsReadOnly } | ForEach-Object { $_.IsReadOnly = $false }