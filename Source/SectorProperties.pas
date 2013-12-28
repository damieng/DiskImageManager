unit SectorProperties;

{$MODE Delphi}

{
  Disk Image Manager -  Sector properties window

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  DskImage, Utils,
  SysUtils, Classes, Forms, StdCtrls, ComCtrls, ExtCtrls, CheckLst, Dialogs;

type
  TfrmSector = class(TForm)
    pnlTab: TPanel;
    pnlButtons: TPanel;
    pagTabs: TPageControl;
    tabSector: TTabSheet;
    btnOK: TButton;
    btnCancel: TButton;
    btnApply: TButton;
    lblStatus: TLabel;
    lblSize: TLabel;
    lblImage: TLabel;
    cklFDC2: TCheckListBox;
    cklFDC1: TCheckListBox;
    lblFDC1: TLabel;
    lblFDC2: TLabel;
    lblSectorID: TLabel;
    edtSectorID: TEdit;
    udSectorID: TUpDown;
    cboStatus: TComboBox;
    edtSize: TEdit;
    udSize: TUpDown;
    lblPhysical: TLabel;
    edtImage: TEdit;
    edtPhysical: TEdit;
    bevDetails: TBevel;
    bevFDC: TBevel;
    lblFDC: TLabel;
    lblDetails: TLabel;
    lblIdentity: TLabel;
    bevIdentity: TBevel;
    lblFill: TLabel;
    edtFill: TEdit;
    udFill: TUpDown;
    lblFillHex: TLabel;
    lblSizeBytes: TLabel;
    lblPad: TLabel;
    edtPad: TEdit;
    udPad: TUpDown;
    lblPadHex: TLabel;
    lblFDCSize: TLabel;
    edtFDCSize: TEdit;
    udFDCSize: TUpDown;
    procedure btnCancelClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure edtFillChange(Sender: TObject);
    procedure cboStatusChange(Sender: TObject);
    procedure edtSizeChange(Sender: TObject);
    procedure edtPadChange(Sender: TObject);
  private
    FSector: TDSKSector;
    SecStat: TDSKSectorStatus;
    procedure MakeChanges;
    procedure UpdateFill;
    procedure UpdatePad;
  public
    constructor Create(AOwner: TComponent; Sector: TDSKSector); reintroduce;
    procedure Refresh;
  end;

var
  frmSector: TfrmSector;

implementation

uses Main;

{$R *.lfm}

constructor TfrmSector.Create(AOwner: TComponent; Sector: TDSKSector);
begin
  inherited Create(AOwner);
  //udSize.Max := MaxSectorSize;
  FSector := Sector;
  Refresh;
  Show;
end;

procedure TfrmSector.Refresh;
var
  SIdx: TDSKSectorStatus;
  FIdx: integer;
begin
  // Physical
  edtImage.Text := ExtractFileName(
    FSector.ParentTrack.ParentSide.ParentDisk.ParentImage.FileName);
  edtPhysical.Text := 'Side ' + IntToStr(FSector.Side + 1) + ' > Track ' +
    IntToStr(FSector.Track) + ' > Sector ' +
    IntToStr(FSector.Sector);
  Caption := edtPhysical.Text;

  // Details
  udSectorID.Position := FSector.ID;
  udSize.Position := FSector.DataSize;
  if (FSector.GetFillByte >= 0) then
    udFill.Position := FSector.ParentTrack.Filler
  else
    udFill.Position := FSector.GetFillByte;

  udPad.Position := udFill.Position;

  cboStatus.Items.Clear;
  for SIdx := ssUnformatted to ssFormattedInUse do
    cboStatus.Items.Add(DSKSectorStatus[SIdx]);

  SecStat := FSector.Status;
  cboStatus.ItemIndex := Ord(FSector.Status);

  // FDC
  for FIdx := 0 to 7 do
  begin
    cklFDC1.Checked[FIdx] :=
      (FSector.FDCStatus[1] and Power2[FIdx + 1]) = Power2[FIdx + 1];
    cklFDC2.Checked[FIdx] :=
      (FSector.FDCStatus[2] and Power2[FIdx + 1]) = Power2[FIdx + 1];
  end;
end;

procedure TfrmSector.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmSector.btnApplyClick(Sender: TObject);
begin
  MakeChanges;
end;

procedure TfrmSector.btnOKClick(Sender: TObject);
begin
  MakeChanges;
  Close;
end;

procedure TfrmSector.MakeChanges;
var
  FIdx: integer;
  OldLength: word;
  SecData: array[0..MaxSectorSize] of byte;
begin
  if frmMain.ConfirmChange('change', 'sector') then
    with FSector do
    begin
      // Details
      ID := udSectorID.Position;

      // Status
      if (SecStat = ssFormattedBlank) or (SecStat = ssFormattedFilled) then
        FillSector(udFill.Position);

      // Changing size?
      if DataSize <> word(udSize.Position))then
      begin
        if (DataSize < word(udSize.Position)) and (DataSize > 0) then
        begin
          Move(Data, SecData, DataSize);
          OldLength := DataSize;
          DataSize := word(udSize.Position);
          FillSector(udPad.Position);
          Move(SecData, Data, OldLength);
        end
        else
        begin
          DataSize := udSize.Position;
        end;
      end;

      // FDC data Size
      if FDCSize <> byte(udFDCSize.Position) then
      begin
        FDCSize := byte(udFDCSize.Position);
      end;

      // FDC status
      FDCStatus[1] := 0;
      for FIdx := 0 to 7 do
        if cklFDC1.Checked[FIdx] then
          FDCStatus[1] := FDCStatus[1] + Power2[FIdx + 1];

      FDCStatus[2] := 0;
      for FIdx := 0 to 7 do
        if cklFDC2.Checked[FIdx] then
          FDCStatus[2] := FDCStatus[2] + Power2[FIdx + 1];

    end;
  frmMain.RefreshList;
