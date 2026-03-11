
$modulePaths = $env:PSModulePath -split ';'
$webModulePath = "$PSScriptRoot/Modules"
if ($modulePaths -notcontains $webModulePath) {
  $env:PSModulePath = ($modulePaths + $webModulePath) -join ';'
}
Class Request {
  [System.Net.HttpStatusCode]$statusCode = 200
  Request() {}
  Request([hashtable]$request) {
    $this.statusCode = $request.statusCode
  }
}
Class ContentType {
  hidden [string]$value
  static [string]$TextPlain = "text/plain"
  static [string]$TextHTML = "text/html"
  static [string]$TextJavaScript = "text/javascript"
  static [string]$TextCSS = "text/css"
  static [string]$TextCSV = "text/csv"
  static [string]$ApplicationJSON = "application/json"
  static [string]$ApplicationGZIP = "application/gzip"
  static [string]$ApplicationZIP = "application/zip"
  static [string]$AudioMidi = "audio/midi"
  static [string]$AudioMP3 = "audio/mpeg"
  static [string]$VideoMP4 = "video/mp4"
  static [string]$videoWEBM = "video/webm"
  static [string]$ImagePng = "image/png"
  static [string]$ImageJpeg = "image/jpeg"
  static [string]$ImageGif = "image/gif"
  static [string]$ImageBmp = "image/bmp"
  static [string]$ImageIco = "image/vnd.microsoft.icon"
  static [string]$ImageSVG = "image/svg+xml"
  static [string]$FontWoff = "font/woff" 
  static [string]$FontWoff2 = "font/woff2" 


  ContentType([string]$value) {
    $this.Value = $value
  }
  static [ContentType] AsType([string] $value) {
    return $value
  }
  

  static [ContentType] FromExt([string]$ext, [bool]$allowDefault) {
    $ext = $ext -replace '^\.', ''
    $ct = switch ($ext) {
      'js' { [ContentType]::textJavaScript }
      'css' { [ContentType]::textCSS }
      'html' { [ContentType]::textHTML }
      'png' { [ContentType]::ImagePng }
      { $_ -match '^jpe?g$' } { [ContentType]::ImageJpeg }
      'gif' { [ContentType]::ImageGif }
      'mp3' { [ContentType]::AudioMP3 }
      'mp4' { [ContentType]::VideoMP4 }
      'ico' { [ContentType]::ImageIco }
      'bmp' { [ContentType]::ImageBmp }
      'svg' { [ContentType]::ImageSVG }
      Default { 
        if (-not $allowDefault) {
          throw """$ext"" is not a valid extension"
        }
        [ContentType]::textHTML 
      }
    }
    return $ct
  }
  static [ContentType] FromExt([string]$ext) {
    return [ContentType]::FromExt($ext, $false)
  }

  [string] ToString() {
    $allowedList = @(
      "text/plain",
      "text/html",
      "text/javascript",
      "text/css",
      "text/csv",
      "application/json",
      "application/gzip",
      "application/zip",
      "audio/mpeg"
      "video/webm",
      "video/mp4",
      "image/png",
      "image/jpeg",
      "image/gif",
      "image/bmp",
      "image/vnd.microsoft.icon",
      "image/svg+xml",
      "application/gzip",
      "font/woff",
      "font/woff2"
    )

    if ($this.value -notin $allowedList) {
      throw """$($this.Value)"" is not a valid ContentType. Valid values:`n$($allowedList -join "`n" )"
    }
    return $allowedList | Where-Object { $_ -eq $this.value }
  }
}

Enum Method {
  GET
  POST
}

class WebServer {
  [System.Collections.ArrayList] hidden $endpoints = [System.Collections.ArrayList]::new()
  [System.Net.HttpListener] hidden $listener
  [string] hidden $titlePrefix = ""
  [char] hidden $titleDelimiter = $null
  [int16] hidden $port = 9001
  [string] hidden $path = ((Get-Location).ProviderPath)
  [int] hidden $appModePid = $null
  [string] hidden $pswsTempDir = $null
  hidden $body = @{}
  hidden $query = @{}
  hidden $store = @{}
  hidden $method = @{}
  hidden $request = [request]::new()

  [void] SetPath([string]$path) {
    $this.path = $path
  }

  [void] SetPort([int]$port) {
    $this.port = $port
  }
  
  [void] SetTitlePrefix([string]$titlePrefix, [char]$titleDelimiter = $null) {
    $this.titlePrefix = $titleprefix
    $this.titleDelimiter = $titleDelimiter
  }

  [void] hidden ResetRequest() {
    $this.method = [Method]::GET.ToString()
    $this.body = @{}
    $this.query = @{}
    $this.request = [Request]::new()
  }

  [void] hidden GetClosestPort([int16]$port) {
    if (Get-NetTCPConnection | Where-Object LocalPort -eq $port) {
      Write-Warning "Port $port is already in use, finding the next available"
      while (Get-NetTCPConnection | Where-Object LocalPort -eq $port) {
        $port++
      }
      Write-Host "New port: $port"
    }
    $this.port = $port
  }

  [scriptblock] hidden ConvertToCallBack($string) { return [scriptblock]::Create("return [string]$string") }

  #----------------------------------------------------------------
  # Endpoints (ADD)
  #----------------------------------------------------------------

  #----------------------------------------------------------------
  # Add Endpoint
  #----------------------------------------------------------------

  [void]AddEndpoint([string]$name, [scriptblock]$callBack, [Method[]]$methods = "GET", [ContentType]$ContentType, [bool]$static = $false) {
    $name = $name -replace '^/?(.*)/?$', '$1'
    if ($this.endpoints | Where-Object name -eq $name) {
      Write-Error "An endpoint with name ""$name"" already exists"
      return
    }

    $null = $this.endpoints.Add(@{
        name        = $name
        methods     = $methods
        ContentType = $contentType
        callback    = $callback
        static      = $static
      })
    return
  }

  #----------------------------------------------------------------
  # Add with Methods
  #----------------------------------------------------------------

  [void] AddEndpoint([string]$name, [scriptblock]$callBack, [Method[]]$methods = "GET", [bool]$static = $false) {
    $this.AddEndpoint($name, $callBack, $methods, [ContentType]::textHTML, $static)
  }

  #----------------------------------------------------------------
  # Add with ContentType
  #----------------------------------------------------------------
    
  [void] AddEndpoint([string]$name, [scriptblock]$callBack, [string]$ContentType, [bool]$static = $false) {
    $this.AddEndpoint($name, $callBack, @('GET', 'POST'), $contentType, $static)
  }

  #----------------------------------------------------------------
  # Add (Barebones)
  #----------------------------------------------------------------

  [void] AddEndpoint([string]$name, [scriptblock]$callBack, [bool]$static = $false ) {
    $this.AddEndpoint($name, $callBack, @('GET', 'POST'), [ContentType]::textHTML, $static)
  }

  #----------------------------------------------------------------
  # Add (Barebones, as string)
  #----------------------------------------------------------------

  [void] AddEndpoint([string]$name, [string]$callBack, [bool]$static = $false ) {
    $this.AddEndpoint($name, $this.ConvertToCallBack($callBack), @('GET', 'POST'), [ContentType]::textHTML, $static)
  }

  #----------------------------------------------------------------
  # Endpoints (ADD) END
  #----------------------------------------------------------------

  #----------------------------------------------------------------
  # Endpoints (UPDATE)
  #----------------------------------------------------------------

  #----------------------------------------------------------------
  # Update Endpoint (Full)
  #----------------------------------------------------------------

  [void] UpdateEndpoint([string]$name, [scriptblock]$callback, [Method[]]$methods, [string]$contentType) {
    [hashtable]$endpoint = $this.endpoints | Where-Object Name -eq $name
    if (-not $endpoint) {
      Write-Warning "No endpoint whith the name $name exists"
      return
    }

    $endpoint.callback = $callback
    $endpoint.methods = $methods
    $endpoint.ContentType = $contentType
  }

  #----------------------------------------------------------------
  # Update Callback
  #----------------------------------------------------------------
  [void] UpdateEndpoint([string]$name, [scriptblock]$callback) {
    [hashtable]$endpoint = $this.endpoints | Where-Object Name -eq $name
    if (-not $endpoint) {
      Write-Warning "No endpoint whith the name $name exists"
      return
    }
    $this.UpdateEndpoint($name, $callback, $endpoint.methods, $endpoint.ContentType)
  }

  [void] UpdateEndpoint([string]$name, [string]$callback) {
    $this.UpdateEndpoint($name, $this.ConvertToCallBack($callBack))
  }


  #----------------------------------------------------------------
  # Update Methods
  #----------------------------------------------------------------

  [void] UpdateEndpoint([string]$name, [Method[]]$methods) {
    [hashtable]$endpoint = $this.endpoints | Where-Object Name -eq $name
    if (-not $endpoint) {
      Write-Warning "No endpoint whith the name $name exists"
      return
    }
  
    $this.UpdateEndpoint($name, $endpoint.callback, $methods, $endpoint.ContentType)

  }

  #----------------------------------------------------------------
  # Update Content Type
  #----------------------------------------------------------------

  [void] UpdateEndpoint([string]$name, [ContentType]$contentType) {
    [hashtable]$endpoint = $this.endpoints | Where-Object Name -eq $name
    if (-not $endpoint) {
      Write-Warning "No endpoint whith the name $name exists"
      return
    }
    $this.UpdateEndpoint($name, $endpoint.callback, $endpoint.methods, $ContentType)
  }

  #----------------------------------------------------------------
  # Update Callback and Method
  #----------------------------------------------------------------

  [void] UpdateEndpoint([string]$name, [scriptblock]$callback, [Method[]]$methods) {
    [hashtable]$endpoint = $this.endpoints | Where-Object Name -eq $name
    if (-not $endpoint) {
      Write-Warning "No endpoint whith the name $name exists"
      return
    }
  
    $this.UpdateEndpoint($name, $callback, $methods, $endpoint.ContentType)
  }
  [void] UpdateEndpoint([string]$name, [string]$callback, [Method[]]$methods) {
    $this.UpdateEndpoint($name, $this.ConvertToCallBack($callBack), $methods)
  }

  #----------------------------------------------------------------
  # Update Callback and ContentType
  #----------------------------------------------------------------

  [void] UpdateEndpoint([string]$name, [scriptblock]$callback, [ContentType]$contentType) {
    [hashtable]$endpoint = $this.endpoints | Where-Object Name -eq $name
    if (-not $endpoint) {
      Write-Warning "No endpoint whith the name $name exists"
      return
    }
    $this.UpdateEndpoint($name, $callback, $endpoint.methods, $ContentType)
  }

  [void] UpdateEndpoint([string]$name, [string]$callback, [ContentType]$contentType) {
    $this.UpdateEndpoint($name, $this.ConvertToCallBack($callBack), $contentType)
  }
  #----------------------------------------------------------------
  # Update Methods and Content Types
  #----------------------------------------------------------------

  [void] UpdateEndpoint([string]$name, [Method[]]$methods, [ContentType]$contentType) {
    [hashtable]$endpoint = $this.endpoints | Where-Object Name -eq $name
    if (-not $endpoint) {
      Write-Warning "No endpoint whith the name $name exists"
      return
    }
    $this.UpdateEndpoint($name, $endpoint.callback, $methods, $ContentType)
  }


  #----------------------------------------------------------------
  # Endpoints (UPDATE) END
  #----------------------------------------------------------------


  #----------------------------------------------------------------
  # Creates the listener if it does not exist
  #----------------------------------------------------------------
  [void] hidden CreateListener() {
    if ($this.listener) { return }
    $this.listener = [System.Net.HttpListener]::new()
    $this.GetClosestPort($this.port)
    $this.listener.Prefixes.Add("http://localhost:$($this.port)/")
    $this.listener.Start()
  }

  [void] hidden CreateListener([int]$port) {
    $this.port = $port
    $this.CreateListener()
  }
  #----------------------------------------------------------------
  #----------------------------------------------------------------

  #----------------------------------------------------------------
  # Adds Endpoints from the Pages Folder
  #----------------------------------------------------------------
  [void] hidden AddPagesEndpoints($item) {
    Get-ChildItem $item.fullName | ForEach-Object {
      if ($_.Attributes -eq 'Directory') {
        return $this.AddPagesEndpoints($_)
      }
      <#if ($_.Extension -ne '.html') {
        return
      }#>
      
      $path = '/' + ($_.FullName -replace ("$(($this.Path -replace '.*::') -replace '\\', '\\')\\pages\\") -replace '(index|).html' -replace '\\', '/' -replace '/$')
      if (($path -replace '^/') -in $this.endpoints.Name) {
        return
      }

      $contentType = [ContentType]::FromExt($_.Extension, $true)
      
      $this.AddEndpoint($path, [scriptblock]::Create("Get-Content -Path '$($_.FullName)' -Raw -encoding UTF8"), $contentType, $true )
      $this.endpoints | Where-Object name -eq ($path -replace '^/') | ForEach-Object {
        $_.Base = $item.fullName -replace ($this.Path -replace '.*::' -replace '\\', '\\') -replace '\\', '/'
        $_.PageBase = $_.Base -replace '^/Pages'
      }
    }
  }
  #----------------------------------------------------------------
  #----------------------------------------------------------------

  #----------------------------------------------------------------
  # Adds Endpoints from the API Folder (.ps1 files)
  #----------------------------------------------------------------
  [void] hidden AddAPIEndpoints($item) {
    Get-ChildItem -Path $item.fullName | ForEach-Object {
      if ($_.Attributes -eq 'Directory') {
        return $this.AddAPIEndpoints($_)
      }
      if ($_.Extension -ne '.ps1') {
        return
      }
      $path = ($_.FullName -replace ($this.path -replace '\\', '\\') -replace '(index|).ps1' -replace '\\', '/' -replace '/$')

      if (($path -replace '^/') -in $this.endpoints.Name) {
        return
      }
      $content = (Get-Content $_.FullName) -join "`n"
      if ($content -match "^methods?:") {
        $Methods = ($content -replace 'methods?:(.*)$', '$1' -split ',') | ForEach-Object { [Method]($_.Trim()) }
      }
      else {
        $Methods = @([Method]::GET, [Method]::POST)
      }
      if ($content -match '^#html$') {
        $contentType = [ContentType]::textHTML
      }
      else {
        $contentType = [ContentType]::ApplicationJSON
      }

      $this.AddEndpoint($path, [scriptblock]::Create(". '$($_.FullName)' -body `$this.body -query `$this.query -method `$this.method -store `$this.store -request `$this.request" ), $Methods, $contentType, $true)
    }
  }
  #----------------------------------------------------------------
  # Retrieves the Paths to Static Files
  # Expects a Pages folder for Static Endpoints
  #   - Expects .html files, ignores others
  # Expects an API folder for Static APIs
  #   - Expects .ps1 files, ignores others
  #----------------------------------------------------------------
  [void] LoadStaticEndpoints() {
    $_endpoints = [System.Collections.ArrayList]::new()
    $this.endpoints | Where-Object { -not $_.static } | ForEach-Object {
      $_endpoints.Add($_)
    }
    $this.endpoints = $_endpoints
    
    $pagesPath = (Join-Path -path $this.path -ChildPath 'pages')
    $apiPath = (Join-Path -path $this.path -ChildPath 'api')


    if (Test-Path $pagesPath) {
      $this.AddPagesEndpoints((Get-Item -Path $pagesPath))
    }
    if (Test-Path $apiPath) {
      $this.AddAPIEndpoints((Get-Item -Path $apiPath))
    }
  }


  [void]ParseRequest([System.Net.HttpListenerRequest]$req) {
    $this.Method = $req.HttpMethod
    if ($req.HasEntityBody) {
      [System.IO.StreamReader]::new($req.InputStream).ReadLine() | ForEach-Object {
        try {
          $item = $_ | ConvertFrom-Json
          $item.PSObject.Properties | ForEach-Object {
            $this.body.($_.Name) = $_.Value
          }
        }
        catch {} 
      }
    }

    $req.Url.Query -replace '^\?' -split '&' | ForEach-Object {
      $key, $value = $_ -split '='
      $this.query.$key = [System.Net.WebUtility]::UrlDecode(($value -join '='))
    }
  }


  hidden [byte[]] BufferFromFile([string]$path) {
    $fstream = [System.IO.FileStream]::new($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    [byte[]]$buffer = [byte[]]::new($fstream.Length)
    $fstream.Read($buffer, 0, $fstream.Length)
    $fstream.close()
    return $buffer
  }

  hidden [byte[]] BufferFromString([string]$message) {
    return [System.Text.Encoding]::UTF8.GetBytes($message)
  }

  #----------------------------------------------------------------
  # Starts the server on specified port 
  # (If port is in use, the next avaliable port will be used)
  #----------------------------------------------------------------
  [void]Start([int16]$port) {
    $this.port = $port
    function Send-Response {
      param(
        [System.Net.HttpListenerResponse]$res,
        [byte[]]$buffer,
        [ContentType]$contentType = [ContentType]::textHTML
      )
     
      try {      
        $res.ContentType = $contentType
        $res.contentLength64 = $buffer.Length
        $output = $res.OutputStream
        $output.write($buffer, 0, $buffer.Length)
        $output.close()
    
      }
      catch {
        Write-Host $path
        Write-Host $_ -ForegroundColor Red
      }
    }
  
    $this.CreateListener()
  
    $this.LoadStaticEndpoints()
    Write-Host "Server started on port $($this.port) (http://localhost:$($this.port))" -ForegroundColor Green
    Write-Host "Avaliable endpoints:"
  
    #----------------------------------------------------------------
    # Writes all endpoints to console
    #----------------------------------------------------------------
    foreach ($endpoint in $this.endpoints) {
      if (($endpoint.name -match '\.[a-zA-Z]{2,4}$') -and ($endpoint.name -notmatch '^/API/.*\.psm?1')) {
        continue
      }
      $color = if ($endpoint.name -like 'api/*') {
        [System.ConsoleColor]::Gray
      }
      else {
        [System.ConsoleColor]::Magenta
      }
      
      Write-Host "/$($endpoint.name)" -ForegroundColor $color
    }
    Write-Host "/`$end (Closes the server)" -ForegroundColor Yellow


    #----------------------------------------------------------------
    # Reads the request and send response
    #----------------------------------------------------------------
    Function Invoke-Request {
      param([System.Net.HttpListenerContext]$context)
      $req = $context.Request
      $res = $context.Response

      $this.ResetRequest()
      $this.LoadStaticEndpoints()
     
      if ( $req.url -match "$($this.port)/\`$end/?$") {
        Send-Response -req $req -res $res
        return 'Stop'
      }

      $urlPath = Join-Path -Path $this.path -ChildPath ($req.url -replace ".*localhost:$($this.port)")
      
      $file = if ((Test-Path -Path $urlPath -PathType Leaf)) { Get-Item -Path $urlPath }
 
      $contentType = [ContentType]::FromExt($file.Extension, $true)

      if ($file) {
        try {
          $content = $this.BufferFromFile($file.FullName)
        }
        catch {
          $res.statusCode = 404
          $content = $this.BufferFromString("404 - Not Found")
          $contentType = [ContentType]::textHTML
        }

        Send-Response -res $res -buffer $content -contentType $contentType
        return
      }
      
      $url = ([string]$req.Url.AbsolutePath) -replace '^/?(.*)(/|)$', '$1'
      
      $endpoint = $this.endpoints | Where-Object Name -eq $url
      $this.Method = $req.HttpMethod
      if (-not $endpoint) {
        $res.statusCode = 404
        Send-Response -res $res -buffer ($this.BufferFromString("Not Found"))
        return
      }
      if (-not ($req.HttpMethod -in $endpoint.methods)) {
        $res.statusCode = 405
        Send-Response -res $res -buffer ($this.BufferFromString("Method Not Allowed"))
        return
      }

      $message = try {
        if ($req.HasEntityBody) {
          [System.IO.StreamReader]::new($req.InputStream).ReadLine() | ForEach-Object {
            try {
              $item = $_ | ConvertFrom-Json
              $item.PSObject.Properties | ForEach-Object {
                $this.body.($_.Name) = $_.Value
              }
            }
            catch {} 
          }
        }

        $req.Url.Query -replace '^\?' -split '&' | ForEach-Object {
          $key, $value = $_ -split '='
          $this.query.$key = [System.Net.WebUtility]::UrlDecode(($value -join '='))
        }
       
        $ContentType = $endpoint.ContentType

        $result = Invoke-Command -ScriptBlock $endpoint.callback -ErrorAction Stop
         
        $baseUrl = $endpoint.PageBase
        if ($this.titlePrefix) {
          $result = $result -replace '<title>(.*)?</title>', "<title>$($this.titlePrefix) $($this.titleDelimiter) `$1</title>"
        }
        $result = $result -replace '(<(script|img|link|a) .*?(src|href) ?= ?")(?!http)(\./()|(\w))(.*?>)', "`$1$($baseUrl)/`$6`$7"
        

        if (-not $result) { $res.statusCode = 204 }

        if ($this.request.statusCode -is [System.Net.HttpStatusCode] -and $this.request.statusCode -ne [System.Net.HttpStatusCode]::OK) {
          $res.statusCode = $this.request.statusCode
        }

        if (-not ($result -is [string])) {
          $ContentType = [ContentType]::ApplicationJSON
          $result = $result | ConvertTo-Json -Compress
        }

        Send-Response -res $res -buffer $this.BufferFromString($result) -ContentType $ContentType
        return
      }
      catch {
        $res.StatusCode = 400
        
        Write-Host ($_.Exception.Message) -ForegroundColor Red
        $ContentType = [ContentType]::ApplicationJSON
        @{
          status  = 400
          Message = "Bad Request"
        } | ConvertTo-Json -Compress
        
      }
      
      Send-Response -res $res -buffer $this.BufferFromString($message) -contentType $ContentType
    } 

    #----------------------------------------------------------------
    # Request handler
    #----------------------------------------------------------------
    while ($true) {

      try {
        $context = $this.listener.GetContext()
        $status = Invoke-Request -context $context
        Write-Host $status
        if ($status -eq 'Stop') {
          Write-Host "Server stopped" -ForegroundColor Green
          return
        }
      }
      catch [System.Management.Automation.MethodInvocationException] {
        throw $_
      }
      catch { 
        Write-host $_ -ForegroundColor red
       
      }
    }
  }
  #----------------------------------------------------------------
  #----------------------------------------------------------------


  #----------------------------------------------------------------
  # Starts the WebServer on the Instance's default port
  #----------------------------------------------------------------
  [void]Start() {
    $this.Start($this.port)
  }

  #----------------------------------------------------------------
  # Starts the WebServer on specified port and opens Edge in app-mode
  #----------------------------------------------------------------

  [void]Start([int16]$port, [switch]$InBrowser) {
    $this.CreateListener($port)
    $this.OpenInBrowser()
    $this.Start($this.port)
  }


  #----------------------------------------------------------------
  # Starts the WebServer on the Instance's default port and opens Edge in app-mode
  #----------------------------------------------------------------

  [void]Start([switch]$InBrowser) {
    $this.CreateListener()
    $this.OpenInBrowser()
    $this.Start($this.port)
  }

  #----------------------------------------------------------------
  # Stops the WebServer
  #----------------------------------------------------------------

  [void]Stop() {
    if (-not $this.listener.IsListening) {
      Write-Host "Server is not running" -ForegroundColor Yellow
      return
    }

    $this.listener.Stop()
    $this.listener.Close()
    $this.listener = $null

    if ($this.appModePid -and (Get-Process -Id $this.appModePid -ErrorAction SilentlyContinue)) {
      try {
        Stop-Process -Id $this.appModePid -ErrorAction Stop
      }
      catch {
        Write-Host "Failed to close browser window: $_" -ForegroundColor Red
      }
    }

    if ($this.pswsTempDir -and (Test-Path -Path $this.pswsTempDir)) {
      Start-Sleep -Milliseconds 10 # Give the browser some time to close and release the temp directory
      try {
        Remove-Item -Path $this.pswsTempDir -Recurse -Force
      }
      catch {
        Write-Host "Failed to remove temporary files: $_" -ForegroundColor Red
      }
    }
  }

  
  #----------------------------------------------------------------
  # Script for creating a new browser-window
  #----------------------------------------------------------------

  [void] hidden OpenInBrowser() {
    try {
      $_currentPid = [System.Diagnostics.Process]::GetCurrentProcess().Id
      $_pswsTempDir = Join-Path -Path $env:TEMP -ChildPath "PSWS_$(Get-Random 10000)"
      $_appModePid = (Start-Process -FilePath (Get-ItemProperty -ErrorAction Stop -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe\')."(default)" -ArgumentList "--app=http://localhost:$($this.port)", "--user-data-dir=$($_pswsTempDir)", '--disable-extensions' -PassThru).Id
      $this.pswsTempDir = $_pswsTempDir
      $this.appModePid = $_appModePid
      Start-Job -ScriptBlock {
        (Get-Process -Id $using:_appModePid).WaitForExit()
        $url = $using:this.listener.Prefixes | Select-Object -First 1
        Invoke-RestMethod -Uri "$url/`$end" -Method 'POST'
      }

      Start-Process powershell.exe -ArgumentList "-NoProfile -WindowStyle Hidden -Command & {(Get-Process -Id $_currentPid).WaitForExit(); (Get-Process -id $_appModePid).Kill(); Remove-Item -Path $this.pswsTempDir -Recurse -Force}"
    }
    catch {
      Write-Host "Failed to open browser window: $_" -ForegroundColor Red
    }
  }
}

#----------------------------------------------------------------
# 
#----------------------------------------------------------------

<#
.SYNOPSIS
  Exposed function to create and start a new WebServer
.DESCRIPTION
  Exposed function to create and start a new WebServer, allowing setting port number, initial path, title prefix and delimiter (string, char), autostart with or without headless browser (Edge)
.NOTES
  Works only on Windows for now
.LINK
  https://github.com/bempus/PowerShell-WebServer

.EXAMPLE
  New-WebServer
  Returns a new [WebServer] with port 3000

.Example
  New-WebServer -port 9001
  Returns a new [WebServer] with port 9001

.Example
  New-WebServer -path 'C:\Temp\WebServer'
  Returns a new [WebServer] with port 3000 and Path 'C:\Temp\WebServer'
#>


function New-WebServer {
  param([int]$port = 3000, [string]$path, [string]$titlePrefix, [char]$titleDelimiter, [switch]$autoStart, [switch]$autoStartInBrowser)

  $ws = [WebServer]::new()
  $ws.SetPort($port)
  if ($path) {
    $ws.SetPath($path)
  }
  if ($titlePrefix -and $titleDelimiter) {
    $ws.SetTitlePrefix($titlePrefix, $titleDelimiter)
  }
  
  if ($autoStart) {
    $ws.Start()
    return
  }

  if ($autoStartInBrowser) {
    $ws.Start($true)
    return
  }

  return $ws
}