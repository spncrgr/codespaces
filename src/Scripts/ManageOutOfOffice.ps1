# Function to view existing out of office settings
function Get-OutOfOfficeSettings {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Mailboxes
    )

    foreach ($mailbox in $Mailboxes) {
        # Get the auto reply configuration for the mailbox
        $autoReplyConfig = Get-MailboxAutoReplyConfiguration -Identity $mailbox

        # Display the auto reply settings
        Write-Host "Auto Reply Settings for ${mailbox}:"
        Write-Host "Enabled: $($autoReplyConfig.AutoReplyState)"
        Write-Host "Start Time: $($autoReplyConfig.StartTime)"
        Write-Host "End Time: $($autoReplyConfig.EndTime)"
        Write-Host "External Message: $($autoReplyConfig.ExternalMessage)"
        Write-Host "Internal Message: $($autoReplyConfig.InternalMessage)"
        Write-Host ""
    }
}

# Function to set up or edit the auto reply
function Set-OutOfOfficeSettings {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Mailboxes,
        [Parameter(Mandatory = $true)]
        [string]$ExternalMessage,
        [Parameter(Mandatory = $true)]
        [string]$InternalMessage,
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate
    )

    # Set the auto reply configuration for each mailbox
    foreach ($mailbox in $Mailboxes) {
        Write-Host "Setting auto reply for ${mailbox}..."
        Set-MailboxAutoReplyConfiguration -Identity $mailbox -AutoReplyState Scheduled -ExternalMessage $ExternalMessage -InternalMessage $InternalMessage -StartTime $StartDate -EndTime $EndDate
    }
}

# Function to disable the auto reply
function Disable-OutOfOfficeSettings {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Mailboxes
    )

    foreach ($mailbox in $Mailboxes) {
        # Disable the auto reply for the mailbox
        Write-Host "Disabling auto reply for ${mailbox}..."
        Set-MailboxAutoReplyConfiguration -Identity $mailbox -AutoReplyState Disabled
    }
}
