param (
    [Parameter(Mandatory=$true)]
    [string]$host,
    [int]$port = 5454,
    [string]$enc_key = "adL0g0nAppPwd_",
    [string]$dirPath = "$HOME/sdptmp",
    [string]$serverUrl = "https://sdpondemand.manageengine.com",
    [bool]$agent = $false,
    [bool]$canUpload = $true,
    [string]$md = "sha256",
    [string]$apiKey = "",
    [string]$customer = "",
    [bool]$verbose = $false,
    [string]$encType = "-aes-256-cbc"
)

if ([string]::IsNullOrEmpty($host)) {
    Write-Host "Usage : scan_script.ps1 <Probe Host> [Port]"
    exit 1
}

$argument = $host
$sw_scan = $false

if ($args -contains "server=" -or $args -contains "serverUrl=") {
    $serverUrl = $args | Where-Object { $_ -like "*server=*" -or $_ -like "*serverUrl=*" } | ForEach-Object { $_.Split("=")[1] }
    Write-Host $serverUrl
}

if ($args -contains "apiKey") {
    $apiKey = $args | Where-Object { $_ -like "*apiKey*" }
    $agent = $true
}

if ($args -contains "sw_scan=") {
    if ($args -contains "true") {
        $sw_scan = $true
    }
}

if ($args -contains "-v") {
    $verbose = $true
}

if ($args -contains "path=") {
    $dirPath = $args | Where-Object { $_ -like "*path=*" } | ForEach-Object { $_.Split("=")[1] + "/sdptmp" }
    Write-Host "dirPath set to [$dirPath]"
}

if ($args -contains "encType=") {
    $encType = $args | Where-Object { $_ -like "*encType=*" } | ForEach-Object { $_.Split("=")[1] }
    Write-Host "Custom encryption used. $encType"
}

if ($args -contains "customerId=") {
    $customer = $args | Where-Object { $_ -like "*customerId=*" }
    Write-Host "Customer $customer"
}

$dirPath = New-Item -ItemType Directory -Path $dirPath -Force
$last_scan = Join-Path $dirPath "last_scan"

if (![string]::IsNullOrEmpty($apiKey)) {
    if (Test-Path $last_scan) {
        $currtime = Get-Date -UFormat "%s"
        $filetime = Get-Date -UFormat "%s" -File $last_scan
        $filetimeplus = $filetime + 300
        if ($currtime -gt $filetimeplus) {
            Write-Host "Scan result xml can be uploaded to server"
        } else {
            Write-Host "Time interval must be 5 minutes to upload scan result"
            $canUpload = $false
        }
    }
    $agent = $true
}

if ($sw_scan -eq $false) {
    $dirPath = New-Item -ItemType Directory -Path $dirPath -Force
    Write-Host "Software scan disabled"
    Set-Content -Path "$dirPath/no_software_scan.txt" -Value "no software scan"
} else {
    Remove-Item -Path "$dirPath/no_software_scan.txt" -Force
    Write-Host "Software Scan enabled"
}

if ($agent -eq $false -and ![string]::IsNullOrEmpty($args[1])) {
    if ($args[1] -notlike "*sw_scan=*" -and $args[1] -notlike "*encType=*") {
        $port = $args[1]
    }
}

function CheckAndDeleteFile($file) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Force
        if ($?) {
            Write-Host "Unable to delete $file. QUITTING"
            exit 1
        }
    }
}

function CheckAndDeleteFiles {
    CheckAndDeleteFile (Join-Path $dirPath "ae_scan.sh")
    CheckAndDeleteFile (Join-Path $dirPath "ae_scan.sh_enc")
    CheckAndDeleteFile (Join-Path $dirPath "scan_result.xml")
    CheckAndDeleteFile (Join-Path $dirPath "scan_result.xml_enc")
    CheckAndDeleteFile (Join-Path $dirPath "scan_result.enc")
}

function DownloadScanScript {
    Write-Host "Going to download scan script from Probe"
    $downloadstr = "1_GET_LIN_SCRIPT"
    $unamestr = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption
    Write-Host $unamestr
    if ($unamestr -eq "Darwin") {
        $downloadstr = "1_GET_MAC_SCRIPT"
    }

    if ($verbose) {
        Write-Host "Going to request data from probe using $encType"
    }
    $dataToSend = $downloadstr | ConvertTo-SecureString -AsPlainText -Force | ConvertTo-Base64String
    Invoke-WebRequest -Uri "http://${host}:${port}" -Method POST -OutFile (Join-Path $dirPath "ae_scan.sh_enc") -Body $dataToSend
    Write-Host "Downloaded scan script"

    if ($verbose) {
        Write-Host "Going to decrypt data from probe using $encType"
    }
    $base64Data = Get-Content (Join-Path $dirPath "ae_scan.sh_enc") -Raw
    $decryptedData = $base64Data | ConvertFrom-Base64String | ConvertTo-SecureString -AsPlainText -Force
    $decryptedData | Out-File -FilePath (Join-Path $dirPath "ae_scan.sh") -Encoding ASCII
    if ($?) {
        Write-Host "Decrypt failed"
        exit 1
    }
    Write-Host "Decrypted scan script"
}

