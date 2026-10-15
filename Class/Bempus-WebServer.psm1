class ContentType {
  hidden [string]$value

  static [string]$TextPlain = "text/plain"
  static [string]$TextHTML = "text/html"
  static [string]$TextCSS = "text/css"
  static [string]$TextCSV = "text/csv"
  static [string]$TextJavascript = "text/javascript"
  static [string]$TextXML = "text/xml"
  static [string]$TextMarkdown = "text/markdown"

  static [string]$ApplicationJSON = "application/json"
  static [string]$ApplicationXML = "application/xml"
  static [string]$ApplicationPDF = "application/pdf"
  static [string]$ApplicationZip = "application/zip"
  static [string]$ApplicationGzip = "application/gzip"
  static [string]$ApplicationOctetStream = "application/octet-stream"
  static [string]$ApplicationXhtml = "application/xhtml+xml"
  static [string]$ApplicationSql = "application/sql"
  static [string]$ApplicationWasm = "application/wasm"

  static [string]$ImgPng = "image/png"
  static [string]$ImgJpeg = "image/jpeg"
  static [string]$ImgGif = "image/gif"
  static [string]$ImgWebp = "image/webp"
  static [string]$ImgSvg = "image/svg+xml"
  static [string]$ImgBmp = "image/bmp"
  static [string]$ImgIco = "image/vnd.microsoft.icon"
  static [string]$ImgTiff = "image/tiff"

  static [string]$AudioMpeg = "audio/mpeg"
  static [string]$AudioOgg = "audio/ogg"
  static [string]$AudioWav = "audio/wav"
  static [string]$AudioWebm = "audio/webm"
  static [string]$AudioAac = "audio/aac"
  static [string]$VideoMp4 = "video/mp4"
  static [string]$VideoWebm = "video/webm"
  static [string]$VideoOgg = "video/ogg"
  static [string]$VideoMpeg = "video/mpeg"
  static [string]$VideoQuicktime = "video/quicktime"

  static [string]$MsWord = "application/msword"
  static [string]$MsWordDocx = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  static [string]$MsExcel = "application/vnd.ms-excel"
  static [string]$MsExcelXlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  static [string]$MsPowerpoint = "application/vnd.ms-powerpoint"
  static [string]$MsPowerpointPptx = "application/vnd.openxmlformats-officedocument.presentationml.presentation"

  static [string]$FontWoff = "font/woff"
  static [string]$FontWoff2 = "font/woff2"
  static [string]$FontTtf = "font/ttf"
  static [string]$FontOtf = "font/otf"


  ContentType([string] $value) {
    $this.Value = $value
  }
  
  static [ContentType] FromExt([string]$ext, [bool]$allowDefault) { 
    $ct = switch ($ext.TrimStart('.')) {

      'html' { [ContentType]::TextHTML }
      'htm' { [ContentType]::TextHTML }
      'txt' { [ContentType]::TextPlain }
      'css' { [ContentType]::TextCSS }
      'js' { [ContentType]::TextJavascript }
      'mjs' { [ContentType]::TextJavascript }
      'csv' { [ContentType]::TextCSV }
      'xml' { [ContentType]::TextXML }
      'md' { [ContentType]::TextMarkdown }

      'json' { [ContentType]::AppJSON }
      'pdf' { [ContentType]::AppPDF }
      'zip' { [ContentType]::AppZip }
      'gz' { [ContentType]::AppGzip }
      'xhtml' { [ContentType]::AppXhtml }
      'sql' { [ContentType]::AppSql }
      'wasm' { [ContentType]::AppWasm }

      'png' { [ContentType]::ImgPng }
      { $_ -match 'jpe?g' } { [ContentType]::ImgJpeg }
      'gif' { [ContentType]::ImgGif }
      'webp' { [ContentType]::ImgWebp }
      'svg' { [ContentType]::ImgSvg }
      'ico' { [ContentType]::ImgIco }
      'bmp' { [ContentType]::ImgBmp }
      { $_ -match 'tiff?' } { [ContentType]::ImgTiff }
  
      'mp3' { [ContentType]::AudioMpeg }
      'wav' { [ContentType]::AudioWav }
      { $_ -match 'og[ag]' } { [ContentType]::AudioOgg }
      'weba' { [ContentType]::AudioWebm }
      'aac' { [ContentType]::AudioAac }

      'mp4' { [ContentType]::VideoMp4 }
      'webm' { [ContentType]::VideoWebm }
      'ogv' { [ContentType]::VideoOgg }
      'mpeg' { [ContentType]::VideoMpeg }
      'mov' { [ContentType]::VideoQuicktime }

      'doc' { [ContentType]::MsWord }
      'docx' { [ContentType]::MsWordDocx }
      'xls' { [ContentType]::MsExcel }
      'xlsx' { [ContentType]::MsExcelXlsx }
      'ppt' { [ContentType]::MsPowerpoint }
      'pptx' { [ContentType]::MsPowerpointPptx }

      'woff' { [ContentType]::FontWoff }
      'woff2' { [ContentType]::FontWoff2 }
      'ttf' { [ContentType]::FontTtf }
      'otf' { [ContentType]::FontOtf }

      default {
        if (-not $allowDefault) {
          throw "Unknown file extension: $ext"
        }
        [ContentType]::AppOctetStream
      }
    }
    return $ct
  }
  
  static [ContentType] FromExt([string]$ext) {
    return [ContentType]::FromExt($ext, $false)
  }

  static [ContentType] FromUrl([string]$url) {
    $ext = $url | Select-String -Pattern '\..{2,4}$' | Select-Object -ExpandProperty Matches -First 1
    if (-not $ext.value) { return [ContentType]::textHTML }
    return [ContentType]::FromExt($ext.value, $true)
  }


  [string] ToString() {

    $allowedList = [ContentType] | Get-Member -Static -MemberType Property | ForEach-Object {
      [ContentType]::($_.Name)
    }
    
    if ($this.value -notin $allowedList) {
      throw "'$($this.Value)' is not a valid ContentType."
    }
    return $allowedList | Where-Object { $_ -eq $this.value }
  }
}

