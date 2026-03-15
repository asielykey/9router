@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "APP_DIR=%SCRIPT_DIR%app"

if not defined PORT set "PORT=20128"
if not defined HOSTNAME set "HOSTNAME=127.0.0.1"
if not defined NEXT_PUBLIC_BASE_URL set "NEXT_PUBLIC_BASE_URL=http://localhost:%PORT%"
set "NODE_ENV=production"
set "MITM_SERVER_PATH=%APP_DIR%\src\mitm\server.js"

if not exist "%APP_DIR%\server.js" (
  echo Khong tim thay runtime cua 9Router trong "%APP_DIR%".
  exit /b 1
)

if not exist "%APP_DIR%\node.exe" (
  echo Khong tim thay node.exe duoc dong kem trong "%APP_DIR%".
  exit /b 1
)

for /f "tokens=5" %%P in ('netstat -ano ^| findstr /r /c:":%PORT% .*LISTENING"') do (
  echo 9Router dang chay o cong %PORT% voi PID %%P.
  exit /b 0
)

echo Dang khoi dong 9Router o cong %PORT%...
cd /d "%APP_DIR%"
"%APP_DIR%\node.exe" "%APP_DIR%\server.js"