function DownloadScanScriptFromServer {
    Write-Host "Going to download scan script from server"
    $downloadstr = "scanscript/ae_scan.sh"
    $unamestr = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption
    if ($unamestr -eq "Darwin") {
        $downloadstr = "scanscript/mac_ae_scan.sh"
    } elseif ($unamestr -eq "AIX") {
        $downloadstr = "scanscript/aix_ae_scan.sh"
    }
    Write-Host "$serverUrl/$downloadstr"
    Invoke-WebRequest -Uri "$serverUrl/$downloadstr" -OutFile (Join-Path $dirPath "ae_scan.sh") > (Join-Path $dirPath "curlmessage.txt") 2>&1
    if ($?) {
        Write-Host "Successfully downloaded scan script"
    } else {
        Write-Host "Failed to download scan script"
        Get-Content (Join-Path $dirPath "curlmessage.txt")
    }
    Remove-Item -Path (Join-Path $dirPath "curlmessage.txt") -Force
}

function ExecuteScript {
    & (Join-Path $dirPath "ae_scan.sh") $dirPath
}

function UploadScanResult {
    $dataToSend = "1_SCAN_RESULT" | ConvertTo-SecureString -AsPlainText -Force | ConvertTo-Base64String
    $scanResult = Get-Content (Join-Path $dirPath "scan_result.xml") -Raw
    $encryptedScanResult = $scanResult | ConvertTo-SecureString -AsPlainText -Force | ConvertTo-Base64String
    $encryptedData = $dataToSend + $encryptedScanResult
    $encryptedData | Out-File -FilePath (Join-Path $dirPath "scan_result.enc") -Encoding ASCII
    Write-Host "Encrypted scan result"
    
    $encryptedData = Get-Content (Join-Path $dirPath "scan_result.enc") -Raw
    Invoke-WebRequest -Uri "http://${host}:${port}" -Method POST -Body $encryptedData
}

function UploadScanResultToServer {
    $hostfile = $env:COMPUTERNAME
    $unamestr = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption
    if ($unamestr -eq "AIX") {
        Move-Item -Path (Join-Path $dirPath "scan_result.xml") -Destination (Join-Path $dirPath "$hostfile.xml")
    } else {
        Move-Item -Path (Join-Path $dirPath "scan_result.xml") -Destination (Join-Path $dirPath "$hostfile.xml") -Force
    }

    if ($verbose) {
        if (![string]::IsNullOrEmpty($customer)) {
            Invoke-RestMethod -Uri "$serverUrl/agent/upload?$apiKey&$customer" -Method POST -InFile (Join-Path $dirPath "$hostfile.xml") -ContentType "multipart/form-data" -Verbose > (Join-Path $dirPath "curlmessage.txt") 2>&1
        } else {
            Invoke-RestMethod -Uri "$serverUrl/agent/upload?$apiKey" -Method POST -InFile (Join-Path $dirPath "$hostfile.xml") -ContentType "multipart/form-data" -Verbose > (Join-Path $dirPath "curlmessage.txt") 2>&1
        }
        if ($?) {
            Write-Host "Successfully uploaded scan result to server"
            New-Item -ItemType File -Path $last_scan -Force
        } else {
            Write-Host "Problem while uploading to server"
        }
        Get-Content (Join-Path $dirPath "curlmessage.txt")
        Remove-Item -Path (Join-Path $dirPath "curlmessage.txt") -Force
    } else {
        if (![string]::IsNullOrEmpty($customer)) {
            $response = Invoke-RestMethod -Uri "$serverUrl/agent/upload?$apiKey&$customer" -Method POST -InFile (Join-Path $dirPath "$hostfile.xml") -ContentType "multipart/form-data" -Verbose -UseBasicParsing -OutFile "a.txt"
        } else {
            $response = Invoke-RestMethod -Uri "$serverUrl/agent/upload?$apiKey" -Method POST -InFile (Join-Path $dirPath "$hostfile.xml") -ContentType "multipart/form-data" -Verbose -UseBasicParsing -OutFile "a.txt"
        }
        if ($response -eq 200) {
            Write-Host "Successfully uploaded scan result to server"
            New-Item -ItemType File -Path $last_scan -Force
        } else {
            Write-Host "Problem while uploading to server,error=$response"
        }
    }
}

CheckAndDeleteFiles
if ($agent) {
    if ($canUpload) {
        DownloadScanScriptFromServer
        Write-Host "executing script"
        ExecuteScript
        UploadScanResultToServer
    } else {
        Write-Host "Not uploading to server"
    }
} else {
    DownloadScanScript
    ExecuteScript
    UploadScanResult
}
CheckAndDeleteFiles
