program DiskImageManager;

{$MODE Delphi}

uses
  Forms, Interfaces,
  DskImage in 'DskImage.pas',
  Utils in 'Utils.pas',
  About in 'About.pas' {frmAbout},
  Options in 'Options.pas' {frmOptions},
  New in 'New.pas' {frmNew},
  SectorProperties in 'SectorProperties.pas' {frmSector},
  Main in 'Main.pas' {frmMain};

begin
  Application.Initialize;
  Application.Title := 'Disk Image Manager';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
