
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
  static [string]$ApplicationMP4 = "video/mp4"
  static [string]$videoWEBM = "video/webm"
  static [string]$ImagePng = "image/png"
  static [string]$ImageJpeg = "image/jpeg"
  static [string]$ImageGif = "image/gif"
  static [string]$ImageBmp = "image/bmp"
  static [string]$ImageIco = "image/vnd.microsoft.icon"
  static [string]$ImageSvg  = "image/svg+xml"
  static [string]$FontWoff = "font/woff" 
  static [string]$FontWoff2 = "font/woff2"


  ContentType([string]$value) {
    $this.Value = $value
  }
  static [ContentType] AsType([string] $value) {
    return $value
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
      "video/mp4",
      "video/webm",
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
  [int16] hidden $port = 9001
  [string] hidden $path = ((Get-Location).Path -replace '.*::')
  $body = @{}

  [void] SetPath([string]$path) {
    $this.path = $path -replace '.*::'
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

  [void]AddEndpoint([string]$name, [scriptblock]$callBack, [Method[]]$methods = "GET", [ContentType]$ContentType ) {
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
      })
    return
  }

  #----------------------------------------------------------------
  # Add with Methods
  #----------------------------------------------------------------

  [void] AddEndpoint([string]$name, [scriptblock]$callBack, [Method[]]$methods = "GET") {
    $this.AddEndpoint($name, $callBack, $methods, [ContentType]::textHTML)
  }

  #----------------------------------------------------------------
  # Add with ContentType
  #----------------------------------------------------------------
    
  [void] AddEndpoint([string]$name, [scriptblock]$callBack, [string]$ContentType ) {
    $this.AddEndpoint($name, $callBack, @('GET', 'POST'), $contentType)
  }

  #----------------------------------------------------------------
  # Add (Barebones)
  #----------------------------------------------------------------

  [void] AddEndpoint([string]$name, [scriptblock]$callBack ) {
    $this.AddEndpoint($name, $callBack, @('GET', 'POST'), [ContentType]::textHTML)
  }

  #----------------------------------------------------------------
  # Add (Barebones, as string)
  #----------------------------------------------------------------

  [void] AddEndpoint([string]$name, [string]$callBack ) {
    $this.AddEndpoint($name, $this.ConvertToCallBack($callBack), @('GET', 'POST'), [ContentType]::textHTML)
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
    $this.GetClosestPort($this.port)
    $this.listener = [System.Net.HttpListener]::new()
    $this.listener.Prefixes.Add("http://+:$($this.port)/")
    $this.listener.Start()
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
      if ($_.Extension -ne '.html') {
        return
      }
      $path = '/' + ($_.FullName -replace ("$(((Get-Location).path -replace '.*::') -replace '\\', '\\')\\pages\\") -replace '(index|).html' -replace '\\', '/' -replace '/$')
      if (($path -replace '^/') -in $this.endpoints.Name) {
        return
      }
      $this.AddEndpoint($path, [scriptblock]::Create("Get-Content -Path '$($_.FullName)' -encoding UTF8") )
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
      $this.AddEndpoint($path, [scriptblock]::Create(". '$($_.FullName)' -body `$this.body" ), $Methods, $contentType)
    }
  }


  #----------------------------------------------------------------
  # Starts the server on specified port 
  # (If port is in use, the next avaliable port will be used)
  #----------------------------------------------------------------
  [void]Start() {
    function Send-Response {
      param(
        [System.Net.HttpListenerResponse]$res,
        [string]$message,
        [string]$path,
        [ContentType]$contentType = [ContentType]::textHTML
      )

      try {
        if ($path) {
          $path = $path -replace '.*::'
          $fstream = [System.IO.FileStream]::new($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
          [byte[]]$buffer = [byte[]]::new($fstream.Length)
          $fstream.Read($buffer, 0, $fstream.Length)
          $fstream.close()
        }
        else {
          [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
        }
      
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
  
    if(-not $this.listener) {
      $this.CreateListener()
    }
      
    #----------------------------------------------------------------
    # Retrieves the Paths to Static Files
    # Expects a Pages folder for Static Endpoints
    #   - Expects .html files, ignores others
    # Expects an API folder for Static APIs
    #   - Expects .ps1 files, ignores others
    #----------------------------------------------------------------
    $pagesPath = (Join-Path -path $this.path -ChildPath 'pages')
    $apiPath = (Join-Path -path $this.path -ChildPath 'api')


    if (Test-Path $pagesPath) {
      $this.AddPagesEndpoints((Get-Item -Path $pagesPath))
    }
    if (Test-Path $apiPath) {
      $this.AddAPIEndpoints((Get-Item -Path $apiPath))
    }

    Write-Host "Server started on port $($this.port) (http://localhost:$($this.port))" -ForegroundColor Green
    Write-Host "Avaliable endpoints:"
  
    #----------------------------------------------------------------
    # Writes all endpoints to console
    #----------------------------------------------------------------
    foreach ($endpoint in $this.endpoints) {
      Write-Host "/$($endpoint.name)" -ForegroundColor Magenta
    }
    Write-Host "/end (Closes the server)" -ForegroundColor Yellow
    $this.body.path = (Get-Location)

    #----------------------------------------------------------------
    # Reads the request and send response
    #----------------------------------------------------------------
    Function Invoke-Request {
      param($context)
      $req = $context.Request
      $res = $context.Response

      if ($req.url -match '/end/?$') { 
        Send-Response -req $req -res $res -message "Server Closed"
        $this.Stop()
        return 'Stop'
      }
  
      $urlPath = Join-Path -Path $this.body.path -ChildPath ($req.url -replace ".*localhost:$($this.port)")
      $ext = if (Test-Path -Path $urlPath) { (Get-Item -Path $urlPath).Extension -replace '\.'}

      if ($ext) {
        try {
          $content = (Get-Content $urlPath -errorAction Stop -Encoding UTF8) -join "`n"
          $contentType = switch ($ext) {
            'js' { [ContentType]::textJavaScript }
            'css' { [ContentType]::textCSS }
            'html' { [ContentType]::textHTML }
            'png'   {[ContentType]::ImagePng}
            { $_ -match '^jpe?g$' } { [ContentType]::ImageJpeg }
            'gif' { [ContentType]::ImageGif }
            'mp3' { [ContentType]::AudioMP3 }
            'mp4' { [ContentType]::ApplicationMP4 }
            'ico' { [ContentType]::ImageIco }
            'bmp' { [ContentType]::ImageBmp }
            'svg' {[ContentType]::ImageSvg}
            Default { [ContentType]::textHTML }
          }    
        }
        catch {
          $res.StatusCode = 404
          $content = "404 - Not Found"
          $contentType = [ContentType]::textHTML
        }
        if($contentType -notlike 'text*') {
          Send-Response -res $res -path $urlPath -contentType $contentType
        }else {
        Send-Response -res $res -message $content -contentType $contentType
        }
        return
      }
      
      $url = ([string]$req.Url.AbsolutePath) -replace '^/?(.*)(/|)$', '$1'
      $endpoint = $this.endpoints | Where-Object Name -eq $url
        
      if (-not $endpoint) {
        $res.StatusCode = 404
        Send-Response -res $res -message "Not Found" 
        return
      }
      if (-not ($req.HttpMethod -in $endpoint.methods)) {
        $res.StatusCode = 405
        Send-Response -res $res -message "Method Not Allowed"
        return
      }

      $message = try {
        $this.body = @{}       
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
        $this.body.path = (Get-Location).Path
        $this.body.method = $req.HTTPmethod
        $ContentType = $endpoint.ContentType
       
        $result = Invoke-Command -ScriptBlock $endpoint.Callback -ArgumentList $this.body -ErrorAction Stop

        if (-not $result) { $res.StatusCode = 204 }
        if ($this.body.status -match '\d+') {
          $res.statusCode = $this.body.status
        }

        if ($result.StatusCode -and $result.statusCode -match '\d+') { $res.statusCode = $result.statusCode }
        Send-Response -res $res -message $result
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

      Send-Response -res $res -message $message -contentType $ContentType
    } 

    #----------------------------------------------------------------
    #----------------------------------------------------------------

    $MAX_THREADS = 10
    $pool = [runspacefactory]::CreateRunspacePool(1, $MAX_THREADS)
    $pool.Open()
    #----------------------------------------------------------------
    # Request handler
    #----------------------------------------------------------------
    while ($true) {
      try {
        $context = $this.listener.GetContext()


        $status =  Invoke-Request -context $context
        if ($status -eq 'Stop') {
          return
        }
      }
      catch {Write-host $_ -ForegroundColor red}
    }
  }
  #----------------------------------------------------------------
  #----------------------------------------------------------------


  #----------------------------------------------------------------
  # Starts the WebServer on the Instance's default port
  #----------------------------------------------------------------
  [void]Start([int16]$port) {
    $this.port = $port
    $this.Start()
  }

  #----------------------------------------------------------------
  # Starts the WebServer on specified port and opens Edge in app-mode
  #----------------------------------------------------------------

  [void]Start([int16]$port, [switch]$InBrowser) {
    $this.port = $port
    $this.CreateListener()
    $this.OpenInBrowser()
    $this.Start()
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
    $this.listener.Close()
    $this.listener.Dispose() 
  }

  
  #----------------------------------------------------------------
  # Script for creating a new browser-window
  #----------------------------------------------------------------
  [void] hidden OpenInBrowser() {
    try {
      Start-Job -ScriptBlock {
        param($port)
        Start-Process -FilePath (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe\')."(default)" -ArgumentList "--app=http://localhost:$($port)"
      } -ArgumentList $this.port
    }
    catch {}
  }

}