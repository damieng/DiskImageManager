unit TrackProperties;

{$MODE Delphi}

{
  Disk Image Manager -  Track properties window

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  DskImage, SysUtils, Classes, Forms, StdCtrls, ComCtrls, ExtCtrls, Dialogs, Graphics;

type

  { TfrmTrackProperties }

  TfrmTrackProperties = class(TForm)
    bevIdentity: TBevel;
    bevSectorDetails: TBevel;
    edtBitLength: TEdit;
    edtSectorGap: TEdit;
    edtSectorFiller: TEdit;
    lblDetails: TLabel;
    lblBitLength: TLabel;
    lblSectorGap: TLabel;
    lblSectorDetails: TLabel;
    lblSectorFiller: TLabel;
    pnlTab: TPanel;
    pnlButtons: TPanel;
    pagTabs: TPageControl;
    tabTrack: TTabSheet;
    btnOK: TButton;
    btnCancel: TButton;
    btnApply: TButton;
    lblSectorDataRate: TLabel;
    lblSize: TLabel;
    lblImage: TLabel;
    lblLogicalID: TLabel;
    edtLogicalID: TEdit;
    udLogicalID: TUpDown;
    cboSectorDataRate: TComboBox;
    edtSize: TEdit;
    udSize: TUpDown;
    lblPhysical: TLabel;
    edtImage: TEdit;
    edtPhysical: TEdit;
    bevDetails: TBevel;
    lblIdentity: TLabel;
    lblPhysicalID: TLabel;
    edtPhysicalID: TEdit;
    udPhysicalID: TUpDown;
    lblSectorCount: TLabel;
    edtSectorCount: TEdit;
    udSectorCount: TUpDown;
    lblSectorSize: TLabel;
    edtSectorSize: TEdit;
    udSectorGap: TUpDown;
    udSectorFiller: TUpDown;
    procedure btnCancelClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    FTrack: TDSKTrack;
    procedure MakeChanges;
  public
    constructor Create(AOwner: TComponent; Track: TDSKTrack); reintroduce;
    procedure Refresh;
  end;

var
  frmTrackProperties: TfrmTrackProperties;

implementation

uses Main;

{$R *.lfm}

constructor TfrmTrackProperties.Create(AOwner: TComponent; Track: TDSKTrack);
var
  RIdx: TDSKDataRate;
begin
  inherited Create(AOwner);
  FTrack := Track;

  cboSectorDataRate.Items.Clear;
  for RIdx := drUnknown to drExtendedDensity do
    cboSectorDataRate.Items.Add(DSKDataRate[RIdx]);

  Refresh;
  Show;
end;

procedure TfrmTrackProperties.Refresh;
begin
  // Identity
  edtImage.Text := ExtractFileName(FTrack.ParentSide.ParentDisk.ParentImage.FileName);
  edtPhysical.Text := 'Side ' + IntToStr(FTrack.Side + 1) + ' > Track ' + IntToStr(FTrack.Logical);
  Caption := edtImage.Text + ' > ' + edtPhysical.Text;

  // Track details
  udLogicalID.Position := FTrack.Logical;
  udPhysicalID.Position := FTrack.Track;
  udSize.Position := FTrack.Size;
  edtBitLength.Caption := IntToStr(FTrack.BitLength);

  // Sector details
  udSectorCount.Position := FTrack.Sectors;
  edtSectorGap.Text := IntToStr(FTrack.GapLength);
  edtSectorFiller.Text := IntToStr(FTrack.Filler);
  cboSectorDataRate.ItemIndex := Ord(FTrack.DataRate);

  // Sector info
  edtSectorSize.Text := IntToStr(FTrack.SectorSize);
end;

procedure TfrmTrackProperties.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmTrackProperties.btnApplyClick(Sender: TObject);
begin
  MakeChanges;
end;

procedure TfrmTrackProperties.btnOKClick(Sender: TObject);
begin
  MakeChanges;
  Close;
end;

procedure TfrmTrackProperties.MakeChanges;
begin
  if frmMain.ConfirmChange('change', 'track') then
    with FTrack do
    begin
      // Track details
      Logical := udLogicalID.Position;
      Track := udPhysicalID.Position;
      BitLength := StrToInt(edtBitLength.Caption);

      // Sector details
      Sectors := udSectorCount.Position;
      GapLength := udSectorGap.Position;
      Filler := udSectorFiller.Position;
      DataRate := TDSKDataRate(cboSectorDataRate.ItemIndex);
    end;
  frmMain.RefreshList;
end;

end.
