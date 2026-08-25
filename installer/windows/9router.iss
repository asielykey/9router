#ifndef MyAppVersion
  #define MyAppVersion "0.0.0-dev"
#endif

#ifndef MySourceDir
  #error MySourceDir define is required.
#endif

#ifndef MyOutputDir
  #define MyOutputDir AddBackslash(SourcePath) + "..\build\windows\artifacts"
#endif

#ifndef MyDefaultPort
  #define MyDefaultPort "20128"
#endif

[Setup]
AppId={{D9B2A8B8-1D7B-4A1A-9A0E-0B27D4F15725}
AppName=9Router
AppVersion={#MyAppVersion}
AppVerName=9Router {#MyAppVersion}
DefaultDirName={autopf}\9Router
DefaultGroupName=9Router
OutputDir={#MyOutputDir}
OutputBaseFilename=9router-setup-v{#MyAppVersion}
SetupIconFile={#MySourceDir}\9router.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
DisableProgramGroupPage=yes
UninstallDisplayName=9Router
UninstallDisplayIcon={app}\9router.ico
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Tasks]
Name: "desktopicon"; Description: "Tao shortcut ngoai Desktop"; GroupDescription: "Tuy chon bo sung:"

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\9Router Dashboard"; Filename: "{app}\9router-background.vbs"; WorkingDir: "{app}"; IconFilename: "{app}\9router.ico"
Name: "{group}\9Router Terminal"; Filename: "{app}\9router.cmd"; WorkingDir: "{app}"; IconFilename: "{app}\9router.ico"
Name: "{group}\Dung 9Router"; Filename: "{app}\stop-9router.cmd"; WorkingDir: "{app}"; IconFilename: "{app}\9router.ico"
Name: "{group}\Go bo 9Router"; Filename: "{uninstallexe}"; IconFilename: "{app}\9router.ico"
Name: "{autodesktop}\9Router"; Filename: "{app}\9router-background.vbs"; WorkingDir: "{app}"; IconFilename: "{app}\9router.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\9router-background.vbs"; Description: "Mo 9Router ngay sau khi cai"; Flags: nowait postinstall skipifsilent
