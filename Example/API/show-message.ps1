<#
# Note that all calls are blocking, meaning the server will freeze until the script is done. This is prevented by the "Start-Job" command
# To set a custom status, set $body.status to one or more digits (preferably a valid status code) Default is 200, or 400 on error.
#>

param($body)

Add-Type -AssemblyName System.Windows.Forms
$form = [System.Windows.Forms.Form]::new()
$form.TopMost = $true
[System.Windows.Forms.MessageBox]::Show($form, $body.message, $body.title)
