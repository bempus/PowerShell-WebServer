

return { param($requestInfo)
  Set-Location -Path $requestInfo.basePath
  $context = $requestInfo.Context
  $script:encoding = [System.Text.Encoding]::Default


  function Get-WebPathItem {
    param($path, $endpoint, [string[]]$extentions, [switch]$isPage)

    if ($isPage) {
      $endpoint = Join-Path -Path 'Pages' -ChildPath $endpoint
    }
    $fullPath = (Join-Path -Path $path -ChildPath  $endpoint)
                   
    if (Test-Path -Path $fullPath -PathType Container) {
      $fullPath = $fullPath | Join-Path -ChildPath 'index'
    }
    foreach ($ext in $extentions) {
      $item = Get-Item -Path "$fullPath.$ext" -ErrorAction SilentlyContinue
      if ($item) { return $item }
    }                
  }

  function Set-EncodingFromFile {
    param(
      [Parameter(Mandatory)]  
      [string]$path
    ) 
    try {
      $reader = [System.IO.StreamReader]::new($path, $true)
      if ($reader.Peek() -ge 0) {
        $null = $reader.Read()
      }
      
      

      switch ($reader.CurrentEncoding.HeaderName) {
        'utf-8' {
          $script:encoding = [System.Text.Encoding]::UTF8
        }
        default {
          $script:encoding = [System.Text.Encoding]::Default
        }
      }
    }
    catch {
      Throw $_
    }
    finally {
      if ($reader) {
        $reader.Close()
      }
    }

  } 

  function Get-Bytes {
    param (
      $InputObject,
      [System.Text.Encoding]$encoding = [System.Text.Encoding]::Default
    )

    if (-not ($InputObject -is [string])) {
      $InputObject = $InputObject | ConvertTo-Json
    }

    if (-not $InputObject) {
      return $null
    }

    return $encoding.GetBytes($InputObject)
  }


  function Invoke-ScriptBlock {
    param($scriptblock)
    return & $scriptblock -body $requestInfo.body -query $requestInfo.query -method $Context.Request.HttpMethod  -store $requestInfo.store -request $Context.Request -basePath $requestInfo.basePath
  }

  function Invoke-WebPathItem {
            
    if ( $requestInfo.endpoints.($context.Request.Url.AbsolutePath)) {
      try {
        $endpoint = $requestInfo.endpoints.($context.Request.Url.AbsolutePath)
        return Invoke-ScriptBlock -scriptblock $endpoint.callback
      }
      catch {}
    }

    $staticFile = Join-Path -Path $requestInfo.basePath -ChildPath $context.Request.Url.AbsolutePath

    if (Test-Path -Path $staticFile -PathType Leaf) {
      $script:encoding = [System.Text.Encoding]::UTF8
      try {
        return Get-Content -Path $staticFile -Raw -Encoding UTF8
      }
      catch {
        $context.Response.Status = 500
        return "Error loading page: $($_.Exception.Message)"
      }
    }

    $pageItem = Get-WebPathItem -path $requestInfo.basePath -endpoint "$($context.Request.Url.AbsolutePath)" -extentions 'html', 'htm' -isPage
    if ($pageItem) {
      $script:encoding = [System.Text.Encoding]::UTF8

      return Get-Content -Path $pageItem -Raw -Encoding UTF8
    }


    $apiItem = Get-WebPathItem -path $requestInfo.basePath -endpoint "$($context.Request.Url.AbsolutePath)" -extentions 'ps1', 'psm1', 'pse1'
    if ($apiItem) {
      try {
        $script:encoding = [System.Text.Encoding]::UTF8
        return Invoke-ScriptBlock -scriptblock $apiItem.FullName
      }
      catch {
        return $_.Exception.Message
      }
    }
    
    $context.Response.statusCode = 404

    $404 = $requestInfo.endpoints.'/404' 

    if ($404) {
      $script:encoding = [System.Text.Encoding]::Default
      return Invoke-ScriptBlock -scriptblock $404.callback
    }
                    
        
    $404 = Join-Path -Path $requestInfo.basePath -ChildPath '404.html'
    if (Test-Path -path $404) {
      return Get-Content -Path $404 -Raw
    }
    
    $404 = Get-WebPathItem -Path $requestInfo.basePath -endpoint '404' -extentions 'ps1', 'psm1', 'pse1'
    if ($404) {          
      try {
        return Invoke-ScriptBlock -scriptblock $404.FullName              
      }
      catch {
        return $_.Exception.Message
      }
    }
    return "<div>404 - page not found</div>"
  }
            
         
  try {
    $requestInfo.result = Invoke-WebPathItem                
    if (-not $requestInfo.result) {
      $context.Response.StatusCode = '204'
      $requestInfo.Context.Response.Close()
      return 
    }
  
                
    $buffer = Get-Bytes -InputObject $requestInfo.result -encoding $script:encoding
    $requestInfo.Context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $requestInfo.Context.Response.Close()

    if ($context.Request.Url.AbsolutePath -eq '/$end') {
      return "STOP"     
    }
  }
  catch {
    $buffer = [System.Text.Encoding]::Default.GetBytes("500 - something went wrong: $($_.Exception.Message)")
    $requestInfo.Context.Response.StatusCode = 500
    $requestInfo.Context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $requestInfo.Context.Response.Close()
  }
    
  
}