function Set-FileDirectoryLocation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $directoryPath = Get-FileDirectory -Path $Path
    Set-Location -Path $directoryPath.ToString()
}

function Get-FileDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    # Check that the path is a file and that it exists
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "The path '$Path' is not a file or does not exist."
    }
    $item = Get-Item -Path $Path
    return $item.Directory
}

function Split-TextFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $TextFilePath
    )

    if (!(Test-Path $TextFilePath)) {
        Write-Host "The specified file does not exist"
        return
    }

    $fileSizeBytes = (Get-Item $TextFilePath).Length
    $fileSizeKB = [math]::Round($fileSizeBytes / 1KB, 2)
    $fileSizeMB = [math]::Round($fileSizeBytes / 1MB, 2)

    $totalLines = (Get-Content $TextFilePath | Measure-Object).Count

    Write-Host "File size: $fileSizeBytes bytes, $fileSizeKB KB, $fileSizeMB MB"
    Write-Host "Total lines in file: $totalLines"

    $hasHeader = Read-Host "Does the file have a header? (y/n)"
    if ($hasHeader -eq "y") {
        $Header = Get-Content $TextFilePath -First 1
    }

    $splitChoice = Read-Host "Do you want to split by size(s) or number of lines(l)?"

    if ($splitChoice -eq "s") {
        Split-TextFileBySize -TextFilePath $TextFilePath -header $Header
    }
    elseif ($splitChoice -eq "l") {
        Split-TextFileByLines -TextFilePath $TextFilePath -header $Header
    }
    else {
        Write-Host "Invalid choice. Please choose 's' for size or 'l' for lines."
    }
}

function Split-TextFileBySize {
    param (
        [Parameter(Mandatory = $true)]
        [string] $TextFilePath,
        [string] $Header
    )

    [int] $splitSizeBytes = 0

    do {
        $splitSizeBytes = Get-RequestedFileSize
    }
    until ($splitSizeBytes -gt 0) 

    $index = 1
    $reader = [System.IO.File]::OpenText("$TextFilePath")
    try {
        while ($reader.EndOfStream -eq $false) {
            $lines = New-Object System.Collections.ArrayList
            if ([string]::IsNullOrWhiteSpace($Header) -eq $false -and $index -gt 1) {
                $lines.Add($Header) | Out-Null
            }
            $currentSize = 0

            while ($reader.EndOfStream -eq $false -and $currentSize -le $splitSizeBytes) {
                $line = $reader.ReadLine()
                $lines.Add($line) | Out-Null
                $currentSize += [System.Text.Encoding]::UTF8.GetByteCount($line)
            }

            $outputFilePath = [System.IO.Path]::ChangeExtension($TextFilePath, ".$index" + [System.IO.Path]::GetExtension($TextFilePath))
            [System.IO.File]::WriteAllLines($outputFilePath, $lines)
            Write-Host "Created file: $outputFilePath"
            $index++
        }
    }
    finally {
        if ($reader) {
            $reader.Close()
        }
    }
}

function Split-TextFileByLines {
    param (
        [Parameter(Mandatory = $true)]
        [string] $TextFilePath,
        [string] $Header
    )

    [int] $desiredLines = 0

    do {
        try {
            $desiredLines = Get-RequestedLineCount
        }
        catch {
            Write-Host $_.Exception.Message
            return;
        }
    }
    until ($desiredLines -gt 0) 

    $index = 1
    $reader = [System.IO.File]::OpenText("$TextFilePath")
    try {
        while ($reader.EndOfStream -eq $false) {
            $lines = New-Object System.Collections.ArrayList
            if ([string]::IsNullOrWhiteSpace($Header) -eq $false -and $index -gt 1) {
                $lines.Add($Header) | Out-Null
            }

            for ($i = 0; $i -lt $desiredLines; $i++) {
                if ($reader.EndOfStream -eq $false) {
                    $lines.Add($reader.ReadLine()) | Out-Null
                }
            }

            $outputFilePath = [System.IO.Path]::ChangeExtension($TextFilePath, ".$index" + [System.IO.Path]::GetExtension($TextFilePath))
            [System.IO.File]::WriteAllLines($outputFilePath, $lines)
            Write-Host "Created file: $outputFilePath"
            $index++
        }
    }
    finally {
        if ($reader) {
            $reader.Close()
        }
    }
}

function Get-RequestedFileSize {
    $desiredSizeKB = Read-Host "Please provide your desired file size in KB"
    $splitSizeBytes = [int]$desiredSizeKB * 1KB
    $approxFiles = [math]::Ceiling($fileSizeBytes / $splitSizeBytes)

    Write-Host "Approximate number of output files: $approxFiles"
    $confirmation = Read-Host "Proceed? (y/n)"

    if ($confirmation -eq "y") {
        return $splitSizeBytes
    }
    else {
        return 0
    }
}

function Get-RequestedLineCount {
    $desiredLines = Read-Host "Please provide your desired number of lines per file"
    $approxFiles = [math]::Ceiling($totalLines / $desiredLines)

    Write-Host "Approximate number of output files: $approxFiles"
    $confirmation = Read-Host "Proceed? (y/n)"

    if ($confirmation -eq "y") {
        return $desiredLines
    }
    else {
        return 0
    }
}

function Get-FileEncoding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $encoding = $null
    $byteCount = 0
    $byteOrderMark = $null

    $byteOrderMark = Get-FileByteOrderMark -Path $Path
    $encoding = Get-FileEncodingFromByteOrderMark -ByteOrderMark $byteOrderMark

    if ($null -eq $encoding) {
        $byteCount = Get-FileByteCount -Path $Path
        $encoding = Get-FileEncodingFromByteCount -ByteCount $byteCount
    }

    return $encoding
}

function Copy-WithRetry {
    param (
        [string]$source,
        [string]$destination,
        [int]$retryCount,
        [int]$waitTime,
        [string]$logFile
    )

    $attempt = 0
    $success = $false

    while (-not $success -and $attempt -lt $retryCount) {
        try {
            $items = Get-ChildItem -Path $source -Recurse

            foreach ($item in $items) {
                $currentItem++
                $destPath = $item.FullName -replace [regex]::Escape($source), $destination

                Copy-Item -Path $item.FullName -Destination $destPath -Force -ErrorAction Stop
                Write-Progress -Activity "Copying files" -Status "Copying $($item.FullName)" -PercentComplete (($currentItem / $totalItems) * 100)
            }

            $success = $true
            Add-Content -Path $logFile -Value "Copy successful on attempt $($attempt + 1)."
        } catch {
            $attempt++
            Add-Content -Path $logFile -Value "Attempt $attempt failed. Retrying in $waitTime seconds..."
            Start-Sleep -Seconds $waitTime
        }
    }

    if (-not $success) {
        Add-Content -Path $logFile -Value "Failed to copy after $retryCount attempts."
    }
}