enum Method {
  GET
  POST
  PUT
  PATCH
  DELETE
}
class WebServer {
  # Public State
  [bool] $isDisposed = $false

  # Core Infrastructure
  hidden [System.Net.HttpListener]                             $listener = [System.Net.HttpListener]::new()
  hidden [int16]                                               $port = 9001
  hidden [string]                                              $basePath = ((Get-Location).ProviderPath)
  hidden [System.Management.Automation.Runspaces.RunspacePool] $pool = $null
  hidden [System.Collections.Generic.List[scriptblock]]        $backgroundScripts = [System.Collections.Generic.List[scriptblock]]::new()

  # State & Data Collections
  hidden [hashtable]                                           $endpoints = [hashtable]::new()
  hidden [hashtable]                                           $store = [hashtable]::new()
  hidden [System.Collections.Generic.List[object]]             $jobs = $null

  # File System & Temp Storage
  hidden [string]                                              $pswsTempDir = $null
    


  WebServer([int16]$port, [string]$basePath) {
    $this.SetWebserver($port, $basePath)
  }

  WebServer([string]$basePath) {
    $this.SetWebserver($this.port, $basePath)
  }

  WebServer([int16]$port) {
    $this.SetWebserver($port, $this.basePath)
  }

  WebServer() {
    $this.SetWebserver($this.port, $this.basePath)
  }

  [void]SetWebserver([int16]$port, [string]$basePath) {

    if (-not ($basePath | Test-Path -PathType Container)) {
      throw "'$basePath' is not a directory, make sure the path exists"
    }
       

    $this.port = $port
    if ($basePath) {
      $this.setRoot($basePath)
    }

    $this.pool = [runspacefactory]::CreateRunspacePool(1, 10)
    $this.pool.Open()
    $this.jobs = [System.Collections.Generic.List[object]]::new()

        
    $this.GetClosestPort($this.port)
    $this.CreateListener()
  }


