$ErrorActionPreference = "Stop"
$root = (Resolve-Path $PSScriptRoot).Path
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 8000)

try {
    $listener.Start()
    Write-Host ""
    Write-Host "=========================================="
    Write-Host " LAB 11 - React ExpenseFlow"
    Write-Host " Адрес: http://127.0.0.1:8000"
    Write-Host " Для остановки нажмите CTRL+C"
    Write-Host "=========================================="
    while ($listener.Pending() -or $true) {
        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $stream.ReadTimeout = 5000
            $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
            $requestLine = $reader.ReadLine()
            if ([string]::IsNullOrWhiteSpace($requestLine)) { $client.Close(); continue }
            $parts = $requestLine.Split(" ")
            $requestPath = [Uri]::UnescapeDataString(($parts[1] -split '\?')[0])
            if ($requestPath -eq "/") { $requestPath = "/index.html" }
            $relative = $requestPath.TrimStart("/") -replace '/', [IO.Path]::DirectorySeparatorChar
            $fullPath = [IO.Path]::GetFullPath([IO.Path]::Combine($root, $relative))
            if (-not $fullPath.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
                $status = "404 Not Found"
                $body = [Text.Encoding]::UTF8.GetBytes("404 - File not found")
                $contentType = "text/plain; charset=utf-8"
            } else {
                $status = "200 OK"
                $ext = [IO.Path]::GetExtension($fullPath).ToLowerInvariant()
                $contentType = switch ($ext) {
                    ".html" { "text/html; charset=utf-8" }
                    ".css"  { "text/css; charset=utf-8" }
                    ".js"   { "text/javascript; charset=utf-8" }
                    ".jsx"  { "text/plain; charset=utf-8" }
                    ".json" { "application/json; charset=utf-8" }
                    ".svg"  { "image/svg+xml" }
                    default { "application/octet-stream" }
                }
                $body = [IO.File]::ReadAllBytes($fullPath)
            }
            $header = "HTTP/1.1 $status`r`nContent-Type: $contentType`r`nContent-Length: $($body.Length)`r`nConnection: close`r`nAccess-Control-Allow-Origin: *`r`n`r`n"
            $headerBytes = [Text.Encoding]::ASCII.GetBytes($header)
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Write($body, 0, $body.Length)
            $stream.Flush()
        } catch {
            Write-Host "Ошибка запроса: $($_.Exception.Message)"
        } finally {
            $client.Close()
        }
    }
} catch {
    Write-Host "Не удалось запустить сервер на порту 8000: $($_.Exception.Message)"
    Write-Host "Возможно, порт занят. Закройте другое приложение на порту 8000 и повторите."
    Read-Host "Нажмите Enter для выхода"
} finally {
    $listener.Stop()
}
