unit Options;

{$MODE Delphi}

{
  Disk Image Manager -  Copyright 2002-2009 Envy Technologies Ltd.

  Options window
}

interface

uses
  DiskMap, Utils,
  Graphics, Forms, ComCtrls, StdCtrls, Classes, Controls, ExtCtrls, Registry, Dialogs;

type
  TfrmOptions = class(TForm)
    pnlButtons: TPanel;
    pagOptions: TPageControl;
    tabMain: TTabSheet;
    btnOK: TButton;
    btnCancel: TButton;
    tabSectors: TTabSheet;
    tabDiskMap: TTabSheet;
    lblFontMainLabel: TLabel;
    dlgFont: TFontDialog;
    edtFontMain: TEdit;
    btnFontMain: TButton;
    DiskMap: TSpinDiskMap;
    lblFontMapLabel: TLabel;
    edtFontMap: TEdit;
    btnFontMap: TButton;
    lblBackColorLabel: TLabel;
    lblGridColorLabel: TLabel;
    lblFontSectorLabel: TLabel;
    edtFontSector: TEdit;
    btnFontSector: TButton;
    lblTrackMarksLabel: TLabel;
    udTrackMarks: TUpDown;
    edtTrackMarks: TEdit;
    lblBytesLabel: TLabel;
    edtBytes: TEdit;
    udBytes: TUpDown;
    lblNonDisplayLabel: TLabel;
    edtNonDisplay: TEdit;
    chkRestoreWindow: TCheckBox;
    chkRestoreWorkspace: TCheckBox;
    btnReset: TButton;
    chkDarkBlankSectors: TCheckBox;
    cbxBack: TColorButton;
    cbxGrid: TColorButton;
    tabSaving: TTabSheet;
    chkWarnConversionProblems: TCheckBox;
    chkSaveRemoveEmptyTracks: TCheckBox;
    lblMapSave: TLabel;
    edtMapX: TEdit;
    edtMapY: TEdit;
    lblBy: TLabel;
    udMapX: TUpDown;
    udMapY: TUpDown;
    chkWarnSectorChange: TCheckBox;
    pnlTabs: TPanel;
    tabSamDisk: TTabSheet;
    chkSamDiskIntegration: TCheckBox;
    lblSamDiskLocation: TLabel;
    edtSamDiskLocation: TEdit;
    btnSamDiskLocation: TButton;
    dlgSamDiskLocation: TOpenDialog;
    procedure cbxBackChange(Sender: TObject);
    procedure cbxGridChange(Sender: TObject);
    procedure btnFontMainClick(Sender: TObject);
    procedure btnFontMapClick(Sender: TObject);
    procedure btnFontSectorClick(Sender: TObject);
    procedure edtTrackMarksChange(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure chkDarkBlankSectorsClick(Sender: TObject);
    procedure btnSamDiskLocationClick(Sender: TObject);
  private
    MainFont, SectorFont, MapFont: TFont;
    SamDiskLocation: string;
    procedure Read;
    procedure Write;
  public
    function Show: boolean;
  end;

var
  frmOptions: TfrmOptions;

implementation

uses Main;

{$R *.lfm}

procedure TfrmOptions.cbxBackChange(Sender: TObject);
begin
  DiskMap.Color := cbxBack.Color;
end;

procedure TfrmOptions.cbxGridChange(Sender: TObject);
begin
  DiskMap.GridColor := cbxGrid.Color;
end;

procedure TfrmOptions.btnFontMainClick(Sender: TObject);
begin
  with dlgFont do
  begin
    Font := MainFont;
    Options := Options - [fdFixedPitchOnly];
    if Execute then
    begin
      MainFont := Font;
      edtFontMain.Text := FontDescription(MainFont);
    end;
  end;
end;

procedure TfrmOptions.btnFontMapClick(Sender: TObject);
begin
  with dlgFont do
  begin
    Font := MapFont;
    Options := Options - [fdFixedPitchOnly];
    if Execute then
    begin
      MapFont := Font;
      edtFontMap.Text := FontDescription(MapFont);
      DiskMap.Font := MapFont;
    end;
  end;
end;

procedure TfrmOptions.btnFontSectorClick(Sender: TObject);
begin
  with dlgFont do
  begin
    Font := SectorFont;
    Options := Options + [fdFixedPitchOnly];
    if Execute then
    begin
      SectorFont := Font;
      edtFontSector.Text := FontDescription(SectorFont);
    end;
  end;
end;

function TfrmOptions.Show: boolean;
begin
  pagOptions.ActivePageIndex := 0;
  Read;
  Result := (ShowModal = mrOk);
  if Result then
    Write;
end;

procedure TfrmOptions.Read;
begin
  MainFont := FontCopy(frmMain.Font);
  SectorFont := FontCopy(frmMain.SectorFont);
  MapFont := FontCopy(frmMain.DiskMap.Font);
  edtFontMain.Text := FontDescription(MainFont);
  edtFontSector.Text := FontDescription(SectorFont);
  edtFontMap.Text := FontDescription(MapFont);
  chkRestoreWindow.Checked := frmMain.RestoreWindow;
  chkRestoreWorkspace.Checked := frmMain.RestoreWorkspace;
  udBytes.Position := frmMain.BytesPerLine;
  udTrackMarks.Position := frmMain.DiskMap.TrackMark;
  chkDarkBlankSectors.Checked := frmMain.DiskMap.DarkBlankSectors;
  edtNonDisplay.Text := frmMain.UnknownASCII;
  cbxBack.Color := frmMain.DiskMap.Color;
  cbxBackChange(Self);
  cbxGrid.Color := frmMain.DiskMap.GridColor;
  cbxGridChange(Self);
  chkWarnConversionProblems.Checked := frmMain.WarnConversionProblems;
  chkWarnSectorChange.Checked := frmMain.WarnSectorChange;
  chkSaveRemoveEmptyTracks.Checked := frmMain.RemoveEmptyTracks;
  udMapX.Position := frmMain.SaveMapX;
  udMapY.Position := frmMain.SaveMapY;
  chkSamDiskIntegration.Checked := frmMain.SamDiskEnabled;
  edtSamDiskLocation.Text := frmMain.SamDiskLocation;
end;

procedure TfrmOptions.Write;
begin
  with frmMain do
  begin
    frmMain.SectorFont := FontCopy(Self.SectorFont);
    frmMain.Font := FontCopy(Self.MainFont);
    DiskMap.Color := cbxBack.Color;
    DiskMap.DarkBlankSectors := chkDarkBlankSectors.Checked;
    DiskMap.GridColor := cbxGrid.Color;
    DiskMap.TrackMark := udTrackMarks.Position;
    DiskMap.Font := FontCopy(Self.MapFont);
    RestoreWindow := chkRestoreWindow.Checked;
    BytesPerLine := udBytes.Position;
    UnknownASCII := edtNonDisplay.Text;
    RestoreWorkspace := chkRestoreWorkspace.Checked;
    WarnConversionProblems := chkWarnConversionProblems.Checked;
    WarnSectorChange := chkWarnSectorChange.Checked;
    RemoveEmptyTracks := chkSaveRemoveEmptyTracks.Checked;
    SaveMapX := udMapX.Position;
    SaveMapY := udMapY.Position;
    SamDiskEnabled := chkSamDiskIntegration.Checked;
    SamDiskLocation := edtSamDiskLocation.Text;
  end;
end;

procedure TfrmOptions.edtTrackMarksChange(Sender: TObject);
begin
  DiskMap.TrackMark := udTrackMarks.Position;
end;

procedure TfrmOptions.btnResetClick(Sender: TObject);
var
  Reg: TRegIniFile;
begin
  Reg := TRegIniFile.Create(RegKey);
  Reg.EraseSection('DiskMap');
  Reg.EraseSection('SectorView');
  Reg.EraseSection('Window');
  Reg.EraseSection('Workspace');
  frmMain.LoadSettings;
  Read;
end;

procedure TfrmOptions.btnSamDiskLocationClick(Sender: TObject);
begin
  with dlgSamDiskLocation do
  begin
    FileName := SamDiskLocation;
    if Execute then
    begin
      SamDiskLocation := FileName;
      edtSamDiskLocation.Text := FileName;
    end;
  end;
end;

procedure TfrmOptions.chkDarkBlankSectorsClick(Sender: TObject);
begin
  DiskMap.DarkBlankSectors := chkDarkBlankSectors.Checked;
end;

end.