# PowerShell WebServer

## Changelog

- 1.0
  - Initial release
- 2.0
  - Added async reqeusts and soft closing
  - Rewritten most of the code base
  - Extracted the request into separate file for readability
- 2.1
  - Added SSR support via pshtml

## Why?

I got tired of the Windows Forms when building GUI's for my powershell applications.  
Also to see if I could

## How does it work?

- Installation

```ps
 Install-Module -Name 'Bempus-WebServer'
```

- Create the server:

```
Use the Example/server.ps1 in this repo
```

**OR**

Create your own instance:

```ps
  Import-Module Bempus-WebServer
  # Start Webserver directly (expects Pages and/or API folder at path):
  New-WebServer -path $PSScriptRoot -AutoStart -DisposeOnClose # -AutoStartAsApp only works on Windows

  # OR

   $ws = New-WebServer -path $PSScriptRoot
   $ws | Add-Endpoint -name '/' -callback {
    "<html><body><h1>Hello World</h1><body></html>"
   }
   $ws | Start-WebServer # starts the webserver (-DisposeOnClose can be used to dispose the webserver automatically)
  #
```

- ps1-files and callback scriptblocks
  Default params are $body, $query, $method, $store, $request, $basePath these can be used inside a param() in any ps1 file or callback scriptblock.
  If the script returns anything other than a string, it'll be stringified as JSON

- In the same folder as the webserver or at the specified Path, create a "Pages" folder and an "API" folder.
  - The Pages folder should contain .html files, and the API folder should contain .ps1 files. These paths ignore extensions and index.html (i.e. endpoint for 'Pages/index.html' is '/', endpoint for 'API/example.api' is '/API/example')
  - Any file can be reached by it's full relative path-name, i.e /API/example.ps1 will display the ps1 file as text. Useful to fetch non-parsed files such as javascript/css/images/etc. i.e. '/assets/scripts/main.js'

## Support

- Supports major JavaScript frameworks like React, Angular etc.
- Supports HTMX
- Supports majority of image/video/audio files such as jpg, png, svg, mp4, mp3, etc.
