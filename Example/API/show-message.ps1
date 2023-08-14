<#
# Note that all calls are blocking, meaning the server will freeze until the script is done. This is prevented by the "Start-Job" command
# To set a custom status, set $body.status to one or more digits (preferably a valid status code) Default is 200, or 400 on error.
#>

param($body)

# $body.status = 204

$null = Start-Job -ScriptBlock {
  param($message, $title)
  Add-Type -AssemblyName System.Windows.Forms
  [System.Windows.Forms.MessageBox]::Show($message, $title)
} -ArgumentList $body.message, $body.title
