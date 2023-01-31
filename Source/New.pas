unit New;

{$MODE Delphi}

{
  Disk Image Manager -  New disk window

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  DskImage, Main, Utils,
  SysUtils, Classes, Forms, StdCtrls, ComCtrls, ExtCtrls, Dialogs, Buttons, Math;

type

  { TfrmNew }

  TfrmNew = class(TForm)
    memDPBHex: TMemo;
    pnlInfo: TPanel;
    pnlTabs: TPanel;
    pnlButtons: TPanel;
    btnFormat: TButton;
    btnCancel: TButton;
    pagTabs: TPageControl;
    tabFormat: TTabSheet;
    tabDetails: TTabSheet;
    tabDiskSpec: TTabSheet;
    lblSides: TLabel;
    cboSides: TComboBox;
    lblTracks: TLabel;
    edtTracks: TEdit;
    lblSectors: TLabel;
    edtSectors: TEdit;
    lblSecSize: TLabel;
    edtSecSize: TEdit;
    udSecSize: TUpDown;
    lblGapRW: TLabel;
    edtGapRW: TEdit;
    udGapRW: TUpDown;
    lblGapFormat: TLabel;
    edtGapFormat: TEdit;
    udGapFormat: TUpDown;
    lblResTracks: TLabel;
    edtResTracks: TEdit;
    udResTracks: TUpDown;
    lblDirBlocks: TLabel;
    edtDirBlocks: TEdit;
    udDirBlocks: TUpDown;
    lblFiller: TLabel;
    edtFiller: TEdit;
    udFiller: TUpDown;
    lblFillHex: TLabel;
    udTracks: TUpDown;
    udSectors: TUpDown;
    chkWriteDiskSpec: TCheckBox;
    lblFormatDesc: TLabel;
    lvwFormats: TListView;
    lblSpecDesc: TLabel;
    lvwWarnings: TListView;
    pnlSummary: TPanel;
    lvwSummary: TListView;
    pnlWarnings: TPanel;
    chkAdjust: TCheckBox;
    lblFirstSector: TLabel;
    edtFirstSector: TEdit;
    udFirstSector: TUpDown;
    lblInterleave: TLabel;
    edtInterleave: TEdit;
    udInterleave: TUpDown;
    lblSkewTrack: TLabel;
    edtSkewTrack: TEdit;
    udSkewTrack: TUpDown;
    dlgOpenBoot: TOpenDialog;
    lblBlockSize: TLabel;
    edtBlockSize: TEdit;
    udBlockSize: TUpDown;
    lblSkewSide: TLabel;
    edtSkewSide: TEdit;
    udSkewSide: TUpDown;
    tabBoot: TTabSheet;
    lblBootDesc: TLabel;
    lblBootBinary: TLabel;
    lblBootType: TLabel;
    cboBootMachine: TComboBox;
    lblBinFile: TLabel;
    lblBinOffset: TLabel;
    lvwBootDetails: TListView;
    lblBootDetails: TLabel;
    btnBootClear: TBitBtn;
    btnBootBin: TBitBtn;
    procedure edtFillerChange(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnFormatClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lvwFormatsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure cboSidesChange(Sender: TObject);
    procedure edtTracksChange(Sender: TObject);
    procedure edtSectorsChange(Sender: TObject);
    procedure edtSecSizeChange(Sender: TObject);
    procedure edtGapRWChange(Sender: TObject);
    procedure edtGapFormatChange(Sender: TObject);
    procedure edtResTracksChange(Sender: TObject);
    procedure edtDirBlocksChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure chkWriteDiskSpecClick(Sender: TObject);
    procedure chkAdjustClick(Sender: TObject);
    procedure edtSkewTrackChange(Sender: TObject);
    procedure edtInterleaveChange(Sender: TObject);
    procedure edtFirstSectorChange(Sender: TObject);
    procedure cboBootMachineChange(Sender: TObject);
    procedure btnBootBinClick(Sender: TObject);
    procedure edtSkewSideChange(Sender: TObject);
    procedure tabBootShow(Sender: TObject);
    procedure btnBootClearClick(Sender: TObject);
    procedure edtBlockSizeChange(Sender: TObject);
  private
    IsLoading: boolean;
    CurrentFormat: TDSKFormatSpecification;
    BootSectorBin: array[0..MaxSectorSize] of byte;
    BootOffset, BootSectorSize: word;
    BootChecksum: byte;
    BootChecksumRequired: boolean;
    procedure SetShowAdvanced(ShowAdvanced: boolean);
    procedure SetCurrentFormat(ItemIndex: integer);
    procedure UpdateDetails;
    procedure UpdateSummary;
    procedure UpdateFileDetails;
    function IsPlus3Format: boolean;
    function GetFormat: TDSKSpecFormat;
  end;

var
  frmNew: TfrmNew;

implementation

{$R *.lfm}

procedure TfrmNew.edtFillerChange(Sender: TObject);
begin
  lblFillHex.Caption := Format('%.2x', [udFiller.Position]);
end;

procedure TfrmNew.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmNew.UpdateDetails;
begin
  IsLoading := True;
  with CurrentFormat do
  begin
    cboSides.ItemIndex := Ord(Sides);
    udTracks.Position := TracksPerSide;
    udSectors.Position := SectorsPerTrack;
    udSecSize.Position := SectorSize;
    udFirstSector.Position := FirstSector;
    udGapRW.Position := GapRW;
    udGapFormat.Position := GapFormat;
    udResTracks.Position := ResTracks;
    udDirBlocks.Position := DirBlocks;
    udBlockSize.Position := BlockSize;
    udFiller.Position := FillerByte;
    udInterleave.Position := Interleave;
    udSkewTrack.Position := SkewTrack;
    udSkewSide.Position := SkewSide;
  end;
  IsLoading := False;
  UpdateSummary;
end;

procedure TfrmNew.UpdateSummary;
var
  NewWarn: TListItem;
  hexDPB: string;
begin
  if IsLoading then
    exit;
  // Set summary details
  if lvwSummary.Items.Count > 0 then
  begin
    lvwSummary.Items[0].SubItems[0] :=
      Format('%d KB', [CurrentFormat.GetCapacityBytes div 1024]);
    lvwSummary.Items[1].SubItems[0] :=
      Format('%d KB', [CurrentFormat.GetUsableBytes div 1024]);
    lvwSummary.Items[2].SubItems[0] :=
      Format('%d', [CurrentFormat.GetDirectoryEntries]);
    if CurrentFormat.ResTracks > 0 then
      lvwsummary.Items[3].SubItems[0] := 'Yes'
    else
      lvwsummary.Items[3].SubItems[0] := 'No';
  end;

  // DPB hex preview
  hexDPB := '';
  case GetFormat of
    dsFormatPCW_SS: hexDPB := hexDPB + '00';
    dsFormatCPC_System: hexDPB := hexDPB + '01';
    dsFormatCPC_Data: hexDPB := hexDPB + '02';
    dsFormatPCW_DS: hexDPB := hexDPB + '03';
  end;
  case cboSides.ItemIndex of
    0: hexDPB := hexDPB + ' 00';
    1: hexDPB := hexDPB + ' 01';
    2: hexDPB := hexDPB + ' 02';
  end;
  hexDPB := hexDPB + ' ' + StrHex(udTracks.Position);
  hexDPB := hexDPB + ' ' + StrHex(udSectors.Position);
  hexDPB := hexDPB + ' ' + StrHex(Trunc(Log2(udSecSize.Position) - 7));
  hexDPB := hexDPB + ' ' + StrHex(udResTracks.Position);
  hexDPB := hexDPB + ' ' + StrHex(Trunc(Log2(udBlockSize.Position / 128)));
  hexDPB := hexDPB + ' ' + StrHex(udDirBlocks.Position);
  hexDPB := hexDPB + ' ' + StrHex(udGapRW.Position);
  hexDPB := hexDPB + ' ' + StrHex(udGapFormat.Position);
  hexDPB := hexDPB + ' 00 00 00 00 00';
  hexDPB := hexDPB + ' ??';
  memDPBHex.Text := hexDPB;

  lvwWarnings.Items.Clear;

  // Boot warnings
  if BootSectorSize > 0 then
  begin
    if cboBootMachine.ItemIndex = 3 then
    begin
      if CurrentFormat.FirstSector <> 65 then
      begin
        NewWarn := lvwWarnings.Items.Add;
        NewWarn.Caption := 'Boot on CPC requires first sector ID of 65';
      end;

      if chkWriteDiskSpec.Checked then
      begin
        NewWarn := lvwWarnings.Items.Add;
        NewWarn.Caption := 'CPC boot sector overwrites disk specification';
      end;
    end;

    if CurrentFormat.ResTracks < 1 then
    begin
      NewWarn := lvwWarnings.Items.Add;
      NewWarn.Caption := 'Boot requires a reserved track';
    end;

    if (cboBootMachine.ItemIndex < 3) and (not chkWriteDiskSpec.Checked) then
    begin
      NewWarn := lvwWarnings.Items.Add;
      NewWarn.Caption := 'Boot on PCW/+3 requires a disk specification';
    end;
  end;

  // Set any warnings
  if (not IsPlus3Format) and (not chkWriteDiskSpec.Checked) then
  begin
    NewWarn := lvwWarnings.Items.Add;
    NewWarn.Caption := 'Format requires disk specification on PCW/+3';
  end;

  if CurrentFormat.GetDirectoryEntries > 256 then
  begin
    NewWarn := lvwWarnings.Items.Add;
    NewWarn.Caption := '+3 has a maximum of 256 directory entries';
  end;

  if CurrentFormat.DirBlocks = 0 then
  begin
    NewWarn := lvwWarnings.Items.Add;
    NewWarn.Caption := 'File system has no directory blocks';
  end;

  if (CurrentFormat.ResTracks = 0) and (chkWriteDiskSpec.Checked) then
  begin
    NewWarn := lvwWarnings.Items.Add;
    NewWarn.Caption := 'Disk spec should use a reserved track';
  end;

  if CurrentFormat.SectorSize > 512 then
  begin
    NewWarn := lvwWarnings.Items.Add;
    NewWarn.Caption := '512 bytes per sector limit in +3DOS';
  end;

  if CurrentFormat.Interleave = 0 then
  begin
    NewWarn := lvwWarnings.Items.Add;
    NewWarn.Caption := 'Interleave can not be 0';
  end;

  if CurrentFormat.SectorSize * CurrentFormat.SectorsPerTrack > 6144 then
  begin
    NewWarn := lvwWarnings.Items.Add;
    NewWarn.Caption := '6144 bytes per track limit on +3';
  end;

  if (lvwFormats.Selected <> nil) and (chkWriteDiskSpec.Checked) then
    with lvwFormats.Selected do
      if (ImageIndex = 2) or (ImageIndex = 3) or (ImageIndex = 7) then
      begin
        NewWarn := lvwWarnings.Items.Add;
        NewWarn.Caption := 'Disk specification unsupported by Amstrad CPC';
      end;
end;

function TfrmNew.GetFormat: TDSKSpecFormat;
begin
  Result := dsFormatPCW_SS;
  if (lvwFormats.Selected = nil) then exit;

  if (lvwFormats.Selected.ImageIndex = 2) then
    Result := dsFormatCPC_System;
  if (lvwFormats.Selected.ImageIndex = 3) then
    Result := dsFormatCPC_Data;
  if (CurrentFormat.Sides <> dsSideSingle) then
    Result := dsFormatPCW_DS;
end;

procedure TfrmNew.btnFormatClick(Sender: TObject);
var
  NewImage: TDSKImage;
  CopySize: integer;
begin
  NewImage := TDSKImage.Create;
  with NewImage do
  begin
    FileName := Format('Untitled %d.dsk', [frmMain.GetNextNewFile]);
    FileFormat := diNotYetSaved;
    Disk.Format(CurrentFormat);
  end;

  if chkWriteDiskSpec.Checked then
    with NewImage.Disk.Specification do
    begin
      Format := GetFormat;
      Side := CurrentFormat.Sides;
      BlockSize := CurrentFormat.BlockSize;
      DirectoryBlocks := CurrentFormat.DirBlocks;
      GapFormat := CurrentFormat.GapFormat;
      GapReadWrite := CurrentFormat.GapRW;
      ReservedTracks := CurrentFormat.ResTracks;
      SectorsPerTrack := CurrentFormat.SectorsPerTrack;
      FDCSectorSize := CurrentFormat.FDCSectorSize;
      SectorSize := CurrentFormat.SectorSize;
      TracksPerSide := CurrentFormat.TracksPerSide;
      Checksum := 0;

      if TracksPerSide > 50 then
        Track := dsTrackDouble
      else
        Track := dsTrackSingle;
      Write;
    end;

  if BootSectorSize > 0 then
    with NewImage.Disk.Side[0].Track[0].Sector[0] do
    begin
      CopySize := (CurrentFormat.SectorSize - BootOffset);
      if BootSectorSize < CopySize then
        CopySize := BootSectorSize;
      Move(BootSectorBin, Data[BootOffset], CopySize);
      if (chkWriteDiskSpec.Checked) and (BootChecksumRequired) then
      begin
        NewImage.Disk.Specification.Checksum :=
          (255 - GetModChecksum(256) + BootChecksum + 1) mod 256;
        NewImage.Disk.Specification.Write;
      end;
    end;

  frmMain.AddWorkspaceImage(NewImage);
end;

procedure TfrmNew.FormCreate(Sender: TObject);
var
  Idx: integer;
  Format: TDSKFormatSpecification;
begin
  lvwFormats.BeginUpdate;
  for Idx := 0 to 8 do
    with lvwFormats.Items.Add do
    begin
      Format := TDSKFormatSpecification.Create(Idx);
      ImageIndex := Idx;
      Caption := Format.Name;
      SubItems.Add(StrInt(Format.GetCapacityBytes div 1024));
      SubItems.Add(StrInt(Format.GetUsableBytes div 1024));
    end;
  lvwFormats.EndUpdate;

  CurrentFormat := TDSKFormatSpecification.Create(1);
  for Idx := 0 to Length(DSKSpecSides) - 2 do
    cboSides.Items.Add(DSKSpecSides[TDSKSpecSide(Idx)]);

  BootOffset := 0;
  BootChecksumRequired := False;
  pagTabs.ActivePage := tabFormat;
  SetShowAdvanced(False);
end;

procedure TfrmNew.lvwFormatsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  if lvwFormats.Selected <> nil then
    SetCurrentFormat(Item.ImageIndex);
end;

procedure TfrmNew.SetCurrentFormat(ItemIndex: integer);
begin
  CurrentFormat := TDSKFormatSpecification.Create(ItemIndex);
  UpdateDetails;
end;

// Temp hack until we persist the formatters properly
function TfrmNew.IsPlus3Format: boolean;
begin
  Result := True;
  with CurrentFormat do
  begin
    if Sides <> dsSideSingle then
      Result := False;
    if TracksPerSide <> 40 then
      Result := False;
    if SectorsPerTrack <> 9 then
      Result := False;
    if SectorSize <> 512 then
      Result := False;
    if GapRW <> 42 then
      Result := False;
    if GapFormat <> 82 then
      Result := False;
    if ResTracks <> 1 then
      Result := False;
    if DirBlocks <> 2 then
      Result := False;
    if BlockSize <> 1024 then
      Result := False;
  end;
end;

procedure TfrmNew.cboSidesChange(Sender: TObject);
begin
  CurrentFormat.Sides := TDSKSpecSide(cboSides.ItemIndex);
  UpdateSummary;
end;

procedure TfrmNew.edtTracksChange(Sender: TObject);
begin
  CurrentFormat.TracksPerSide := udTracks.Position;
  UpdateSummary;
end;

procedure TfrmNew.edtSectorsChange(Sender: TObject);
begin
  CurrentFormat.SectorsPerTrack := udSectors.Position;
  UpdateSummary;
end;

procedure TfrmNew.edtSecSizeChange(Sender: TObject);
begin
  CurrentFormat.SectorSize := udSecSize.Position;
  UpdateSummary;
end;

procedure TfrmNew.edtGapRWChange(Sender: TObject);
begin
  CurrentFormat.GapRW := udGapRW.Position;
  UpdateSummary;
end;

procedure TfrmNew.edtGapFormatChange(Sender: TObject);
begin
  CurrentFormat.GapFormat := udGapFormat.Position;
  UpdateSummary;
end;

procedure TfrmNew.edtResTracksChange(Sender: TObject);
begin
  CurrentFormat.ResTracks := udResTracks.Position;
  UpdateSummary;
end;

procedure TfrmNew.edtDirBlocksChange(Sender: TObject);
begin
  CurrentFormat.DirBlocks := udDirBlocks.Position;
  UpdateSummary;
end;

procedure TfrmNew.FormShow(Sender: TObject);
begin
  SetCurrentFormat(0);
  lvwFormats.Items[0].Selected := True;
end;

procedure TfrmNew.chkWriteDiskSpecClick(Sender: TObject);
begin
  if chkWriteDiskSpec.Checked then
    BootOffset := 16
  else
    BootOffset := 0;
  UpdateSummary;
  UpdateFileDetails;
end;

procedure TfrmNew.chkAdjustClick(Sender: TObject);
begin
  SetShowAdvanced(chkAdjust.Checked);
end;

procedure TfrmNew.SetShowAdvanced(ShowAdvanced: boolean);
begin
  tabDetails.TabVisible := ShowAdvanced;
end;

procedure TfrmNew.edtSkewTrackChange(Sender: TObject);
begin
  CurrentFormat.SkewTrack := udSkewTrack.Position;
  UpdateSummary;
end;

procedure TfrmNew.edtInterleaveChange(Sender: TObject);
begin
  CurrentFormat.Interleave := udInterleave.Position;
  UpdateSummary;
end;

procedure TfrmNew.edtFirstSectorChange(Sender: TObject);
begin
  CurrentFormat.FirstSector := udFirstSector.Position;
  UpdateSummary;
end;

procedure TfrmNew.cboBootMachineChange(Sender: TObject);
begin
  BootChecksumRequired := True;
  case cboBootMachine.ItemIndex of
    0: BootChecksum := 3;
    1: BootChecksum := 255;
    2: BootChecksum := 1;
    else
      BootChecksumRequired := False;
  end;
  UpdateFileDetails;
  UpdateSummary;
end;

procedure TfrmNew.btnBootBinClick(Sender: TObject);
var
  BootFile: TFileStream;
begin
  dlgOpenBoot.FileName := lblBinFile.Caption;
  if dlgOpenBoot.Execute then
  begin
    lblBinFile.Caption := dlgOpenBoot.FileName;

    BootFile := TFileStream.Create(dlgOpenBoot.FileName, fmOpenRead or fmShareDenyNone);
    BootSectorSize := BootFile.Read(BootSectorBin, Length(BootSectorBin));
    BootFile.Free;
  end;
  UpdateFileDetails;
end;

procedure TfrmNew.edtSkewSideChange(Sender: TObject);
begin
  CurrentFormat.SkewSide := udSkewSide.Position;
  UpdateSummary;
end;

procedure TfrmNew.UpdateFileDetails;
var
  Available: word;
begin
  Available := CurrentFormat.SectorSize - BootOffset;

  if lvwBootDetails.Items.Count > 0 then
  begin
    if BootSectorSize > 0 then
    begin
      lblBootType.Visible := True;
      cboBootMachine.Visible := True;
      lblBootDetails.Visible := True;
      lvwBootDetails.Visible := True;

      with lvwBootDetails do
      begin
        Items[0].SubItems[0] := Format('%d', [BootOffset]);
        Items[1].SubItems[0] := Format('%d bytes', [Available]);
        Items[2].SubItems[0] := Format('%d bytes', [BootSectorSize]);

        // Size checks
        if (BootSectorSize > Available) then
          Items[3].SubItems[0] := 'Truncate';
        if (BootSectorSize < Available) then
          Items[3].SubItems[0] := Format('Pad (%.2x)', [CurrentFormat.FillerByte]);
        if (BootSectorSize = Available) then
          Items[3].SubItems[0] := 'Perfect';

        // Checksum stuff
        if BootChecksumRequired then
          Items[4].SubItems[0] := Format('%d / %d', [BootChecksum, 1])
        else
          Items[4].SubItems[0] := 'Not required';
      end;
    end
    else
    begin
      lblBootType.Visible := False;
      cboBootMachine.Visible := False;
      lblBootDetails.Visible := False;
      lvwBootDetails.Visible := False;
    end;
  end;
end;

procedure TfrmNew.tabBootShow(Sender: TObject);
begin
  UpdateFileDetails;
end;

procedure TfrmNew.btnBootClearClick(Sender: TObject);
begin
  BootSectorSize := 0;
  lblBinFile.Caption := '';
  UpdateFileDetails;
end;

procedure TfrmNew.edtBlockSizeChange(Sender: TObject);
begin
  CurrentFormat.BlockSize := udBlockSize.Position;
  UpdateSummary;
end;

end.
