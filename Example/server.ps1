using module '../Class/WebServer_Class.psm1' # Imports the WebServer class
$ws = New-Object WebServer # Creates a new instance of the WebServer class
$ws.SetPath($PSScriptRoot) # Sets the location of the folder-tree where Page and API lives (optional)
$ws.SetTrayIconPath('./favico.ico') # Sets the TrayIconPath, if this is set a Tray Icon will appear (optional)

#  $ws.AddEndpoint('/greetings', { "Hello!" }) # Adds an endpoint at /greetings that sends "Hello!" to the browser
<# $ws.AddEndpoint('/api/message', { 
  param($body)
  $body.status = 204
  $null = Start-Job -ScriptBlock {
    param($message, $title)
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($message, $title)
  } -ArgumentList $body.message, $body.title
  return
}, [method]::POST) # Adds an endpoint at /api/message that opens a message box in Windows, can only be reached with the POST method #>
#  $ws.AddEndpoint('/', { '<html><body><h1>Startpage</h1></body</html>' }) # Add a new endpoint at start (/) displaying html code

#$ws.UpdateEndpoint('/greetings', { '<html><body><h1>Hello!</h1></body></html>' }) # Updates the endpoint with name /greetings (Name is required, possible to change callBack, method and/or contentType)

# More examples coming soon...


# $ws.Start() # Starts the WebServer
# $ws.Start(9001) # Starts the WebServer on port 9001 or the first port available after
# $ws.Start(9001, $true) # Starts the WebServer on port 9001 or the first port available and opens a new edge window
$ws.Start($true) # Starts the WebServer and opens a new edge window, [default port: 9001]

