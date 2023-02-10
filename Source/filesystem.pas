unit FileSystem;

{$MODE Delphi}

{
  Disk Image Manager -  Virtual file system

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  DSKImage, Utils,
  Classes, SysUtils, FGL;

type
  TDSKEntryAllocationSize = (asByte, asWord);
  TDSKFile = class;

  TDSKFileSystem = class(TObject)
  private
    FParentDisk: TDSKDisk;
    FEntryAllocationSize: TDSKEntryAllocationSize;

    procedure TryPlus3DOSHeader(Data: array of byte; DiskFile: TDSKFile);
    procedure TryAMSDOSHeader(Data: array of byte; DiskFile: TDSKFile);
  public
    DiskLabel: string;

    property EntryAllocationSize: TDSKEntryAllocationSize read FEntryAllocationSize;

    function ReadLabelEntry(Data: array of byte; Offset: integer): string;
    function ReadFileEntry(Data: array of byte; Offset: integer): TDSKFile;
    function Directory: TFPGList<TDSKFile>;

    constructor Create(ParentDisk: TDSKDisk);
    destructor Destroy; override;
  end;

  TDSKFile = class(TObject)
  private
    FParentFileSystem: TDSKFileSystem;
  public
    Blocks: TFPGList<integer>;
    FileName: string;
    SizeOnDisk: integer;
    User: byte;
    ReadOnly: boolean;
    System: boolean;
    Archived: boolean;
    FirstSector: TDSKSector;
    Extent: integer;

    HeaderType: string;
    Checksum: boolean;
    Size: integer;
    Meta: string;

    constructor Create(ParentFileSystem: TDSKFileSystem);
    destructor Destroy; override;
  end;


implementation

// File system

constructor TDSKFileSystem.Create(ParentDisk: TDSKDisk);
begin
  inherited Create;
  FParentDisk := ParentDisk;

  if FParentDisk.Specification.GetBlockCount > 255 then
    FEntryAllocationSize := asWord
  else
    FEntryAllocationSize := asByte;
end;

destructor TDSKFileSystem.Destroy;
begin
  FParentDisk := nil;
  inherited Destroy;
end;

const
  FILENAME_OFFSET: integer = 1;
  EXTENSION_OFFSET: integer = 9;
  READONLY_OFFSET: integer = 9;
  SYSTEM_OFFSET: integer = 10;
  ARCHIVED_OFFSET: integer = 11;
  EXTENT_LOW: integer = 12;
  BYTES_IN_LAST_RECORD_OFFSET: integer = 13;
  EXTENT_HIGH: integer = 14;
  RECORD_COUNT_OFFSET: integer = 15;
  ALLOCATION_OFFSET: integer = 16;

function TDSKFileSystem.Directory: TFPGList<TDSKFile>;
const
  DIR_ENTRY_SIZE: integer = 32;
var
  MaxEntries, SectorOffset: integer;
  Sector: TDSKSector;
  Spec: TDSKSpecification;
  Index: integer;
begin
  Spec := FParentDisk.Specification;
  case Spec.Format of
    dsFormatCPC_Data:
      MaxEntries := 32;
    dsFormatCPC_System:
      MaxEntries := 32;
    else
      MaxEntries := Spec.DirectoryBlocks * Spec.GetBlockSize() div DIR_ENTRY_SIZE;
  end;

  Result := TFPGList<TDSKFile>.Create;

  Sector := FParentDisk.GetLogicalTrack(Spec.ReservedTracks).GetFirstLogicalSector();
  if Sector = nil then exit;

  SectorOffset := 0;
  for Index := 0 to MaxEntries - 1 do
  begin
    // Move to next sector if out of data
    if (SectorOffset + DIR_ENTRY_SIZE > Sector.DataSize) then
    begin
      Sector := FParentDisk.GetNextLogicalSector(Sector);
      SectorOffset := 0;
    end;

    if Sector.Data[SectorOffset] < 32 then
    begin
      Result.Add(ReadFileEntry(Sector.Data, SectorOffset));
    end;

    if Sector.Data[SectorOffset] = 32 then
      DiskLabel := ReadLabelEntry(Sector.Data, SectorOffset);

    SectorOffset := SectorOffset + DIR_ENTRY_SIZE;
  end;
end;

function TDSKFileSystem.ReadLabelEntry(Data: array of byte; Offset: integer): string;
begin
  Result := StrBlockClean(Data, Offset + FILENAME_OFFSET, 11);
end;

function TDSKFileSystem.ReadFileEntry(Data: array of byte; Offset: integer): TDSKFile;
var
  Extension: string;
  AllocBlock, AllocOffset: integer;
begin
  Result := TDskFile.Create(self);
  with Result do
  begin
    User := Data[Offset];
    FileName := StrBlockClean(Data, Offset + FILENAME_OFFSET, 8).TrimRight();
    Extension := StrBlockClean(Data, Offset + EXTENSION_OFFSET, 3).TrimRight();
    if Extension <> '' then
      FileName := FileName + '.' + Extension;

    ReadOnly := Data[Offset + READONLY_OFFSET] > 127;
    System := Data[Offset + SYSTEM_OFFSET] > 127;
    Archived := Data[Offset + ARCHIVED_OFFSET] > 127;

    Extent := Data[Offset + EXTENT_LOW];

    AllocOffset := Offset + ALLOCATION_OFFSET;
    repeat
      begin
        if FEntryAllocationSize = asByte then
        begin
          AllocBlock := Data[AllocOffset];
          AllocOffset := AllocOffset + 1;
        end
        else
        begin
          AllocBlock := Data[AllocOffset] + (Data[AllocOffset + 1] << 8);
          AllocOffset := AllocOffset + 2;
        end;
        if AllocBlock > 0 then
          Result.Blocks.Add(AllocBlock);
      end;
    until (AllocBlock = 0) or (AllocOffset = Offset + 32);

    SizeOnDisk := Blocks.Count * FParentDisk.Specification.GetBlockSize();
    Size := Data[Offset + RECORD_COUNT_OFFSET] * 128;
    if Data[Offset + BYTES_IN_LAST_RECORD_OFFSET] > 0 then
      Size := Size - 128 + Data[Offset + BYTES_IN_LAST_RECORD_OFFSET];

    if Blocks.Count > 0 then
    begin
      HeaderType := 'Raw';
      FirstSector := FParentDisk.GetSectorByBlock(Blocks[0]);
      if FirstSector <> nil then
      begin
        TryPlus3DOSHeader(FirstSector.Data, Result);
        TryAMSDOSHeader(FirstSector.Data, Result);
      end;
    end;
  end;
end;

procedure TDSKFileSystem.TryAMSDOSHeader(Data: array of byte; DiskFile: TDSKFile);
var
  CalcCheckSum: word;
  Idx: integer;
  ExecAddr, LoadAddr: word;
begin
  CalcChecksum := 0;
  for Idx := 0 to 66 do
    CalcChecksum := CalcChecksum + Data[Idx];
  if CalcCheckSum <> Data[67] + (Data[68] << 8) then exit;

  DiskFile.Checksum := True;
  DiskFile.HeaderType := 'AMSDOS';
  DiskFile.Size := Data[64] + (Data[65] << 8) + (Data[66] << 16);

  LoadAddr := Data[21] + (Data[22] << 8);
  ExecAddr := Data[26] + (Data[27] << 8);

  case Data[18] of
    0: DiskFile.Meta := 'BASIC';
    1: DiskFile.Meta := 'BASIC (protected)';
    2: DiskFile.Meta := Format('BINARY %d EXEC %d', [LoadAddr, ExecAddr]);
    3: DiskFile.Meta := Format('BINARY (protected) %d EXEC %d', [LoadAddr, ExecAddr]);
    4: DiskFile.Meta := 'SCREEN';
    5: DiskFile.Meta := 'SCREEN (protected)';
    6: DiskFile.Meta := 'ASCII';
    7: DiskFile.Meta := 'ASCII (protected)';
    else
      DiskFile.Meta := Format('Custom 0x%x', [Data[15]]);
  end;

end;

procedure TDSKFileSystem.TryPlus3DOSHeader(Data: array of byte; DiskFile: TDSKFile);
var
  Sig: string;
  CalcChecksum: byte;
  Idx: integer;
  Length, Param1, Param2: word;
begin
  Sig := StrBlockClean(Data, 0, 8);
  if Sig <> 'PLUS3DOS' then exit;

  CalcChecksum := 0;
  for Idx := 0 to 126 do
    CalcChecksum := CalcChecksum + Data[Idx];
  //  DiskFile.Checksum := CalcChecksum = Data[127];
  DiskFile.HeaderType := Sig;
  DiskFile.Size := Data[11] + (Data[12] << 8) + (Data[13] << 16) + (Data[14] << 24);

  Length := Data[16] + (Data[17] << 8);
  Param1 := Data[18] + (Data[19] << 8);
  Param2 := Data[20] + (Data[21] << 8);

  case Data[15] of
    0: begin
      if Param1 <> $8000 then
        DiskFile.Meta := Format('BASIC LINE %d', [Param1])
      else
        DiskFile.Meta := 'BASIC';
    end;
    1: DiskFile.Meta := Format('DATA %s', [Data[19]]);
    2: DiskFile.Meta := Format('DATA %s$', [Data[19]]);
    3: DiskFile.Meta := Format('CODE %d,%d', [Param1, Length]);
    else
      DiskFile.Meta := Format('Custom 0x%x', [Data[15]]);
  end;
end;

// File

constructor TDSKFile.Create(ParentFileSystem: TDSKFileSystem);
begin
  inherited Create;
  FParentFileSystem := ParentFileSystem;
  Blocks := TFPGList<integer>.Create;
end;

destructor TDSKFile.Destroy;
begin
  FParentFileSystem := nil;
  Blocks.Free;
  inherited Destroy;
end;

end.
