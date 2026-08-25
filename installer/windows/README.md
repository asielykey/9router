# Windows Installer

Flow này đóng gói `9router` thành bộ cài `Setup.exe` trên Windows, không cần user copy tay các thư mục runtime nữa.

## Cách hoạt động

- Mặc định tải `9router@<version>` từ npm tarball
- Sửa lại `better-sqlite3` cho đúng binary Windows
- Vá runtime bundle để fix tunnel/cloudflared trước khi đóng gói
- Gom runtime vào `build\windows\staging`
- Copy luôn `node.exe` từ máy build hiện tại vào bộ cài
- Dùng Inno Setup 6 để sinh `Setup.exe`

## Lệnh dùng nhanh

```powershell
npm run build:win:portable
npm run build:win:installer
npm run build:win:source:portable
npm run build:win:source:installer
```

## Output

- Portable runtime: `build\windows\artifacts\9router-portable-v<version>.zip`
- Installer: `build\windows\artifacts\9router-setup-v<version>.exe`

## Yêu cầu

- Windows
- `node.exe` có sẵn trong `PATH`
- Nếu build từ source: chạy `npm install` trong repo trước
- Nếu muốn ra `Setup.exe`: cài **Inno Setup 6**

## Ghi chú

- Bộ cài sẽ đóng gói luôn `node.exe` của máy build hiện tại. Nếu bạn đang build bằng Node `x64`, máy đích cũng nên là Windows `x64`.
- Launcher `9router.cmd` có chặn chạy trùng theo cổng để giảm việc mở nhiều instance.
- Flow npm runtime sẽ tự vá `better-sqlite3` và chunk `9201.js` trước khi đóng gói.
- Flow source `build:win:source:*` sẽ tự đổi `HOME`, `USERPROFILE`, `APPDATA`, `LOCALAPPDATA` sang `.fakehome` trong repo khi build để tránh lỗi `Application Data` trên Windows.
- Bộ cài sẽ dùng `src\app\favicon.ico` làm icon cho `Setup.exe` và shortcut.

## Tuỳ chọn script

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-win-from-npm-package.ps1 -SkipInstaller
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-win-from-npm-package.ps1 -PackageVersion 0.3.54
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-win-installer.ps1 -RuntimeDir C:\path\to\runtime\app
```
