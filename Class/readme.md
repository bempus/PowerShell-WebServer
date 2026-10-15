# PowerShell-WebServer

A lightweight PowerShell web server supporting dynamic endpoints, static file hosting, background tasks, browser app mode, and shared application state.

# Quick Start

```
Import-Module PowerShell-WebServer

$server = New-WebServer -Port 9001

$server |
    Add-Endpoint `
        -Name "/" `
        -Callback { "Hello World" }

$server | Start-WebServer

```

Visit `http://localhost:9001` in your browser.

# Functions

## New-WebServer

Creates a new WebServer instance.

### Syntax

```
New-WebServer `
    [-Port <int16>] `
    [-Path <string>] `
    [-BackgroundScripts <scriptblock[]>] `
    [-Store <hashtable>] `
    [-AutoStart] `
    [-AutostartAsApp] `
    [-DisposeOnClose]

```

### Parameters

| Parameter           | Description                                                              |
| ------------------- | ------------------------------------------------------------------------ |
| `Port`              | Port the server should listen on. Default: `3000`                        |
| `Path`              | Root folder used for pages, APIs, and static files                       |
| `BackgroundScripts` | One or more scriptblocks executed repeatedly while the server is running |
| `Store`             | Hashtable shared across all requests                                     |
| `AutoStart`         | Starts the webserver immediately                                         |
| `AutostartAsApp`    | Starts the webserver and opens it in Microsoft Edge app mode             |
| `DisposeOnClose`    | Automatically disposes resources when the server closes                  |

### Examples

#### Basic Server with Path

```
$server = New-WebServer `
    -Port 9001 `
    -Path "C:\Website"

```

#### Shared State Server

```
$server = New-WebServer `
    -Store @{
        Visits = 0
    }

```

## Start-WebServer

Starts an existing WebServer instance.

### Syntax

```
$server | Start-WebServer

```

### Parameters

| Parameter     | Description                                     |
| ------------- | ----------------------------------------------- |
| `AsApp`       | Opens the website in Microsoft Edge app mode    |
| `AutoDispose` | Automatically disposes the server when it stops |

### Examples

#### Standard Start

```
$server | Start-WebServer

```

#### Run as Desktop App with Auto-Cleanup

```
$server |
    Start-WebServer `
        -AsApp `
        -AutoDispose

```

## Add-Endpoint

Registers a new dynamic endpoint route.

### Syntax

```
$server |
    Add-Endpoint `
        -Name <string> `
        -Callback <scriptblock> `
        [-Methods <Method[]>] `
        [-ContentType <ContentType>]

```

### Parameters

| Parameter     | Description                                         |
| ------------- | --------------------------------------------------- |
| `Name`        | Route path                                          |
| `Callback`    | Scriptblock executed when the endpoint is requested |
| `Methods`     | Allowed HTTP methods                                |
| `ContentType` | Response MIME type                                  |

### Examples

#### Simple Text Endpoint

```
$server |
    Add-Endpoint `
        -Name "/" `
        -Callback {
            "Hello World"
        }

```

#### JSON API Endpoint

```
$server |
    Add-Endpoint `
        -Name "/api/time" `
        -Methods GET `
        -ContentType ([ContentType]::ApplicationJSON) `
        -Callback {
            @{
                Time = Get-Date
            } | ConvertTo-Json
        }

```

#### Multiple Methods

```
$server |
    Add-Endpoint `
        -Name "/api/users" `
        -Methods @(
            [Method]::GET,
            [Method]::POST
        ) `
        -Callback {
            "User endpoint"
        }

```

## Update-Endpoint

Updates an existing endpoint configuration.

### Syntax

```
$server |
    Update-Endpoint `
        -Name <string> `
        [-Callback <scriptblock>] `
        [-Methods <Method[]>] `
        [-ContentType <ContentType>]

```

### Examples

#### Update Callback

```
$server |
    Update-Endpoint `
        -Name "/api/time" `
        -Callback {
            "Updated response"
        }

```

#### Change Content Type

```
$server |
    Update-Endpoint `
        -Name "/data" `
        -ContentType ([ContentType]::ApplicationJSON)

```

## Show-Endpoints

Displays registered endpoints.

### Syntax

```
$server | Show-Endpoints

