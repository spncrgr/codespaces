# A Function that will parse the arguments and invoke the proper function
function Invoke-BCCL {
       
    # Get and store the location of the Business Central Command Line executable
    $bcclExe = Get-Command bccl.exe | Select-Object -ExpandProperty Source

    # If the exe isn't found, then silently skip this section
    if ($bcclExe) {
        # If the first argument is 'login' or 'logout', then remove it from the '$args' array.
        # Then, run Connect-BCCL or Disconnect-BCCL, respectively, with the remaining arguments
        # Otherwise, run bccl.exe with all of the arguments
        if ($args[0] -eq 'login') {
            Connect-BCCL -BcEnvironment $args[1]
        }
        elseif ($args[0] -eq 'logout') {
            Disconnect-BCCL
        }
        else {
            & $bcclExe $args
        }
    }
}

# This function will set up an OAuth connection to a Business Central tenant
function Connect-BCCL {
    param (
        [Parameter(Mandatory = $true)]
        [string]$BcEnvironment
    )

    Write-Verbose "Requested environment: $BcEnvironment"
    $isTraining = $BcEnvironment -eq 'train'
    $isDevelopment = $BcEnvironment -eq 'dev'
    $isProduction = $BcEnvironment -eq 'prod'
    Write-Verbose  "Recognized?: $isTraining, $isDevelopment, $isProduction"
    $bcEnvironment = ""
    if ($isTraining) {
        Write-Verbose "Connecting to Training..."
        $bcEnvironment = 'Training'
    }
    elseif ($isDevelopment) {
        Write-Verbose "Connecting to Development..."
        $bcEnvironment = 'Development'
    }
    elseif ($isProduction) {
        Write-Verbose "Connecting to Production..."
        $bcEnvironment = 'Production'
    }
    else {
        Write-Verbose "Invalid environment. Please use 'train', 'dev', or 'prod."
    }

    Write-Verbose "Environment is set to $bcEnvironment..."
    Write-Verbose "Args: $args"
    # $command = "https://api.businesscentral.dynamics.com/v2.0/1dff241e-203e-4aa6-be14-60b389b74588/Development/WS/HomeSource%20Operations%2C%20LLC/Codeunit/bccl --auth S2S --tenantid $env:BCCL_TENANT_ID --clientid $env:BCCL_CLIENT_ID --clientsecret $($env:BCCL_CLIENT_SECRET) --remember"
    & (Get-Command bccl).Source -w `
        https://api.businesscentral.dynamics.com/v2.0/1dff241e-203e-4aa6-be14-60b389b74588/$bcEnvironment/WS/HomeSource%20Operations%2C%20LLC/Codeunit/bccl `
        --auth S2S `
        --tenantid $env:BCCL_TENANT_ID `
        --clientid $env:BCCL_CLIENT_ID `
        --clientsecret $($env:BCCL_CLIENT_SECRET) `
        --remember
}

# This function will clear the stored OAuth connection to a Business Central tenant
function Disconnect-BCCL {
    # param(
    #     [Parameter(Mandatory = $true)]
    #     [string]$CommandArgs
    # )

    & (Get-Command bccl).Source --forget
}
