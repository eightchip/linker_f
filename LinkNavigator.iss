[Setup]
AppName=Link Navigator
AppVersion=1.0
DefaultDirName={autopf}\Link Navigator
DefaultGroupName=Link Navigator
UninstallDisplayIcon={app}\Link_Navigator.exe
OutputDir=.
OutputBaseFilename=LinkNavigatorInstaller
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\Link_Navigator.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; PowerShellスクリプトを {userappdata}\Apps にコピー
Source: "scripts\company_outlook_test.ps1"; DestDir: "{userappdata}\Apps"; Flags: ignoreversion
Source: "scripts\company_task_search.ps1"; DestDir: "{userappdata}\Apps"; Flags: ignoreversion
Source: "scripts\compose_mail.ps1"; DestDir: "{userappdata}\Apps"; Flags: ignoreversion
Source: "scripts\find_sent.ps1"; DestDir: "{userappdata}\Apps"; Flags: ignoreversion

[Icons]
Name: "{group}\Link Navigator"; Filename: "{app}\Link_Navigator.exe"
Name: "{group}\アンインストール Link Navigator"; Filename: "{uninstallexe}"
Name: "{userdesktop}\Link Navigator"; Filename: "{app}\Link_Navigator.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "デスクトップにショートカットを作成する"; GroupDescription: "追加タスク:"

[UninstallDelete]
Type: filesandordirs; Name: "{app}\data"




