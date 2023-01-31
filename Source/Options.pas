unit Options;

{$MODE Delphi}

{
  Disk Image Manager -  Options window

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  DiskMap, Utils, Settings,
  Graphics, Forms, ComCtrls, StdCtrls, Controls, ExtCtrls, Dialogs;

type

  { TfrmOptions }

  TfrmOptions = class(TForm)
    cboOpenView: TComboBox;
    lblDefaultView: TLabel;
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
    procedure cbxBackColorChanged(Sender: TObject);
    procedure btnFontMainClick(Sender: TObject);
    procedure btnFontMapClick(Sender: TObject);
    procedure btnFontSectorClick(Sender: TObject);
    procedure cbxGridColorChanged(Sender: TObject);
    procedure edtTrackMarksChange(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure chkDarkBlankSectorsClick(Sender: TObject);
  private
    FontMain, FontSector: TFont;
    Settings: TSettings;
    procedure Read;
    procedure Write;
  public
    constructor Create(Owner: TForm; Settings: TSettings); reintroduce;
    function Show: boolean;
  end;

var
  frmOptions: TfrmOptions;

implementation

{$R *.lfm}

constructor TfrmOptions.Create(Owner: TForm; Settings: TSettings);
begin
  inherited Create(Owner);
  self.Settings := Settings;
end;

procedure TfrmOptions.cbxBackColorChanged(Sender: TObject);
begin
  DiskMap.Color := cbxBack.ButtonColor;
end;

procedure TfrmOptions.btnFontMainClick(Sender: TObject);
begin
  with dlgFont do
  begin
    Font := FontMain;
    Options := Options - [fdFixedPitchOnly];
    if Execute then
    begin
      edtFontMain.Text := FontHumanReadable(Font);
      FontMain := Font;
    end;
  end;
end;

procedure TfrmOptions.btnFontMapClick(Sender: TObject);
begin
  with dlgFont do
  begin
    Font := DiskMap.Font;
    Options := Options - [fdFixedPitchOnly];
    if Execute then
    begin
      edtFontMap.Text := FontHumanReadable(Font);
      DiskMap.Font := Font;
    end;
  end;
end;

procedure TfrmOptions.btnFontSectorClick(Sender: TObject);
begin
  with dlgFont do
  begin
    Font := FontSector;
    Options := Options + [fdFixedPitchOnly];
    if Execute then
    begin
      edtFontSector.Text := FontHumanReadable(Font);
      FontSector := Font;
    end;
  end;
end;

procedure TfrmOptions.cbxGridColorChanged(Sender: TObject);
begin
  DiskMap.GridColor := cbxGrid.ButtonColor;
end;

function TfrmOptions.Show: boolean;
begin
  pagOptions.ActivePageIndex := 0;
  Read;
  Result := ShowModal = mrOk;
  if Result then
    Write;
end;

procedure TfrmOptions.Read;
begin
  with Settings do
  begin
    FontMain := WindowFont;
    edtFontMain.Text := FontHumanReadable(WindowFont);

    FontSector := SectorFont;
    edtFontSector.Text := FontHumanReadable(SectorFont);

    DiskMap.Font := DiskMapFont;
    edtFontMap.Text := FontHumanReadable(DiskMapFont);

    chkRestoreWindow.Checked := RestoreWindow;
    chkRestoreWorkspace.Checked := RestoreWorkspace;
    udBytes.Position := BytesPerLine;
    udTrackMarks.Position := DiskMapTrackMark;
    chkDarkBlankSectors.Checked := DarkBlankSectors;
    edtNonDisplay.Text := UnknownASCII;
    cbxBack.ButtonColor := DiskMapBackgroundColor;
    cbxGrid.ButtonColor := DiskMapGridColor;
    chkWarnConversionProblems.Checked := WarnConversionProblems;
    chkWarnSectorChange.Checked := WarnSectorChange;
    chkSaveRemoveEmptyTracks.Checked := RemoveEmptyTracks;
    udMapX.Position := SaveDiskMapWidth;
    udMapY.Position := SaveDiskMapHeight;
    cboOpenView.Text := OpenView;
  end;
end;

procedure TfrmOptions.Write;
begin
  with Settings do
  begin
    WindowFont := FontMain;
    SectorFont := FontSector;
    DiskMapFont := DiskMap.Font;

    DiskMapBackgroundColor := cbxBack.ButtonColor;
    DarkBlankSectors := chkDarkBlankSectors.Checked;
    DiskMapGridColor := cbxGrid.ButtonColor;
    DiskMapTrackMark := udTrackMarks.Position;
    RestoreWindow := chkRestoreWindow.Checked;
    BytesPerLine := udBytes.Position;
    UnknownASCII := edtNonDisplay.Text;
    RestoreWorkspace := chkRestoreWorkspace.Checked;
    WarnConversionProblems := chkWarnConversionProblems.Checked;
    WarnSectorChange := chkWarnSectorChange.Checked;
    RemoveEmptyTracks := chkSaveRemoveEmptyTracks.Checked;
    SaveDiskMapWidth := udMapX.Position;
    SaveDiskMapHeight := udMapY.Position;
    OpenView := cboOpenView.SelText;
  end;
end;

procedure TfrmOptions.edtTrackMarksChange(Sender: TObject);
begin
  DiskMap.TrackMark := udTrackMarks.Position;
end;

procedure TfrmOptions.btnResetClick(Sender: TObject);
begin
  Settings.Reset;
  Read;
end;

procedure TfrmOptions.chkDarkBlankSectorsClick(Sender: TObject);
begin
  Settings.DarkBlankSectors := chkDarkBlankSectors.Checked;
end;

end.