  [void] setRoot([string]$path) {
    if (-not (Test-Path $path -PathType Container)) {
      Write-Error -Message "No folder with the name of '$($path)'"
      return 
    }
    $this.basePath = (Get-Item -Path $path).FullName
  }

  [void]setPort([int16]$port) {
    if ($this.port -eq $port) {
      Write-Host "Port is already set to $port, skipping"
      return
    }
    $this.port = $port
  }

  [void]RegisterBackgroundScript([scriptblock]$scriptBlock) {
    $this.backgroundScripts.Add($scriptBlock)
  }


  [void] hidden GetClosestPort([int16]$port) {
    if (Get-NetTCPConnection | Where-Object LocalPort -EQ $port) {
      Write-Warning "Port $port is already in use, finding the next available"
      while (Get-NetTCPConnection | Where-Object LocalPort -EQ $port) {
        $port++
      }
    }
    if ($this.port -ne $port) {
      $this.port = $port
      Write-Host "New port: $port"
    }
  }

  [void] hidden GetClosestPort() {
    $this.GetClosestPort($this.port)
  }

  [int16]FindAndSetClosestPort() {
    $this.GetClosestPort()
    return $this.port
  }


  [hashtable] GetEndpoint([string]$name) {
    $name = $name -replace '^/?', '/'
    if (-not $this.endpoints.$name) {
      return $null
    }
    return $this.endpoints.$name
  }

  [void] SetEndpoint([string]$name, [scriptblock]$callBack, [Method[]]$methods, [string]$contentType) {
    $name = $name -replace '^/?', '/'
    $this.endpoints.$name = @{
      callback    = $callBack
      methods     = $methods
      ContentType = $contentType
    }
  }



  [void] ListEndpoints([string]$type, [bool]$includeStatic) {

    $files = Get-ChildItem -Path $this.basePath -Recurse -File
        
    $staticFiles = @()
    $pages = @()
    $api = @()

    foreach ($file in $files) {
      $relativePath = $file.FullName -replace [Regex]::Escape($this.basePath) -replace '\\', '/'
      if ($relativePath -match "^/Pages/.*\.html?$") {
        $pages += $relativePath -replace '/Pages(.*?)(?:index)?\.html?$', '$1'
        continue
      }
      if ($relativePath -match "^/API/.*\.ps[me]?1$") {
        $api += $relativePath -replace "\.ps[me]?1$"
        continue
      }
      $staticFiles += $relativePath
    }
        
    foreach ($key in $this.endpoints.Keys) {
      if ($key -match '^/API/.*ps[me]?1') {
        $api += $key
        continue
      }
      $pages += $key
    }

    if ($type -in ('All', 'Pages')) {
      $pagesText = if ($pages.Count) { $pages -join "`n" } else { "No pages found" }
      Write-Host "Pages:`n$($pagesText)`n" -ForegroundColor Magenta

    }
    if ($type -in ('All', 'API')) {
      $apiText = if ($api.Count) { $api -join "`n" } else { "No API's found" }
      Write-Host "APIs:`n$($apiText -join "`n")`n" -ForegroundColor Cyan
    } 
    if ($includeStatic) {
      $staticText = if ($staticFiles.Count) { $staticFiles -join "`n" } else { "No static files found" }
      Write-Host "Static files:`n$staticText" -ForegroundColor DarkYellow
    }
  }

  [void] ListEndpoints([string]$type) {
    $this.ListEndpoints($type, $false)
  }

  [void] ListEndpoints([bool]$includeStatic) {
    $this.ListEndpoints('All', $includeStatic)  
  }

  [void] ListEndpoints() {
    $this.ListEndpoints('All', $false)
  }


  [void] GetPagesEndpoints() {
    $this.GetEndpoints('Pages', 'html', [System.ConsoleColor]::Magenta, 'Page')
  }

  [void] GetAPIEndpoints() {
    $this.GetEndpoints('API', 'ps[me]?1', [System.ConsoleColor]::Cyan, 'API')
  }

