@echo off
setlocal

if not defined PORT set "PORT=20128"
set "FOUND_PID="

for /f "tokens=5" %%P in ('netstat -ano ^| findstr /r /c:":%PORT% .*LISTENING"') do (
  set "FOUND_PID=1"
  echo Dang dung tien trinh PID %%P tren cong %PORT%...
  taskkill /PID %%P /T /F >nul 2>&1
)

if not defined FOUND_PID (
  echo Khong tim thay tien trinh nao dang lang nghe tren cong %PORT%.
  exit /b 0
)

echo Da gui lenh dung 9Router.
