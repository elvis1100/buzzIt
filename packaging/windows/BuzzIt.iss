; Build with Inno Setup after running: flutter build windows
; Output: packaging\windows\output\BuzzItSetup.exe

#define AppName "BuzzIt"
#define AppVersion "1.0.0"
#define AppPublisher "BuzzIt"
#define ReleaseDir "..\..\build\windows\x64\runner\Release"

[Setup]
AppId={{C91A1A9B-6959-452D-AB74-C49BA8C7A8BB}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=BuzzItSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\BuzzIt.exe

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; Flags: unchecked

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\BuzzIt.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\BuzzIt.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\BuzzIt.exe"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent
