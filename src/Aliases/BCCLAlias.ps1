# Aliases for the Business Central Command Line

# Create an alias for the BCCL function
$bcclPath = Get-Command -Name bccl -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if ($bcclPath) {
     Set-Alias -Name bc -Value terraform.exe
}