end;

procedure TfrmSector.edtFillChange(Sender: TObject);
begin
  lblFillHex.Caption := IntToHex(udFill.Position, 2);
end;

procedure TfrmSector.cboStatusChange(Sender: TObject);
begin
  SecStat := TDSKSectorStatus(cboStatus.ItemIndex);

  if (SecStat = ssFormattedInUse) and (FSector.Status <> ssFormattedInUse) then
  begin
    ShowMessage('Sector can not be made in-use when it was not previously');
    cboStatus.ItemIndex := Ord(FSector.Status);
  end;

  if SecStat = ssUnformatted then
    udSize.Position := 0
  else
  if udSize.Position = 0 then
    if FSector.DataSize <> 0 then
      udSize.Position := FSector.DataSize
    else
      udSize.Position := FSector.ParentTrack.SectorSize * 256;

  UpdateFill;
end;

procedure TfrmSector.edtSizeChange(Sender: TObject);
begin
  if (udSize.Position > 0) and (FSector.DataSize = 0) then
    cboStatus.ItemIndex := Ord(ssFormattedBlank);
  if udSize.Position = 0 then
    cboStatus.ItemIndex := Ord(ssUnformatted);
  UpdatePad;
end;

procedure TfrmSector.UpdatePad;
var
  ShowPad: boolean;
begin
  ShowPad := (word(udSize.Position) > FSector.DataSize) and (FSector.DataSize > 0);
  lblPad.Visible := ShowPad;
  edtPad.Visible := ShowPad;
  udPad.Visible := ShowPad;
  lblPadHex.Visible := ShowPad;
end;

procedure TfrmSector.UpdateFill;
var
  ShowFill: boolean;
begin
  ShowFill := ((SecStat = ssFormattedBlank) or (SecStat = ssFormattedFilled)) or
    (word(udSize.Position) > FSector.DataSize);
  if (cboStatus.ItemIndex = 1) then
    udFill.Position := FSector.ParentTrack.Filler;
  lblFill.Visible := ShowFill;
  edtFill.Visible := ShowFill;
  udFill.Visible := ShowFill;
  lblFillHex.Visible := ShowFill;
end;

procedure TfrmSector.edtPadChange(Sender: TObject);
begin
  lblPadHex.Caption := IntToHex(udPad.Position, 2);
end;

end.