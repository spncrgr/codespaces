function Convert-FromBase64 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Value
    )

    # Convert the Base64 string to bytes
    $bytes = [System.Convert]::FromBase64String($Value)
    # Convert the bytes to a string
    $string = [System.Text.Encoding]::UTF8.GetString($bytes)
    return $string
}