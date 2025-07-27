# Function to get files count by extension from a directory
Function Get-FilesCountByExtension($folderPath, $startDate, $endDate) {
    # Create a hashtable to store the file extensions and their counts
    $fileExtensionCount = @{}

    # Convert input dates to DateTime objects
    $startDateTime = [DateTime]::Parse($startDate)
    $endDateTime = [DateTime]::Parse($endDate)

    # Recursively get all files that were modified within the specified date range
    $files = Get-ChildItem -Path $folderPath -File -Recurse | Where-Object { $_.LastWriteTime -ge $startDateTime -and $_.LastWriteTime -le $endDateTime }

    foreach ($file in $files) {
        $extension = $file.Extension
        if ($fileExtensionCount.ContainsKey($extension)) {
            $fileExtensionCount[$extension]++
        }
        else {
            $fileExtensionCount[$extension] = 1
        }
    }

    return $fileExtensionCount
}