  [hashtable] NewRequest([System.Net.HttpListenerContext]$context) {
    $req = $context.Request
    $newRequest = @{
      context   = $context
      store     = $this.store
      query     = @{}
      body      = @{}
      endpoints = $this.endpoints
      basePath  = (Get-Item $this.basePath).FullName
      #ContentType = [ContentType]::FromUrl($context.Request.Url.AbsolutePath).ToString()
    }  

    
    $newRequest.context.Response.ContentType = [ContentType]::FromUrl($context.Request.Url.AbsolutePath)

    $req.Url.Query -replace '^\?' -split '&' | ForEach-Object {
      $key, $value = $_ -split '='
      $newRequest.query.$key = [System.Net.WebUtility]::UrlDecode(($value -join '='))
    }

    if ($req.HasEntityBody) { try { $newRequest.body = [System.IO.StreamReader]::new($context.Request.InputStream).ReadLine() | ConvertFrom-Json }catch {} }
    return $newRequest
  }

  [void]CreateListener() {
    if (!$this.listener.IsListening) {
      $this.listener.Prefixes.Add("http://localhost:$($this.port)/")
    }
  }
    
  [void] hidden InvokeRequest($requestInfo) {
    $requestJob = . "$PSScriptRoot/requestJob.ps1"
    $ps = [powershell]::Create()
    $ps.RunspacePool = $this.pool
    $ps.AddScript($requestJob).AddParameter('requestInfo', $requestInfo) | Out-Null
    $async = $ps.BeginInvoke()
    $this.jobs.Add([PSCustomObject]@{
        PS    = $ps
        Async = $async
      })        
  }

  [void]Start() {

    try {
      $this.listener.Start()
      if ($this.isDisposed) {
        throw [ObjectDisposedException]::new([WebServer].Name)
        return
      }
      $TreatControlCAsInput = [System.Console]::TreatControlCAsInput
      $_Host = Get-Host
      [System.Console]::TreatControlCAsInput = $true

      Write-Host "Server started on http://localhost:$($this.port)/" -ForegroundColor Green

      while ($this.listener.IsListening) {
        $contextTask = $this.listener.GetContextAsync()
        while (-not $contextTask.AsyncWaitHandle.WaitOne(200)) {
                    
          if ($_Host.UI.RawUI.KeyAvailable) {
            $key = $_Host.UI.RawUI.ReadKey("AllowCtrlC,NoEcho,IncludeKeyUp")
                        
            switch ($key.VirtualKeyCode) {
              67 {
                $this.listener.stop()
              }
              76 {
                $this.ListEndpoints()
              }
            }
          }

          foreach ($script in $this.backgroundScripts) {
            try {
              . $script -store $this.store -root $this.basePath
            }
            catch {}
          }
          foreach ($job in $this.jobs | Where-Object { $_.Async.IsCompleted } ) {
            $result = $job.ps.EndInvoke($job.Async)
            if ($result -eq 'STOP') {
              $this.Dispose()
              return
            }

            if ($result) {
              write-host $result
            }
    
            [void]$this.jobs.Remove($job)
          }
        }
        
        if (-not $this.listener.IsListening) {
          return
        }
        $context = $contextTask.GetAwaiter().GetResult()
         
        $newRequest = $this.NewRequest($context)
        $this.InvokeRequest($newRequest)       
      }
    }
    finally {
      [System.Console]::TreatControlCAsInput = $TreatControlCAsInput
    }
  }



  [void]Close() {
    $this.listener.Close()
  }

  [void]Dispose() {
    $this.close()
    $this.listener.Dispose()
    foreach ($job in $this.jobs) {
      $job.Dispose()
    }
    $this.pool.Dispose()
    $this.isDisposed = $true
  }
}


<#
.SYNOPSIS
  Exposed function to create and start a new WebServer
