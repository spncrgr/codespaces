#
# update Windows Preinstallation Environment (WinPE)
#

# Get the list of images contained within WinPE
$WINPE_IMAGES = Get-WindowsImage -ImagePath $MEDIA_NEW_PATH"\sources\boot.wim"

Foreach ($IMAGE in $WINPE_IMAGES) {

# update WinPE
    Write-Output "$(Get-TS): Mounting WinPE, image index $($IMAGE.ImageIndex)"
    Mount-WindowsImage -ImagePath $MEDIA_NEW_PATH"\sources\boot.wim" -Index $IMAGE.ImageIndex -Path $WINPE_MOUNT -ErrorAction stop | Out-Null

# Add servicing stack update (Step 9 from the table)

# Depending on the Windows release that you are updating, there are 2 different approaches for updating the servicing stack
    # The first approach is to use the combined cumulative update. This is for Windows releases that are shipping a combined 
    # cumulative update that includes the servicing stack updates (i.e. SSU + LCU are combined). Windows 11, version 21H2 and 
    # Windows 11, version 22H2 are examples. In these cases, the servicing stack update is not published separately; the combined 
    # cumulative update should be used for this step. However, in hopefully rare cases, there may breaking change in the combined 
    # cumulative update format, that requires a standalone servicing stack update to be published, and installed first before the 
    # combined cumulative update can be installed.

# This is the code to handle the rare case that the SSU is published and required for the combined cumulative update
    # Write-Output "$(Get-TS): Adding package $SSU_PATH"
    # Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $SSU_PATH | Out-Null

# Now, attempt the combined cumulative update.
    # There is a known issue where the servicing stack update is installed, but the cumulative update will fail.
    # This error should be caught and ignored, as the last step will be to apply the cumulative update 
    # (or in this case the combined cumulative update) and thus the image will be left with the correct packages installed.

try
    {
        Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $LCU_PATH | Out-Null  
    }
    Catch
    {
        $theError = $_
        Write-Output "$(Get-TS): $theError"

if ($theError.Exception -like "*0x8007007e*") {
            Write-Output "$(Get-TS): This failure is a known issue with combined cumulative update, we can ignore."
        }
        else {
            throw
        }
    }

# The second approach for Step 9 is for Windows releases that have not adopted the combined cumulative update
    # but instead continue to have a separate servicing stack update published. In this case, we'll install the SSU
    # update. This second approach is commented out below.

# Write-Output "$(Get-TS): Adding package $SSU_PATH"
    # Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $SSU_PATH | Out-Null

# Install lp.cab cab
    Write-Output "$(Get-TS): Adding package $WINPE_OC_LP_PATH"
    Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $WINPE_OC_LP_PATH -ErrorAction stop | Out-Null

# Install language cabs for each optional package installed
    $WINPE_INSTALLED_OC = Get-WindowsPackage -Path $WINPE_MOUNT
    Foreach ($PACKAGE in $WINPE_INSTALLED_OC) {

if ( ($PACKAGE.PackageState -eq "Installed") -and ($PACKAGE.PackageName.startsWith("WinPE-")) -and ($PACKAGE.ReleaseType -eq "FeaturePack") ) {

$INDEX = $PACKAGE.PackageName.IndexOf("-Package")
            if ($INDEX -ge 0) {

$OC_CAB = $PACKAGE.PackageName.Substring(0, $INDEX) + "_" + $LANG + ".cab"
                if ($WINPE_OC_LANG_CABS.Contains($OC_CAB)) {
                    $OC_CAB_PATH = Join-Path $WINPE_OC_LANG_PATH $OC_CAB
                    Write-Output "$(Get-TS): Adding package $OC_CAB_PATH"
                    Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $OC_CAB_PATH -ErrorAction stop | Out-Null  
                }
            }
        }
    }

# Add font support for the new language
    if ( (Test-Path -Path $WINPE_FONT_SUPPORT_PATH) ) {
        Write-Output "$(Get-TS): Adding package $WINPE_FONT_SUPPORT_PATH"
        Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $WINPE_FONT_SUPPORT_PATH -ErrorAction stop | Out-Null
    }

# Add TTS support for the new language
    if (Test-Path -Path $WINPE_SPEECH_TTS_PATH) {
        if ( (Test-Path -Path $WINPE_SPEECH_TTS_LANG_PATH) ) {

Write-Output "$(Get-TS): Adding package $WINPE_SPEECH_TTS_PATH"
            Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $WINPE_SPEECH_TTS_PATH -ErrorAction stop | Out-Null

Write-Output "$(Get-TS): Adding package $WINPE_SPEECH_TTS_LANG_PATH"
            Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $WINPE_SPEECH_TTS_LANG_PATH -ErrorAction stop | Out-Null
        }
    }

# Generates a new Lang.ini file which is used to define the language packs inside the image
    if ( (Test-Path -Path $WINPE_MOUNT"\sources\lang.ini") ) {
        Write-Output "$(Get-TS): Updating lang.ini"
        DISM /image:$WINPE_MOUNT /Gen-LangINI /distribution:$WINPE_MOUNT | Out-Null
    }

# Add latest cumulative update
    Write-Output "$(Get-TS): Adding package $LCU_PATH"
    Add-WindowsPackage -Path $WINPE_MOUNT -PackagePath $LCU_PATH -ErrorAction stop | Out-Null

# Perform image cleanup
    Write-Output "$(Get-TS): Performing image cleanup on WinPE"
    DISM /image:$WINPE_MOUNT /cleanup-image /StartComponentCleanup /ResetBase /Defer | Out-Null

if ($IMAGE.ImageIndex -eq "2") {

# Save setup.exe for later use. This will address possible binary mismatch with the version in the main OS \sources folder
        Copy-Item -Path $WINPE_MOUNT"\sources\setup.exe" -Destination $WORKING_PATH"\setup.exe" -Force -ErrorAction stop | Out-Null
        
        # Save serviced boot manager files later copy to the root media.
        Copy-Item -Path $WINPE_MOUNT"\Windows\boot\efi\bootmgfw.efi" -Destination $WORKING_PATH"\bootmgfw.efi" -Force -ErrorAction stop | Out-Null
        Copy-Item -Path $WINPE_MOUNT"\Windows\boot\efi\bootmgr.efi" -Destination $WORKING_PATH"\bootmgr.efi" -Force -ErrorAction stop | Out-Null
    
    }
        
    # Dismount
    Dismount-WindowsImage -Path $WINPE_MOUNT -Save -ErrorAction stop | Out-Null

#Export WinPE
    Write-Output "$(Get-TS): Exporting image to $WORKING_PATH\boot2.wim"
    Export-WindowsImage -SourceImagePath $MEDIA_NEW_PATH"\sources\boot.wim" -SourceIndex $IMAGE.ImageIndex -DestinationImagePath $WORKING_PATH"\boot2.wim" -ErrorAction stop | Out-Null

}

Move-Item -Path $WORKING_PATH"\boot2.wim" -Destination $MEDIA_NEW_PATH"\sources\boot.wim" -Force -ErrorAction stop | Out-Null