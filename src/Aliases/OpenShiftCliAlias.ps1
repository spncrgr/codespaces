# openshift-cli
$ocPath = Get-Command -Name oc -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if ($ocPath) {
    Set-Alias -Name ocxu -Value oc-config-use-context
    Set-Alias -Name ocl -Value oc-login
    Set-Alias -Name oclo -Value oc-logout
    Set-Alias -Name ocxl -Value oc-config-get-contexts
    Set-Alias -Name ocv -Value oc-config-view
}