.DESCRIPTION
  Exposed function to create and start a new WebServer, allowing setting port number, initial path, autostart with or without headless browser (Edge)
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
  param(
    [int16]$port = 3000, 
    [string]$path, 
    [scriptblock[]]$backgroundScripts,
    [hashtable]$store,
    [switch]$autoStart, 
    [switch]$autostartAsApp,
    [switch]$disposeOnClose
  )


  $ws = [WebServer]::new($port)
        
        
  if ($path) {
    $ws.SetRoot($path)
  }
  if ($store) {
    $ws.store = $store
  }
        
  foreach ($bgScript in $backgroundScripts) {
    $ws | Register-backgroundScript -scriptblock $bgScript
  }
        
  if ($autoStart -or $autostartAsApp) {
    $ws | Start-WebServer -asApp:$autostartAsApp -autoDispose:$disposeOnClose
  }

  return $ws
}

function Start-WebServer {
  param (
    [Parameter(ValueFromPipeline)]
    [WebServer]$webserver,
    [switch]$asApp,
    [switch]$autoDispose
  )

  $TreatControlCAsInput = [System.Console]::TreatControlCAsInput
  [System.Console]::TreatControlCAsInput = $true

  [int]$appModePid = $null
  [string]$pswsTempDir = $null
        
        
  if ($asApp) {
    $pswsTempDir = Join-Path -Path $env:TEMP -ChildPath "PSWS_$(Get-Random 10000)"
    $port = $webserver.FindAndSetClosestPort()
    $appModePid = (Start-Process -FilePath (Get-ItemProperty -ErrorAction Stop -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe\')."(default)" -ArgumentList "--app=http://localhost:$port", "--user-data-dir=$($pswsTempDir)", '--disable-extensions' -PassThru).Id
                
    if ($autoDispose) {
      $webserver | Register-backgroundScript -ScriptBlock {   
        if (-not (Get-Process -Id $appModePid -ErrorAction SilentlyContinue) -and $autoDispose) {
          $webserver.Close()
        }
      }
    }
  }
        
  $webserver.Start()

  if ($autoDispose) {
    $webserver.dispose()
  }
  if ($appModePid) {
    $process = (Stop-Process $appModePid -ErrorAction SilentlyContinue -PassThru ) | Get-Process
    if ($process) {
      $process.WaitForExit()
    }
  }
  if ($pswsTempDir) {
    Remove-Item $pswsTempDir -Force -Recurse          
  }
  [System.Console]::TreatControlCAsInput = $TreatControlCAsInput
  return $webserver

  

}


function Add-Endpoint {
  param(
    [Parameter(ValueFromPipeline)]
    [WebServer]$webserver, 
    [string]$name, 
    [scriptblock]$callBack = {}, 
    [Method[]]$methods = "GET", 
    [ContentType]$ContentType = [ContentType]::textHTML
  )

  if ($webserver.GetEndpoint($name)) { return Write-Warning "Endpoint with name '$name' already exists on this WebServer use Update-Endpoint instead" }
    

  return $webserver.SetEndpoint($name, $callBack, $methods, $ContentType)
}

function Update-Endpoint {
  param(
    [Parameter(ValueFromPipeline)]
    [WebServer]$webserver,
    [string]$name,
    [scriptblock]$callBack = {},
    [Method[]]$methods,
    [ContentType]$ContentType
  )

  $endpoint = $webserver.GetEndpoint($name)

  if (-not $endpoint) { Write-Warning "Endpoint with name '$name' does not exist on this WebServer, use Add-Endpoint instead" }

  if ($callBack) {
    $endpoint.callback = $callback
  }

  if ($methods) {
    $endpoint.methods = $methods
  }

  if ($contentType) {
    $endpoint.ContentType = $ContentType
  }
}

function Show-Endpoints {
  param (
    [Parameter(ValueFromPipeline, Mandatory)]
    [WebServer]$WebServer,
    [ValidateNotNullOrEmpty()]
    [ValidateSet('API', 'Pages', 'All')]$type = 'All',
    [switch]$includeStaticFiles
  )

  $WebServer.ListEndpoints($type, [bool]$includeStaticFiles)

}


function Register-backgroundScript {
  param (
    [Parameter(ValueFromPipeline)]
    [WebServer]$webserver,
    [scriptblock]$scriptBlock
  )
    
  $webserver.RegisterBackgroundScript($scriptBlock)
}