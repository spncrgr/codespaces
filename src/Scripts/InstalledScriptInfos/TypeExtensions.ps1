# Add properties to convert to and from Base64 encoding
Update-TypeData -TypeName "System.String" -MemberType ScriptProperty -MemberName "ToBase64" -Force -Value {
    [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($this))
}
Update-TypeData -TypeName "System.String" -MemberType ScriptProperty -MemberName "FromBase64" -Force -Value {
    [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($this))
}

# Add a 'Quarter' property to System.DateTime
Update-TypeData -TypeName "System.DateTime" -MemberType ScriptProperty -MemberName "Quarter" -Force -Value {
    if ($this.Month -in @(1,2,3)) {
        "Q1"
    }
    elseif ($this.Month -in @(4,5,6)) {
        "Q2"
    }
    elseif ($this.Month -in @(7,8,9)) {
        "Q3"
    }
    else {
        "Q4"
    }
}