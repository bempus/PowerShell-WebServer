# PowerShell WebServer

## Why?

I got tired of the Windows Forms when building GUI's for my powershell applications.

## How does it work?

- Installation

```ps
 Install-Module -Name 'Bempus-WebServer'
```

- Create the server:

```ps
  Import-Module Bempus-WebServer
  $ws = New-Webserver
  $ws.SetPath($PSScriptRoot) # Set the location (optional)
  $ws.Start($true) # $true includes autostart of Microsoft Edge
  #OR#
  $ws.Start() # Starts the server without browser
```

- Important notes:

  - HTML and PS1 files added or modified after the server is started will sync, however the endpoints list won't update
  - Assets (images/css/etc.) and Scripts will be synced automatically

- In the same folder as the webserver or at the specified Path, create a "Pages" folder and an "API" folder.

  - The Pages folder should contain .html files, and the API folder should contain .ps1 files.
  - Any other files will be ignored, but can be loaded from inside the .html files.

## Support

- Supports major JavaScript frameworks like React, Angular etc.
- Supports HTMX
- Supports majority of image/video/audio files such as jpg, png, svg, mp4, mp3, etc.
