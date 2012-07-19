; this is a windows installer for sipper
; to create setup.exe you need the Inno Setup Compiler 5.2.2
; from http://www.jrsoftware.org
; Author : Nasir Khan

[Setup]
AppName=Sipper
AppVerName=Sipper 2.0.0
DefaultDirName={pf}\Sipper
DefaultGroupName=Sipper
Compression=lzma
SolidCompression=yes
OutputDir="C:\sipper_installer"
ChangesEnvironment=yes
LicenseFile=license.txt

[Files]
Source: "C:\sipper_installer\facets-1.8.54.gem"; DestDir: "{tmp}"
Source: "C:\sipper_installer\flexmock-0.7.1.gem"; DestDir: "{tmp}"
Source: "C:\sipper_installer\log4r-1.0.5.gem"; DestDir: "{tmp}"
Source: "C:\sipper_installer\rake-0.7.2.gem"; DestDir: "{tmp}"
Source: "C:\sipper_installer\Sipper-2.0.0.gem"; DestDir: "{tmp}"
Source: "C:\sipper_installer\i.rb"; DestDir: "{tmp}"
Source: "C:\sipper_installer\c.cmd"; DestDir: "{tmp}"
Source: "C:\sipper_installer\README.txt"; DestDir: "{app}"; Flags: isreadme
Source: "C:\sipper_installer\sgen.cmd"; DestDir: "{app}\bin";
Source: "C:\sipper_installer\srun.cmd"; DestDir: "{app}\bin";
Source: "C:\sipper_installer\sproj.cmd"; DestDir: "{app}\bin";
Source: "C:\sipper_installer\ssmoke.cmd"; DestDir: "{app}\bin";
Source: "C:\sipper_installer\supgrade.cmd"; DestDir: "{app}\bin";
Source: "C:\sipper_installer\license.txt"; DestDir: "{app}";


;[Run]
;Filename: "{app}\c.cmd";

[Tasks]
Name: modifypath; Description: Add SIPPER_HOME to your system path;

;[Icons]
;Name: "{group}\My Program"; Filename: "{app}\h.txt"



[Code]
procedure execute();
var
  ResultCode: Integer;
  S: String;

begin
  if Exec(ExpandConstant('{tmp}\c.cmd'), '', '', SW_SHOWMINIMIZED,
     ewWaitUntilTerminated, ResultCode) then

  begin
    LoadStringFromFile(ExpandConstant('{tmp}\sh.txt'), S)
    
    RegWriteStringValue(HKEY_CURRENT_USER, 'Environment',
    'SIPPER_HOME', S);
  end
  else begin
    // handle failure if necessary; ResultCode contains the error code
  end;
end;


function ModPathDir(): TArrayOfString;
var
    Dir: TArrayOfString;
begin
    execute();
    setArrayLength(Dir, 1)
    Dir[0] := ExpandConstant('{app}\bin');
    Result := Dir;
end;
#include "modpath.iss"
