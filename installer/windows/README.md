# Windows Installer

Flow này đóng gói `9router` thành bộ cài `Setup.exe` trên Windows, không cần user copy tay các thư mục runtime nữa.

## Cách hoạt động

- Build `Next standalone`
- Gom đủ runtime cần chạy vào `build\windows\staging`
- Copy luôn `node.exe` từ máy build hiện tại vào bộ cài
- Dùng Inno Setup 6 để sinh `Setup.exe`

## Lệnh dùng nhanh

```powershell
npm run build:win:portable
npm run build:win:installer
```

## Output

- Portable runtime: `build\windows\artifacts\9router-portable-v<version>.zip`
- Installer: `build\windows\artifacts\9router-setup-v<version>.exe`

## Yêu cầu

- Windows
- `node.exe` có sẵn trong `PATH`
- Nếu muốn ra `Setup.exe`: cài **Inno Setup 6**

## Ghi chú

- Bộ cài sẽ đóng gói luôn `node.exe` của máy build hiện tại. Nếu bạn đang build bằng Node `x64`, máy đích cũng nên là Windows `x64`.
- Launcher `9router.cmd` có chặn chạy trùng theo cổng để giảm việc mở nhiều instance.
- Script có copy thêm `src\` để runtime MITM còn tìm được `src\mitm\server.js`.
- Bộ cài sẽ dùng `src\app\favicon.ico` làm icon cho `Setup.exe` và shortcut.

## Tuỳ chọn script

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-win-installer.ps1 -SkipInstaller
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-win-installer.ps1 -SkipBuild
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-win-installer.ps1 -NodeExePath C:\nvm\v20.20.0\node.exe
```