```

### Parameters

| Parameter            | Description                         |
| -------------------- | ----------------------------------- |
| `Type`               | Filter by `All`, `Pages`, or `API`  |
| `IncludeStaticFiles` | Includes static files in the output |

### Examples

```
# Show everything
$server | Show-Endpoints

# Show only API endpoints
$server | Show-Endpoints -Type API

# Include static files
$server | Show-Endpoints -IncludeStaticFiles

```

## Register-BackgroundScript

Registers a scriptblock that runs continuously while the server is active.

### Syntax

```
$server |
    Register-BackgroundScript `
        -ScriptBlock <scriptblock>

```

### Parameters

| Parameter     | Description                                     |
| ------------- | ----------------------------------------------- |
| `ScriptBlock` | Code executed repeatedly during the server loop |

### Examples

#### Heartbeat Logging

```
$server |
    Register-BackgroundScript {
        Write-Host "Heartbeat"
    }

```

#### Periodic State Update

```
$server |
    Register-BackgroundScript {
        param($store)
        $store.LastUpdated = Get-Date
    }

```

# Interactive Server Console Shortcuts

While the server is running and actively listening in the PowerShell console, you can use the following key shortcuts to control or inspect it in real-time:

| Virtual Key Code | Key / Shortcut | Action                                   |
| ---------------- | -------------- | ---------------------------------------- |
| `67`             | `CTRL + C`     | Stops the web server listener            |
| `76`             | `L`            | Lists all currently registered endpoints |

---

# File-Based Routing & Page Requests

When configured with a root `-Path` (e.g., `C:\Website`), the server supports automatic file-based routing alongside manual endpoints.

### Directory Structure Example

```
C:\Website\
│
├── index.html          # Served at root http://localhost:9001/
├── style.css           # Static file served directly
├── Pages\
│   ├── about.html      # Served at http://localhost:9001/about
│   └── contact.html    # Served at http://localhost:9001/contact
├── api\
│   └── status.ps1      # Dynamic script served at http://localhost:9001/api/status
└── 404.html            # Custom fallback error page

```

### How the Request Handler Works

The request execution script processes requests in the following order:

1. **Registered Endpoints**: Checks if an explicit scriptblock route was added via `Add-Endpoint`.

2. **Static Files**: Checks if a direct file match exists under the root path (e.g., images, CSS, JavaScript).

3. **HTML Pages**: Looks inside a `Pages\` subfolder for `.html` or `.htm` files matching the requested route (supporting directory indexes automatically).

4. **Dynamic API Scripts**: Looks for `.ps1`, `.psm1`, or `.pse1` files to execute dynamically.

5. **404 Fallback**: Triggers the `/404` endpoint, `404.html`, or `404.ps1` if no matching route is found.

# File Examples

### Example HTML Page (`C:\Website\Pages\about.html`)

```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>About Us</title>
    <link rel="stylesheet" href="/style.css">
</head>
<body>
    <h1>About Our PowerShell Web Server</h1>
    <p>This static page is automatically served from the Pages directory.</p>
</body>
</html>

```

### Example PowerShell API Script (`C:\Website\api\status.ps1`)

```
param(
    $body,
    $query,
    $method,
    $store,
    $request,
    $basePath
)

# Access shared application state
if ($null -ne $store.Visits) {
    $store.Visits++
}

# Return an object that automatically serializes to JSON
return @{
    Status      = "Online"
    ServerTime  = (Get-Date)
    TotalVisits = $store.Visits
    Method      = $method
    QueryParam  = $query.name
}

```

# Available Script Parameters

When writing dynamic scriptblocks or script files (`.ps1`), the request handler automatically injects the following context parameters:

| Parameter   | Description                          |
| ----------- | ------------------------------------ |
| `$body`     | Incoming request body                |
| `$query`    | Query string parameters              |
| `$method`   | HTTP method used (GET, POST, etc.)   |
| `$store`    | Shared application hashtable store   |
| `$request`  | Raw HTTP listener request object     |
| `$basePath` | Root directory path of the webserver |

# Pipeline Support & Typical Setup

Most functions support pipeline chaining:

```
$server = New-WebServer `
    -Port 9001 `
    -Path "C:\Website" `
    -Store @{
        Requests = 0
    }

$server |
    Add-Endpoint `
        -Name "/" `
        -Callback {
            "Server Online"
        }

$server |
    Register-BackgroundScript {
        param($store)$store.LastHeartbeat = Get-Date
    }

$server | Start-WebServer
```
