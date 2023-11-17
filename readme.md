# PowerShell WebServer

## Why?

I got tired of the Windows Forms when building GUI's for my powershell applications.

## How does it work?

- Create the server:

```ps
  using module 'Path/To/WebServer/WebServer_Class.ps1'
  $ws.SetPath($PSScriptRoot) # Set the location
  $ws.Start($true) # $true includes autostart of Microsoft Edge
```

- Important notes:
  - HTML and PS1 files added after the server is started won't automatically sync, however modifications to existing files will
  - Assets (images/css/etc.) and Scripts will be synced automatically
  - To add a manual reload of Endpoints a fetch-request can be made to "/.config/refresh-endpoints"
- A TrayIcon can be added with the build in functionality to:

  - Open the app in App-view
  - Open the app in browser
  - Refresh the Endpoints
  - Exit the app

- In the same folder as the webserver, create a "Pages" folder and an "API" folder.

  - The Pages folder should contain .html files, and the API folder should contain .ps1 files.
  - Any other files will be ignored, but can be loaded from inside the .html files.

- It is recommended to place scripts in a "Scripts" folder and Assets in an "Assets" folder

## Support

- Supports major JavaScript frameworks like React
