function ConnectToGraph {
    param (
        [string[]]$Scopes = @("User.ReadWrite.All", "Organization.Read.All")
    )

    # Connect to Microsoft Graph if not already connected
    if (-not (Get-Module -ListAvailable -Name "Microsoft.Graph")) {
        Install-Module -Name "Microsoft.Graph" -Force
    }

    # Import the required modules
    Import-Module -Name "Microsoft.Graph"

    # Connect to Microsoft Graph
    Connect-MgGraph -Scopes $Scopes
}

# Function to enable any disabled service plans for all users with SkuPartNumber 'SPE_E5'
function EnableServicePlans {
    param (
        [string]$SkuPartNumber = "SPE_E5"
    )

    # Get an instance of the specified subscribed SKU
    $sku = Get-MgSubscribedSku -All | Where-Object { $_.SkuPartNumber -eq $SkuPartNumber }

    # Get all users with the specified SKU part number
    $users = Get-MgUser -Filter "assignedLicenses/any(a:a/skuId eq $([Guid]$sku.SkuId))" -All | Sort-Object -Property UserPrincipalName

    # Create a common object to store the argument to the AddLicenses parameter
    $addLicenses = @(
        @{
            SkuId = $sku.SkuId
            DisabledPlans = @{}
        }
    )

    # Enable any disabled service plans for each user
    foreach ($user in $users) {
        # Get the user's license details
        $licenseDetails = Get-MgUserLicenseDetail -UserId $user.Id

        # Get the license details for the specified SKU
        $licenseDetail = $licenseDetails | Where-Object { $_.SkuPartNumber -eq $SkuPartNumber }

        # Update the license if there are any disabled service plans
        if ($licenseDetail.ServicePlans.ProvisioningStatus -contains 'Disabled') {
            Write-Host "Enabling service plans for $($user.UserPrincipalName)..."
            Set-MgUserLicense -UserId $user.Id -AddLicenses $addLicenses -RemoveLicenses @()
        }

        # Enable any disabled service plans
        # foreach ($servicePlan in $licenseDetail.ServicePlans) {
        #     if (-not $servicePlan.ProvisioningStatus) {
        #         Write-Host "Enabling service plan $($servicePlan.ServicePlanName) for $($user.UserPrincipalName)..."
        #         Set-MgUserLicense -UserId $user.Id -AddLicenses $addLicenses -RemoveLicenses @() -WhatIf
        #     }
        # }
    }
}

# Call the function to connect to Microsoft Graph
# ConnectToGraph

# Call the function to enable any disabled service plans for the specified SKU
# EnableServicePlans -SkuPartNumber "SPE_E5"


