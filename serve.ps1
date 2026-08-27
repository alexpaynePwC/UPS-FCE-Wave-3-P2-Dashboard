# Local preview of the dashboard. Open http://127.0.0.1:8080/
$port = 8080
$root = $PSScriptRoot
$prefix = "http://127.0.0.1:$port/"
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Dashboard running at $prefix"
Write-Host "Press Ctrl+C to stop."
Start-Process $prefix
$mime = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".svg"  = "image/svg+xml"
  ".png"  = "image/png"
  ".ico"  = "image/x-icon"
}
try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $path = $ctx.Request.Url.LocalPath.TrimStart("/")
    if ([string]::IsNullOrWhiteSpace($path) -or $path.EndsWith("/")) { $path += "index.html" }
    $file = Join-Path $root $path
    try {
      if (Test-Path -LiteralPath $file -PathType Leaf) {
        $ext = [IO.Path]::GetExtension($file).ToLowerInvariant()
        $bytes = [IO.File]::ReadAllBytes($file)
        $ctx.Response.ContentType = $mime[$ext]
        if (-not $ctx.Response.ContentType) { $ctx.Response.ContentType = "application/octet-stream" }
        $ctx.Response.ContentLength64 = $bytes.Length
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      } else {
        $ctx.Response.StatusCode = 404
        $msg = [Text.Encoding]::UTF8.GetBytes("Not found")
        $ctx.Response.ContentLength64 = $msg.Length
        $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
      }
    } catch {
      $ctx.Response.StatusCode = 500
    } finally {
      $ctx.Response.Close()
    }
  }
} finally {
  $listener.Stop()
}
