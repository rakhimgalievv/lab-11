@echo off
setlocal
chcp 65001 >nul
title Lab 11 - React ExpenseFlow
cd /d "%~dp0"

echo Запуск локального сервера...
where powershell.exe >nul 2>nul
if errorlevel 1 (
  echo ОШИБКА: Windows PowerShell не найден.
  pause
  exit /b 1
)

REM Запускаем встроенный сервер PowerShell в отдельном окне.
start "Lab 11 Server" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"

REM Ждём, пока сервер начнёт принимать подключения.
powershell.exe -NoProfile -Command "$ready=$false; for($i=0;$i -lt 20;$i++){ try{$c=New-Object Net.Sockets.TcpClient; $c.Connect('127.0.0.1',8000); $c.Close(); $ready=$true; break}catch{Start-Sleep -Milliseconds 500} }; if(-not $ready){exit 1}"
if errorlevel 1 (
  echo.
  echo Сервер не запустился. Проверьте окно "Lab 11 Server".
  pause
  exit /b 1
)

start "" "http://127.0.0.1:8000"
echo Браузер открыт. Сервер работает в отдельном окне.
echo Чтобы остановить сервер, закройте окно "Lab 11 Server".
exit /b 0
