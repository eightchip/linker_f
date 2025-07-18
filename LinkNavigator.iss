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

[Icons]
Name: "{group}\Link Navigator"; Filename: "{app}\Link_Navigator.exe"
Name: "{group}\アンインストール Link Navigator"; Filename: "{uninstallexe}"
Name: "{userdesktop}\Link Navigator"; Filename: "{app}\Link_Navigator.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "デスクトップにショートカットを作成する"; GroupDescription: "追加タスク:"

[UninstallDelete]
Type: filesandordirs; Name: "{app}\data"




