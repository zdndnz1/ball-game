$gameDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8080/")

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript"
    ".css"  = "text/css"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".ico"  = "image/x-icon"
    ".wasm" = "application/wasm"
    ".bin"  = "application/octet-stream"
    ".binarypb" = "application/octet-stream"
}

try {
    $listener.Start()
    Write-Host "Server running at http://localhost:8080/" -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray

    while ($listener.IsListening) {
        $context  = $listener.GetContext()
        $request  = $context.Request
        $response = $context.Response

        $localPath = $request.Url.LocalPath -replace '/','\' -replace '^\\',''
        if ($localPath -eq '' -or $localPath -eq '\') { $localPath = 'index.html' }
        $filePath = Join-Path $gameDir $localPath

        Write-Host "$(Get-Date -Format 'HH:mm:ss') $($request.HttpMethod) $($request.Url.LocalPath)"

        if (Test-Path $filePath -PathType Leaf) {
            $ext  = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType   = $mime
            $response.ContentLength64 = $bytes.Length
            $response.StatusCode    = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $localPath")
            $response.StatusCode      = 404
            $response.ContentLength64 = $msg.Length
            $response.OutputStream.Write($msg, 0, $msg.Length)
        }
        $response.Close()
    }
} catch {
    Write-Error $_
} finally {
    $listener.Stop()
}
