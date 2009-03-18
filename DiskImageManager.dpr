program DiskImageManager;

uses
  Forms,
  DskImage in 'DskImage.pas',
  About in 'About.pas' {frmAbout},
  Options in 'Options.pas' {frmOptions},
  Utils in 'Utils.pas',
  New in 'New.pas' {frmNew},
  SectorProperties in 'SectorProperties.pas' {frmSector},
  Main in 'Main.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Disk Image Manager';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
