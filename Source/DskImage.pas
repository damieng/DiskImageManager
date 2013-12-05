unit DskImage;

{$MODE Delphi}

{
  Disk Image Manager -  Virtual disk management

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  DSKFormat, Utils,
  Classes, Dialogs, SysUtils, Math;

const
  MaxSectorSize = 32768;
  Alt8KSize = 6144;
  FDCSectorSizes: array[0..8] of word =
    (128, 256, 512, 1024, 2048, 4096, 8192, 16384, MaxSectorSize);

type
  // Physical disk structure
  TDSKImage = class;
  TDSKDisk = class;
  TDSKSide = class;
  TDSKTrack = class;
  TDSKSector = class;

  // Logical intepretations
  TDSKFormatSpecification = class;
  TDSKSpecification = class;
  TDSKFileSystem = class;
  TDSKFile = class;

  // Image
  TDSKImageFormat = (diStandardDSK, diExtendedDSK, diNotYetSaved, diInvalid);

  TDSKImage = class(TObject)
  private
    FCorrupt: boolean;
    FCreator: string;
    FDisk: TDSKDisk;
    FFileName: TFileName;
    FFileSize: int64;
    FIsChanged: boolean;

    procedure SetIsChanged(NewValue: boolean);
    function LoadFileDSK(DiskFile: TFileStream): boolean;
    function SaveFileDSK(DiskFile: TFileStream; SaveFileFormat: TDSKImageFormat;
      Compress: boolean): boolean;
  public
    FileFormat: TDSKImageFormat;
    Messages: TStringList;

    constructor Create;
    destructor Destroy; override;

    function LoadFile(LoadFileName: TFileName): boolean;
    function SaveFile(SaveFileName: TFileName; SaveFileFormat: TDSKImageFormat;
      Copy: boolean; Compress: boolean): boolean;
    function FindText(From: TDSKSector; Text: string;
      CaseSensitive: boolean): TDSKSector;
    function GetNextLogicalSector(Sector: TDSKSector): TDSKSector;

    property Creator: string read FCreator write FCreator;
    property Corrupt: boolean read FCorrupt write FCorrupt;
    property Disk: TDSKDisk read FDisk write FDisk;
    property FileName: TFileName read FFileName write FFileName;
    property FileSize: int64 read FFileSize write FFileSize;
    property IsChanged: boolean read FIsChanged write SetIsChanged;
  end;


  // Disk
  TDSKDisk = class(TObject)
  private
    FFileSystem: TDSKFileSystem;
    FParentImage: TDSKImage;
    FSpecification: TDSKSpecification;

    function GetFormattedCapacity: integer;
    function GetSides: byte;
    function GetTrackTotal: word;
    procedure SetSides(NewSides: byte);
  public
    Side: array of TDSKSide;

    constructor Create(ParentImage: TDSKImage);
    destructor Destroy; override;

    function BootableOn: string;
    function DetectFormat: string;
    function GetLogicalTrack(LogicalTrack: word): TDSKTrack;
    function HasFDCErrors: boolean;
    function HasFirstSector: boolean;
    function IsTrackSizeUniform: boolean;
    function IsUniform(IgnoreEmptyTracks: boolean): boolean;
    procedure Format(Formatter: TDSKFormatSpecification);

    property FileSystem: TDSKFileSystem read FFileSystem;
    property FormattedCapacity: integer read GetFormattedCapacity;
    property Sides: byte read GetSides write SetSides;
    property Specification: TDSKSpecification read FSpecification;
    property TrackTotal: word read GetTrackTotal;
    property ParentImage: TDSKImage read FParentImage;
  end;


  // Side
  TDSKSide = class(TObject)
  private
    FParentDisk: TDSKDisk;

    function GetTracks: byte;
    function GetHighTrackCount: byte;

    procedure SetTracks(NewTracks: byte);
  public
    Side: byte;
    Track: array of TDSKTrack;

    constructor Create(ParentDisk: TDSKDisk);
    destructor Destroy; override;

    property HighTrackCount: byte read GetHighTrackCount;
    property ParentDisk: TDSKDisk read FParentDisk;
    property Tracks: byte read GetTracks write SetTracks;
  end;


  // Disk track
  TDSKTrack = class(TObject)
  private
    FParentSide: TDSKSide;

    function GetIsFormatted: boolean;
    function GetLowSectorID: byte;
    function GetSectors: byte;
    procedure SetSectors(NewSectors: byte);
  public
    Filler: byte;
    GapLength: byte;
    Logical: word;
    Sector: array of TDSKSector;
    SectorSize: word;
    Side: byte;
    Track: byte;

    constructor Create(ParentSide: TDSKSide);
    destructor Destroy; override;

    procedure Format(Formatter: TDSKFormatSpecification);
    procedure Unformat;
    function GetTrackSizeFromSectors: word;

    property IsFormatted: boolean read GetIsFormatted;
    property LowSectorID: byte read GetLowSectorID;
    property ParentSide: TDSKSide read FParentSide;
    property Sectors: byte read GetSectors write SetSectors;
    property Size: word read GetTrackSizeFromSectors;
  end;


  // Sector
  TDSKSectorStatus = (ssUnformatted, ssFormattedBlank, ssFormattedFilled,
    ssFormattedInUse);

  TDSKSector = class(TObject)
  private
    FAdvertisedSize: integer;
    FDataSize: word;
    FIsChanged: boolean;
    FParentTrack: TDSKTrack;

    function GetStatus: TDSKSectorStatus;
  public
    Data: array[0..MaxSectorSize] of byte;
    FDCSize: byte;
    FDCStatus: array[1..2] of byte;
    ID: byte;
    Sector: byte;
    Side: byte;
    Track: byte;

    constructor Create(ParentTrack: TDSKTrack);
    destructor Destroy; override;

    function GetFillByte: integer;
    function GetModChecksum(ModValue: integer): integer;
    function FindText(Text: string; CaseSensitive: boolean): integer;

    procedure FillSector(Filler: byte);
    procedure ResetFDC;
    procedure Unformat;

    property AdvertisedSize: integer read FAdvertisedSize write FAdvertisedSize;
    property DataSize: word read FDataSize write FDataSize;
    property IsChanged: boolean read FIsChanged write FIsChanged;
    property ParentTrack: TDSKTrack read FParentTrack;
    property Status: TDSKSectorStatus read GetStatus;
  end;


  // Specification (Optional PCW/CPC+3 disk specification)
  TDSKSpecFormat = (dsFormatPCW_SS, dsFormatCPC_System, dsFormatCPC_Data,
    dsFormatPCW_DS, dsFormatAssumedPCW_SS, dsFormatInvalid);
  TDSKSpecSide = (dsSideSingle, dsSideDoubleAlternate, dsSideDoubleSuccessive,
    dsSideDoubleReverse, dsSideInvalid);
  TDSKSpecTrack = (dsTrackSingle, dsTrackDouble, dsTrackInvalid);

  TDSKSpecification = class(TObject)
  private
    FParentDisk: TDSKDisk;
    FIsChanged: boolean;

    FBlockSize: integer;
    FChecksum: byte;
    FDirectoryBlocks: byte;
    FFormat: TDSKSpecFormat;
    FGapFormat: byte;
    FGapReadWrite: byte;
    FReservedTracks: byte;
    FSectorsPerTrack: byte;
    FFDCSectorSize: byte;
    FSectorSize: word;
    FSide: TDSKSpecSide;
    FTrack: TDSKSpecTrack;
    FTracksPerSide: byte;

    procedure SetBlockSize(NewBlockSize: integer);
    procedure SetChecksum(NewChecksum: byte);
    procedure SetDirectoryBlocks(NewDirectoryBlocks: byte);
    procedure SetFDCSectorSize(NewFDCSectorSize: byte);
    procedure SetFormat(NewFormat: TDSKSpecFormat);
    procedure SetGapFormat(NewGapFormat: byte);
    procedure SetGapReadwrite(NewGapReadWrite: byte);
    procedure SetReservedTracks(NewReservedTracks: byte);
    procedure SetSectorsPerTrack(NewSectorsPerTrack: byte);
    procedure SetSectorSize(NewSectorSize: word);
    procedure SetSide(NewSide: TDSKSpecSide);
    procedure SetTrack(NewTrack: TDSKSpecTrack);
    procedure SetTracksPerSide(NewTracksPerSide: byte);
  public
    constructor Create(ParentDisk: TDSKDisk);
    destructor Destroy; override;

    function Read: TDSKSpecFormat;
    function Write: boolean;

    property BlockSize: integer read FBlockSize write SetBlockSize;
    property Checksum: byte read FChecksum write SetChecksum;
    property DirectoryBlocks: byte read FDirectoryBlocks write SetDirectoryBlocks;
    property FDCSectorSize: byte read FFDCSectorSize write SetFDCSectorSize;
    property Format: TDSKSpecFormat read FFormat write SetFormat;
    property GapFormat: byte read FGapFormat write SetGapFormat;
    property GapReadWrite: byte read FGapReadWrite write SetGapReadWrite;
    property IsChanged: boolean read FIsChanged write FIsChanged;
    property ReservedTracks: byte read FReservedTracks write SetReservedTracks;
    property SectorsPerTrack: byte read FSectorsPerTrack write SetSectorsPerTrack;
    property SectorSize: word read FSectorSize write SetSectorSize;
    property Side: TDSKSpecSide read FSide write SetSide;
    property Track: TDSKSpecTrack read FTrack write SetTrack;
    property TracksPerSide: byte read FTracksPerSide write SetTracksPerSide;
  end;


  // File system abstraction
  TDSKFileSystem = class(TObject)
  private
    FParentDisk: TDSKDisk;
  public
    DiskFile: array of TDSKFile;

    constructor Create(ParentDisk: TDSKDisk);
    destructor Destroy; override;

    function GetDiskFile(Offset: integer): TDSKFile;
  end;


  // File abstraction
  TDSKFile = class(TObject)
  private
    FParentFileSystem: TDSKFileSystem;
  public
    Data: array of byte;
    Deleted: boolean;
    FileName: string;
    FileType: string;
    Size: integer;

    constructor Create(ParentFileSystem: TDSKFileSystem);
    destructor Destroy; override;
  end;


  // Disk format specification
  TDSKFormatSpecification = class(TObject)
  private
    FSectorIDs: array of byte;
    procedure BuildSectorIDs;
  public
    Bootable: boolean;
    BlockSize: word;
    DirBlocks: byte;
    FDCSectorSize: byte;
    FillerByte: byte;
    FirstSector: byte;
    GapFormat: byte;
    GapRW: byte;
    Interleave: shortint;
    Name: string;
    ResTracks: byte;
    SectorSize: word;
    SectorsPerTrack: byte;
    SkewSide: shortint;
    SkewTrack: shortint;
    Sides: TDSKSpecSide;
    TracksPerSide: word;

    constructor Create(Format: integer);
    function GetCapacityBytes: integer;
    function GetDirectoryEntries: integer;
    function GetSectorID(Side: byte; LogicalTrack: word; Sector: byte): byte;
    function GetSidesCount: byte;
    function GetUsableBytes: integer;
  end;

const
  DSKImageFormats: array[TDSKImageFormat] of string = (
    'Standard DSK',
    'Extended DSK',
    'Not yet saved',
    'Invalid'
    );

  DSKSpecFormats: array[TDSKSpecFormat] of string = (
    'Amstrad PCW/+3 DD/SS/ST',
    'Amstrad CPC DD/SS/ST system',
    'Amstrad CPC DD/SS/ST data',
    'Amstrad PCW DD/DS/DT',
    'Amstrad PCW/+3 DD/SS/ST (Assumed)',
    'Invalid'
    );

  DSKSpecSides: array[TDSKSpecSide] of string = (
    'Single',
    'Double (Alternate)',
    'Double (Successive)',
    'Double (Reverse)',
    'Invalid'
    );

  DSKSpecTracks: array[TDSKSpecTrack] of string = (
    'Single',
    'Double',
    'Invalid'
    );

  DSKSectorStatus: array[TDSKSectorStatus] of string = (
    'Unformatted',
    'Formatted (track filler)',
    'Formatted (odd filler)',
    'Formatted (in use)'
    );

  // FileSystem
  DirEntSize = 32;

function GetFDCSectorSize(SectorSize: word): byte;

implementation

uses FormatAnalysis;

// Image
constructor TDSKImage.Create;
begin
  inherited Create;
  Disk := TDSKDisk.Create(Self);
  Creator := CreatorSig;
  Corrupt := False;
  Messages := TStringList.Create();
end;

destructor TDSKImage.Destroy;
begin
  Disk.Free;
  inherited Destroy;
end;

procedure TDSKImage.SetIsChanged(NewValue: boolean);
begin
  FIsChanged := NewValue;
end;

function TDSKImage.FindText(From: TDSKSector; Text: string;
  CaseSensitive: boolean): TDSKSector;
var
  NextSector: TDSKSector;
begin
  if (From = nil) then
    NextSector := Disk.Side[0].Track[0].Sector[0]
  else
    NextSector := GetNextLogicalSector(From);

  while (NextSector.FindText(Text, CaseSensitive) < 0) do
  begin
    NextSector := GetNextLogicalSector(NextSector);
  end;

  Result := NextSector;
end;

// TODO: Consider ID's and alternate sides
function TDSKImage.GetNextLogicalSector(Sector: TDSKSector): TDSKSector;
var
  SIdx, TIdx, AIdx: integer;
  Disk: TDSKDisk;
begin
  Disk := Sector.ParentTrack.ParentSide.ParentDisk;
  SIdx := Sector.Sector;
  TIdx := Sector.ParentTrack.Track;
  AIdx := Sector.ParentTrack.ParentSide.Side;

  // Next sector
  Inc(SIdx);

  // At end of sector, next track
  if (SIdx >= Sector.ParentTrack.Sectors) then
  begin
    SIdx := 0;
    Inc(TIdx);
    // Some tracks are unformatted, skip them
    while (Disk.Side[AIdx].Track[TIdx].Sectors = 0) do
    begin
      Inc(TIdx);
      if (TIdx = Sector.ParentTrack.ParentSide.Tracks) then
      begin
        Inc(AIdx);
        if (AIdx = Sector.ParentTrack.ParentSide.ParentDisk.Sides) then
        begin
          Result := nil;
          exit;
        end;
      end;
    end;
  end;

  Result := Sector.ParentTrack.ParentSide.ParentDisk.Side[AIdx].Track[TIdx].Sector[SIdx];
end;

function TDSKImage.LoadFile(LoadFileName: TFileName): boolean;
var
  DiskFile: TFileStream;
  DSKInfoBlock: TDSKInfoBlock;
begin
  Result := False;
  FileFormat := diInvalid;

  DiskFile := TFileStream.Create(LoadFileName, fmOpenRead or fmShareDenyNone);
  DiskFile.ReadBuffer(DSKInfoBlock, SizeOf(DSKInfoBlock));
  DiskFile.Seek(0, soFromBeginning);
  FileSize := DiskFile.Size;

  // Detect image format and load
  if (CompareBlock(DSKInfoBlock.DiskInfoBlock, 'MV - CPC')) then
  begin
    FileFormat := diStandardDSK;
    Result := LoadFileDSK(DiskFile);
  end;
  if (CompareBlock(DSKInfoBlock.DiskInfoBlock, 'EXTENDED CPC DSK File')) then
  begin
    FileFormat := diExtendedDSK;
    Result := LoadFileDSK(DiskFile);
  end;
  DiskFile.Free;

  if Result then
  begin
    FIsChanged := False;
    FileName := LoadFileName;
  end
  else
  if (FileFormat = diInvalid) then
    MessageDlg('Unknown file type. Load aborted.', mtWarning, [mbOK], 0);
end;

function TDSKImage.LoadFileDSK(DiskFile: TFileStream): boolean;
var
  DSKInfoBlock: TDSKInfoBlock;
  TRKInfoBlock: TTRKInfoBlock;
  SCTInfoBlock: TSCTInfoBlock;
  SIdx, TIdx, EIdx: integer;
  TOff, EOff: integer;
  ReadSize: integer;
  TrackSizeIdx: integer;
  SizeT: word;
begin
  Result := False;

  DiskFile.ReadBuffer(DSKInfoBlock, SizeOf(DSKInfoBlock));

  // Get the creator (DU54 puts in wrong place)
  if (CompareBlockStart(DSKInfoBlock.DiskInfoBlock, CreatorDU54, 16)) then
    Creator := CreatorDU54
  else
    Creator := StrBlockClean(DSKInfoBlock.Disk_Creator, 0, 14);

  if (DSKInfoBlock.Disk_NumTracks > MaxTracks) then
  begin
    Messages.Add(SysUtils.Format('Image indicates %d tracks, my limit is %d.',
      [DSKInfoBlock.Disk_NumTracks, MaxTracks]));
    Corrupt := True;
  end;

  // Build sides & tracks
  Disk.Sides := DSKInfoBlock.Disk_NumSides;
  for SIdx := 0 to DSKInfoBlock.Disk_NumSides - 1 do
    Disk.Side[SIdx].Tracks := DSKInfoBlock.Disk_NumTracks;

  // Load the tracks in
  for TIdx := 0 to DSKInfoBlock.Disk_NumTracks - 1 do
    for SIdx := 0 to DSKInfoBlock.Disk_NumSides - 1 do
    begin
      with Disk.Side[SIdx].Track[TIdx] do
      begin
        case FileFormat of
          diStandardDSK: SizeT := DSKInfoBlock.Disk_StdTrackSize - 256;
          diExtendedDSK:
          begin
            TrackSizeIdx := (TIdx * DSKInfoBlock.Disk_NumSides) + SIdx;
            SizeT := (DSKInfoBlock.Disk_ExtTrackSize[TrackSizeIdx] * 256);
            if (SizeT > 0) then
              SizeT := SizeT - 256; // Remove track-info size
          end;

          else
            SizeT := 0;
        end;

        TRKInfoBlock.TrackData := 'Damien';
        TOff := DiskFile.Position;
        Logical := (TIdx * DSKInfoBlock.Disk_NumSides) + SIdx;

        if (SizeT > 0) then // Don't load if track is unformatted
        begin
          ReadSize := SizeT + 256;
          if (TOff + ReadSize > FileSize) then
          begin
            Messages.Add(SysUtils.Format(
              'Side %d track %d indicated %d bytes of data' +
              ' but file had only %d bytes left.',
              [SIdx, TIdx, SizeT, FileSize - TOff]));
            Corrupt := True;
            ReadSize := FileSize - TOff;
          end;

          if (ReadSize > SizeOf(TRKInfoBlock)) then
          begin
            Messages.Add(SysUtils.Format(
              'Side %d track %d indicated %d bytes of data' +
              ' which is more than the %d bytes I can handle.',
              [SIdx, TIdx, SizeT, SizeOf(TRKInfoBlock.SectorData)]));
            Corrupt := True;
            DiskFile.ReadBuffer(TRKInfoBlock, SizeOf(TRKInfoBlock));
            DiskFile.Seek(ReadSize - SizeOf(TRKInfoBlock), soCurrent);
          end
          else
          begin
            DiskFile.ReadBuffer(TRKInfoBlock, ReadSize);
          end;

          // Test to make sure this was a track
          if (TRKInfoBlock.TrackData <> DiskInfoTrack) then
          begin
            MessageDlg(SysUtils.Format(
              'Side %d track %d not found at offset %d to %d. Load aborted.',
              [SIdx, TIdx, TOff, DiskFile.Position]), mtError, [mbOK], 0);
            exit;
          end;

          // Set various track info properties
          Track := TRKInfoBlock.TIB_TrackNum;
          Side := TRKInfoBlock.TIB_SideNum;
          Sectors := TRKInfoBlock.TIB_NumSectors;
          SectorSize := MaxSectorSize;
          if (TRKInfoBlock.TIB_SectorSize <= 6) then
            SectorSize := FDCSectorSizes[TRKInfoBlock.TIB_SectorSize];
          GapLength := TRKInfoBlock.TIB_GapLength;
          Filler := TRKInfoBlock.TIB_FillerByte;

          // Load the actual sectors in
          EOff := 0;
          for EIdx := 0 to Sectors - 1 do
            with Sector[EIdx] do
            begin
              Move(TRKInfoBlock.SectorInfoList[EIdx * SizeOf(SCTInfoBlock)],
                SCTInfoBlock, SizeOf(SCTInfoBlock));
              Sector := EIdx;
              Track := SCTInfoBlock.SIB_TrackNum;
              Side := SCTInfoBlock.SIB_SideNum;
              ID := SCTInfoBlock.SIB_ID;
              FDCSize := SCTInfoBlock.SIB_Size;
              FDCStatus[1] := SCTInfoBlock.SIB_FDC1;
              FDCStatus[2] := SCTInfoBlock.SIB_FDC2;

              case FileFormat of
                diStandardDSK:
                begin
                  DataSize := MaxSectorSize;
                  if (SCTInfoBlock.SIB_Size <= 6) then
                    DataSize := FDCSectorSizes[SCTInfoBlock.SIB_Size];
                end;
                diExtendedDSK: DataSize := SCTInfoBlock.SIB_DataLength;
                else
                  DataSize := 0;
              end;

              AdvertisedSize := DataSize;
              if (DataSize > MaxSectorSize) then
              begin
                Messages.Add(SysUtils.Format(
                  'Side %d track %d sector %d exceeds %d byte size limit.',
                  [TIdx, SIdx, EIdx, MaxSectorSize]));
                Corrupt := True;
                DataSize := MaxSectorSize;
              end;

              if (DataSize + EOff > SizeOf(TRKInfoBlock.SectorData)) then
              begin
                if (SizeOf(TRKInfoBlock.SectorData) - EOff) > 0 then
                  DataSize := SizeOf(TRKInfoBlock.SectorData) - EOff
                else
                  DataSize := 0;
                Corrupt := True;
              end;

              if (DataSize > 0) then
                Move(TRKInfoBlock.SectorData[EOff], Data, DataSize);
              EOff := EOff + AdvertisedSize;
            end;
        end;
      end;
    end;

  Result := True;
end;

function TDSKImage.SaveFile(SaveFileName: TFileName; SaveFileFormat: TDSKImageFormat;
  Copy: boolean; Compress: boolean): boolean;
var
  DiskFile: TFileStream;
begin
  Result := False;
  if (Corrupt) then
  begin
    MessageDlg('Image is corrupt. Save aborted.', mtError, [mbOK], 0);
    exit;
  end;

  DiskFile := TFileStream.Create(SaveFileName, fmCreate or fmOpenWrite);

  case SaveFileFormat of
    diStandardDSK: Result := SaveFileDSK(DiskFile, FileFormat, False);
    diExtendedDSK: Result := SaveFileDSK(DiskFile, FileFormat, Compress);
  end;

  DiskFile.Free;
  if not Result then
    MessageDlg('Could not save file. Save aborted.', mtError, [mbOK], 0)
  else
  if not Copy then
  begin
    FIsChanged := False;
    FileName := SaveFileName;
    Self.FileFormat := SaveFileFormat;
  end;
end;

// Save a DSK file
function TDSKImage.SaveFileDSK(DiskFile: TFileStream; SaveFileFormat: TDSKImageFormat;
  Compress: boolean): boolean;
var
  DSKInfoBlock: TDSKInfoBlock;
  TRKInfoBlock: TTRKInfoBlock;
  SCTInfoBlock: TSCTInfoBlock;
  SIdx, TIdx, EIdx, EOff: integer;
  TrackSize: word;
begin
  Result := False;

  FillChar(DSKInfoBlock, SizeOf(DSKInfoBlock), 0);

  // Construct disk info
  with DSKInfoBlock do
  begin
    Disk_NumTracks := Disk.Side[0].Tracks;
    Disk_NumSides := Disk.Sides;
    Move(CreatorSig, Disk_Creator, Length(CreatorSig));
    case SaveFileFormat of
      diStandardDSK:
      begin
        DiskInfoBlock := DiskInfoStandard;
        if Disk.Side[0].Track[0].Size > 0 then
          Disk_StdTrackSize := Disk.Side[0].Track[0].Size + 256
        else
          Disk_StdTrackSize := 0;

        for SIdx := 0 to Disk_NumSides - 1 do
          for TIdx := 0 to Disk_NumTracks - 1 do
            if (Disk.Side[SIdx].Track[TIdx].Size > Disk_StdTrackSize) then
              Disk_StdTrackSize := Disk.Side[SIdx].Track[TIdx].Size + 256;
      end;

      diExtendedDSK:
      begin
        DiskInfoBlock := DiskInfoExtended;
        for SIdx := 0 to Disk_NumSides - 1 do
          for TIdx := 0 to Disk_NumTracks - 1 do
            if (Compress and (Disk.Side[SIdx].Track[TIdx].Sectors = 0)) then
              Disk_ExtTrackSize[(TIdx * Disk_NumSides) + SIdx] := 0
            else
            if (Disk.Side[SIdx].Track[TIdx].Size > 0) then
            begin
              TrackSize := (Disk.Side[SIdx].Track[TIdx].Size div 256) + 1;
              // Track info 256
              if (Disk.Side[SIdx].Track[TIdx].Size mod 256 > 0) then
                TrackSize := TrackSize + 1;
              Disk_ExtTrackSize[(TIdx * Disk_NumSides) + SIdx] := TrackSize;
            end
            else
              Disk_ExtTrackSize[(TIdx * Disk_NumSides) + SIdx] := 0;
      end;
    end;
  end;

  DiskFile.WriteBuffer(DSKInfoBlock, SizeOf(DSKInfoBlock));

  // Write the tracks out
  for TIdx := 0 to DSKInfoBlock.Disk_NumTracks - 1 do
    for SIdx := 0 to Disk.Sides - 1 do
    begin
      with Disk.Side[SIdx].Track[TIdx] do
      begin
        // Set various track info properties
        FillChar(TRKInfoBlock, SizeOf(TRKInfoBlock), 0);
        with TRKInfoBlock do
        begin
          TrackData := DiskInfoTrack;
          TIB_TrackNum := Track;
          TIB_SideNum := Side;
          TIB_NumSectors := Sectors;
          TIB_SectorSize := GetFDCSectorSize(SectorSize);
          TIB_GapLength := GapLength;
          TIB_FillerByte := Filler;
        end;

        // Write the actual sectors out
        EOff := 0;
        for EIdx := 0 to Sectors - 1 do
          with Sector[EIdx] do
          begin
            FillChar(SCTInfoBlock, SizeOf(SCTInfoBlock), 0);
            with SCTInfoBlock do
            begin
              SIB_TrackNum := Track;
              SIB_SideNum := Side;
              SIB_ID := ID;
              SIB_Size := FDCSize;
              SIB_FDC1 := FDCStatus[1];
              SIB_FDC2 := FDCStatus[2];
              if (FileFormat = diExtendedDSK) then
                SIB_DataLength := DataSize;
            end;

            Move(SCTInfoBlock, TRKInfoBlock.SectorInfoList[EIdx *
              SizeOf(SCTInfoBlock)], SizeOf(SCTInfoBlock));
            Move(Data, TRKInfoBlock.SectorData[EOff], DataSize);
            EOff := EOff + DataSize;
          end;

        // Write the whole track out
        if (Size > 0) then
          case FileFormat of
            diStandardDSK: DiskFile.WriteBuffer(
                TRKInfoBlock, DSKInfoBlock.Disk_StdTrackSize);
            diExtendedDSK:
              if not (Compress and (Sectors = 0)) then
                DiskFile.WriteBuffer(TRKInfoBlock,
                  DSKInfoBlock.Disk_ExtTrackSize[(TIdx * Disk.Sides) + SIdx] * 256);
          end;
      end;
    end;
  Result := True;
end;


// Disk                                                  .
constructor TDSKDisk.Create(ParentImage: TDSKImage);
begin
  inherited Create;
  FParentImage := ParentImage;
  FSpecification := TDSKSpecification.Create(Self);
  FFileSystem := TDSKFileSystem.Create(Self);
end;

destructor TDSKDisk.Destroy;
begin
  FParentImage := nil;
  FSpecification.Free;
  FFileSystem.Free;
  inherited Destroy;
end;

procedure TDSKDisk.Format(Formatter: TDSKFormatSpecification);
var
  SIdx, TIdx: integer;
begin
  FParentImage.IsChanged := True;
  Sides := Formatter.GetSidesCount;
  for SIdx := 0 to Formatter.GetSidesCount - 1 do
    for TIdx := 0 to Formatter.TracksPerSide - 1 do
    begin
      Side[SIdx].SetTracks(Formatter.TracksPerSide);
      Side[SIdx].Track[TIdx].Track := TIdx;
      Side[SIdx].Track[TIdx].Side := SIdx;
      Side[SIdx].Track[TIdx].Format(Formatter);
    end;
end;

function TDSKDisk.GetSides: byte;
begin
  if (Side = nil) then
    Result := 0
  else
    Result := High(Side) + 1;
end;

procedure TDSKDisk.SetSides(NewSides: byte);
var
  OldSides: byte;
  Idx: byte;
begin
  OldSides := Sides;
  if (OldSides > NewSides) then
  begin
    for Idx := NewSides - 1 to OldSides do
      Side[Idx].Free;
    SetLength(Side, NewSides);
  end;

  if (NewSides > OldSides) then
  begin
    SetLength(Side, NewSides);
    for Idx := OldSides to NewSides - 1 do
    begin
      Side[Idx] := TDSKSide.Create(Self);
      Side[Idx].Side := Idx;
    end;
  end;
end;

function TDSKDisk.GetFormattedCapacity: integer;
var
  SIdx, TIdx: byte;
begin
  Result := 0;
  for SIdx := 0 to Sides - 1 do
    for TIdx := 0 to Side[SIdx].Tracks - 1 do
      Result := Result + Side[SIdx].Track[TIdx].Size;
end;

function TDSKDisk.GetTrackTotal: word;
var
  SIdx: byte;
begin
  Result := 0;
  if (Sides > 0) then
    for SIdx := 0 to Sides - 1 do
      Result := Result + Side[SIdx].Tracks;
end;

function TDSKDisk.GetLogicalTrack(LogicalTrack: word): TDSKTrack;
var
  PhTrack, PhSide: byte;
begin
  PhTrack := (LogicalTrack div Sides);
  PhSide := LogicalTrack mod Sides;
  Result := Side[PhSide].Track[phTrack];
end;

function TDSKDisk.IsTrackSizeUniform: boolean;
var
  SIdx, TIdx, LastSize: integer;
begin
  Result := True;
  LastSize := Side[0].Track[0].Size;
  for SIdx := 0 to Sides - 1 do
    for TIdx := 0 to Side[SIdx].Tracks - 1 do
      if (LastSize <> Side[SIdx].Track[TIdx].Size) then
        Result := False;
end;

function TDSKDisk.DetectFormat: string;
begin
  Result := AnalyseFormat(self);
end;

function TDSKDisk.BootableOn: string;
var
  Mod256: integer;
begin
  Result := 'None';
  if HasFirstSector then
  begin
    if (Side[0].Track[0].Sector[0].Status = ssFormattedInUse) then
    begin
      Mod256 := Side[0].Track[0].Sector[0].GetModChecksum(256);
      case Mod256 of
        1: Result := 'Amstrad PCW 9512';
        3: Result := 'Spectrum +3';
        255: Result := 'Amstrad PCW 8256';
        else
          if (Side[0].Track[0].Sector[0].ID = 65) then
            Result := 'Amstrad CPC 664/6128'
          else
            Result := SysUtils.Format('Unknown (%d)', [Mod256]);
      end;
    end;
    with Side[0].Track[0].Sector[0] do
      if (FDCStatus[1] and 32 = 32) or (FDCStatus[2] and 64 = 64) then
        Result := Result + ' (Corrupt?)';
  end;
end;

function TDSKDisk.HasFDCErrors: boolean;
var
  SIdx, TIdx, EIdx: integer;
begin
  Result := False;
  for SIdx := 0 to Sides - 1 do
    for TIdx := 0 to Side[SIdx].Tracks - 1 do
      for EIdx := 0 to Side[SIdx].Track[TIdx].Sectors - 1 do
        with Side[SIdx].Track[TIdx].Sector[EIdx] do
          if (FDCStatus[1] <> 0) or (FDCStatus[2] <> 0) then
            Result := True;
end;

function TDSKDisk.IsUniform(IgnoreEmptyTracks: boolean): boolean;
var
  SIdx, TIdx, EIdx: integer;
  CheckTracks, CheckSectors, CheckSectorSize: integer;
begin
  Result := True;
  if HasFirstSector then
  begin
    CheckTracks := Side[0].Tracks;
    CheckSectors := Side[0].Track[0].Sectors;
    CheckSectorSize := Side[0].Track[0].Sector[0].DataSize;
    for SIdx := 0 to Sides - 1 do
    begin
      if CheckTracks <> Side[SIdx].Tracks then
        Result := False;
      for TIdx := 0 to Side[SIdx].Tracks - 1 do
      begin
        if not ((Side[SIdx].Track[TIdx].Sectors = 0) and IgnoreEmptyTracks) then
          if CheckSectors <> Side[SIdx].Track[TIdx].Sectors then
            Result := False;
        for EIdx := 0 to Side[SIdx].Track[TIdx].Sectors - 1 do
          if CheckSectorSize <> Side[SIdx].Track[TIdx].Sector[EIdx].DataSize then
            Result := False;
      end;
    end;
  end;
end;

function TDSKDisk.HasFirstSector: boolean;
begin
  Result := False;
  if Sides > 0 then
    if Side[0].Tracks > 0 then
      if Side[0].Track[0].Sectors > 0 then
        Result := True;
end;


// Side                                                  .
constructor TDSKSide.Create(ParentDisk: TDSKDisk);
begin
  inherited Create;
  FParentDisk := ParentDisk;
end;

destructor TDSKSide.Destroy;
begin
  SetTracks(0);
  FParentDisk := nil;
  inherited Destroy;
end;

function TDSKSide.GetTracks: byte;
begin
  if (Track = nil) then
    Result := 0
  else
    Result := High(Track) + 1;
end;

function TDSKSide.GetHighTrackCount: byte;
begin
  Result := Tracks;
  while (not Track[Result - 1].IsFormatted) and (Result > 1) do
    Result := Result - 1;
end;

procedure TDSKSide.SetTracks(NewTracks: byte);
var
  OldTracks: byte;
  Idx: byte;
begin
  OldTracks := Tracks;
  if (OldTracks > NewTracks) then
  begin
    for Idx := NewTracks - 1 to OldTracks do
      Track[Idx].Free;
    SetLength(Track, NewTracks);
  end;

  if (NewTracks > OldTracks) then
  begin
    SetLength(Track, NewTracks);
    for Idx := OldTracks to NewTracks - 1 do
      Track[Idx] := TDSKTrack.Create(Self);
  end;
end;


// Track                                                .
constructor TDSKTrack.Create(ParentSide: TDSKSide);
begin
  inherited Create;
  FParentSide := ParentSide;
end;

destructor TDSKTrack.Destroy;
begin
  SetSectors(0);
  FParentSide := nil;
  inherited Destroy;
end;

function TDSKTrack.GetLowSectorID: byte;
var
  SIdx: byte;
begin
  Result := 255;
  for SIdx := 0 to Sectors - 1 do
    if Sector[SIdx].ID < Result then
      Result := Sector[SIdx].ID;
end;

function TDSKTrack.GetTrackSizeFromSectors: word;
var
  SIdx: byte;
begin
  Result := 0;
  if (Sectors > 0) then
    for SIdx := 0 to Sectors - 1 do
      Result := Result + Sector[SIdx].DataSize;
end;

function TDSKTrack.GetIsFormatted: boolean;
begin
  Result := (Sectors > 0);
end;

function TDSKTrack.GetSectors: byte;
begin
  if (Sector = nil) then
    Result := 0
  else
    Result := High(Sector) + 1;
end;

procedure TDSKTrack.Unformat;
begin
  Sectors := 0;
end;

procedure TDSKTrack.SetSectors(NewSectors: byte);
var
  OldSectors: byte;
  SIdx: byte;
begin
  if (NewSectors = 0) then
  begin
    SetLength(Sector, 0);
    exit;
  end;

  OldSectors := Sectors;

  if (OldSectors > NewSectors) then
  begin
    for SIdx := NewSectors - 1 to OldSectors do
      Sector[SIdx].Free;
    SetLength(Sector, NewSectors);
  end;

  if (NewSectors > OldSectors) then
  begin
    SetLength(Sector, NewSectors);
    for SIdx := OldSectors to NewSectors - 1 do
      Sector[SIdx] := TDSKSector.Create(Self);
  end;
end;

procedure TDSKTrack.Format(Formatter: TDSKFormatSpecification);
var
  EIdx: byte;
begin
  Filler := Formatter.FillerByte;
  SectorSize := Formatter.SectorSize;
  Sectors := Formatter.SectorsPerTrack;
  GapLength := Formatter.GapFormat;
  //  Size := Formatter.SectorsPerTrack * Formatter.SectorSize;

  case Formatter.Sides of
    dsSideSingle: Logical := Track;
    dsSideDoubleAlternate: Logical := (Track * Formatter.GetSidesCount) + Side;
    dsSideDoubleSuccessive: Logical := (Side * Formatter.TracksPerSide) + Track;
    dsSideDoubleReverse:
      if (Side = 0) then
        Logical := Track
      else
        Logical := Formatter.TracksPerSide - Track;
  end;

  for EIdx := 0 to Sectors - 1 do
  begin
    Sector[EIdx].Side := Side;
    Sector[EIdx].Track := Track;
    Sector[EIdx].Sector := EIdx;
    Sector[EIdx].FDCSize := Formatter.FDCSectorSize;
    Sector[EIdx].DataSize := Formatter.SectorSize;
    Sector[EIdx].ID := Formatter.GetSectorID(Side, Logical, Sector[EIdx].Sector);
    Sector[EIdx].FillSector(Formatter.FillerByte);
  end;
end;


// Sector
constructor TDSKSector.Create(ParentTrack: TDSKTrack);
begin
  inherited Create;
  FParentTrack := ParentTrack;
  ResetFDC;
  IsChanged := False;
end;

destructor TDSKSector.Destroy;
begin
  FParentTrack := nil;
  inherited Destroy;
end;

function TDSKSector.GetStatus: TDSKSectorStatus;
var
  FillByte: integer;
begin
  FillByte := GetFillByte;
  case FillByte of
    -2: Result := ssUnformatted;
    -1: Result := ssFormattedInUse;
    else
      if (FillByte = ParentTrack.Filler) then
        Result := ssFormattedBlank
      else
        Result := ssFormattedFilled;
  end;
end;

// Get filler byte or -1 if in use, -2 if unformatted
function TDSKSector.GetFillByte: integer;
var
  Idx: integer;
begin
  Result := -2;
  if (DataSize > 0) then
    Result := Data[0];
  for Idx := 0 to DataSize - 1 do
    if (Data[Idx] <> Data[0]) then
    begin
      Result := -1;
      break;
    end;
end;

procedure TDSKSector.ResetFDC;
var
  Idx: integer;
begin
  for Idx := 1 to SizeOf(FDCStatus) do
    if (FDCStatus[Idx] <> 0) then
    begin
      FDCStatus[Idx] := 0;
      IsChanged := True;
    end;
end;

procedure TDSKSector.FillSector(Filler: byte);
begin
  if (GetFillByte <> Filler) then
  begin
    FillChar(Data, DataSize, Filler);
    IsChanged := True;
  end;
end;

procedure TDSKSector.Unformat;
begin
  if (DataSize > 0) then
  begin
    FDCSize := 0;
    DataSize := 0;
    IsChanged := True;
  end;
end;

function TDSKSector.GetModChecksum(ModValue: integer): integer;
var
  Idx: integer;
begin
  Result := 0;
  for Idx := 0 to DataSize - 1 do
    Result := (Result + Data[Idx]) mod ModValue;
end;

function TDSKSector.FindText(Text: string; CaseSensitive: boolean): integer;
var
  Idx: integer;
  SIdx: integer;
  CharFound: boolean;
  TestChar: char;
begin
  if (DataSize = 0) then
  begin
    Result := -1;
    exit;
  end;

  SIdx := 1;
  for Idx := 0 to DataSize - 1 do
  begin
    CharFound := False;
    TestChar := char(Data[Idx]);

    if (CaseSensitive) and (TestChar = Text[SIdx]) then
      CharFound := True;
    if (not CaseSensitive) and (UpperCase(TestChar) = UpperCase(Text[SIdx])) then
      CharFound := True;

    if (CharFound) then
      Inc(SIdx)
    else
      SIdx := 1;

    if (SIdx = Length(Text) + 1) then
    begin
      Result := Idx;
      exit;
    end;
  end;

  Result := -1;
end;


// File system                                            .
constructor TDSKFileSystem.Create(ParentDisk: TDSKDisk);
begin
  inherited Create;
  FParentDisk := ParentDisk;
end;

destructor TDSKFileSystem.Destroy;
begin
  FParentDisk := nil;
  inherited Destroy;
end;

function TDSKFileSystem.GetDiskFile(Offset: integer): TDSKFile;
var
  DirBlock: TDSKSector;
  DirEnt: array[0..32] of char;
  Idx: integer;
begin
  Result := TDSKFile.Create(Self);
  for Idx := 0 to FParentDisk.Specification.DirectoryBlocks - 1 do
  begin
    DirBlock := FParentDisk.GetLogicalTrack(FParentDisk.Specification.FReservedTracks +
      Idx).Sector[0];
    with Result do
    begin
      Move(DirBlock.Data[Offset * DirEntSize], DirEnt, DirEntSize);
      FileName := StrBlockClean(DirEnt, 1, 8);
      Size := (integer(DirEnt[12]) * 256) + integer(DirEnt[13]);
      ;
      FileType := 'BASIC';
    end;
  end;
end;


// File                                                  .
constructor TDSKFile.Create(ParentFileSystem: TDSKFileSystem);
begin
  inherited Create;
  FParentFileSystem := ParentFileSystem;
end;

destructor TDSKFile.Destroy;
begin
  FParentFileSystem := nil;
  inherited Destroy;
end;


// Disk specification                                        .
constructor TDSKSpecification.Create(ParentDisk: TDSKDisk);
begin
  inherited Create;
  FParentDisk := ParentDisk;
end;

destructor TDSKSpecification.Destroy;
begin
  FParentDisk := nil;
  inherited Destroy;
end;

procedure TDSKSpecification.SetBlockSize(NewBlockSize: integer);
begin
  if (NewBlockSize <> FBlockSize) then
  begin
    FIsChanged := True;
    FBlockSize := NewBlockSize;
  end;
end;

procedure TDSKSpecification.SetChecksum(NewChecksum: byte);
begin
  if (NewChecksum <> FChecksum) then
  begin
    FIsChanged := True;
    FChecksum := NewChecksum;
  end;
end;

procedure TDSKSpecification.SetDirectoryBlocks(NewDirectoryBlocks: byte);
begin
  if (NewDirectoryBlocks <> FDirectoryBlocks) then
  begin
    FIsChanged := True;
    FDirectoryBlocks := NewDirectoryBlocks;
  end;
end;

procedure TDSKSpecification.SetFormat(NewFormat: TDSKSpecFormat);
begin
  if (NewFormat <> FFormat) then
  begin
    FIsChanged := True;
    FFormat := NewFormat;
  end;
end;

procedure TDSKSpecification.SetGapFormat(NewGapFormat: byte);
begin
  if (NewGapFormat <> FGapFormat) then
  begin
    FIsChanged := True;
    FGapFormat := NewGapFormat;
  end;
end;

procedure TDSKSpecification.SetGapReadwrite(NewGapReadWrite: byte);
begin
  if (NewGapReadWrite <> FGapReadWrite) then
  begin
    FIsChanged := True;
    FGapReadWrite := NewGapReadWrite;
  end;
end;

procedure TDSKSpecification.SetReservedTracks(NewReservedTracks: byte);
begin
  if (NewReservedTracks <> FReservedTracks) then
  begin
    FIsChanged := True;
    FReservedTracks := NewReservedTracks;
  end;
end;

procedure TDSKSpecification.SetSectorsPerTrack(NewSectorsPerTrack: byte);
begin
  if (NewSectorsPerTrack <> FSectorsPerTrack) then
  begin
    FIsChanged := True;
    FSectorsPerTrack := NewSectorsPerTrack;
  end;
end;

procedure TDSKSpecification.SetFDCSectorSize(NewFDCSectorSize: byte);
begin
  if (NewFDCSectorSize <> FFDCSectorSize) then
  begin
    FIsChanged := True;
    FFDCSectorSize := NewFDCSectorSize;
  end;
end;

procedure TDSKSpecification.SetSectorSize(NewSectorSize: word);
begin
  if (NewSectorSize <> FSectorSize) then
  begin
    FIsChanged := True;
    FSectorSize := NewSectorSize;
  end;
end;

procedure TDSKSpecification.SetSide(NewSide: TDSKSpecSide);
begin
  if (NewSide <> FSide) then
  begin
    FIsChanged := True;
    FSide := NewSide;
  end;
end;

procedure TDSKSpecification.SetTrack(NewTrack: TDSKSpecTrack);
begin
  if (NewTrack <> FTrack) then
  begin
    FIsChanged := True;
    FTrack := NewTrack;
  end;
end;

procedure TDSKSpecification.SetTracksPerSide(NewTracksPerSide: byte);
begin
  if (NewTracksPerSide <> FTracksPerSide) then
  begin
    FIsChanged := True;
    FTracksPerSide := NewTracksPerSide;
  end;
end;

function TDSKSpecification.Read: TDSKSpecFormat;
var
  Check: extended;
begin
  FFormat := dsFormatInvalid;
  Result := FFormat;
  if FParentDisk.HasFirstSector then
    with FParentDisk.Side[0].Track[0].Sector[0] do
    begin
      case Data[0] of
        0: FFormat := dsFormatPCW_SS;
        1: FFormat := dsFormatCPC_System;
        2: FFormat := dsFormatCPC_Data;
        3: FFormat := dsFormatPCW_DS;
        else
          exit;
      end;

      case (Data[1] and $3) of
        0: FSide := dsSideSingle;
        1: FSide := dsSideDoubleAlternate;
        2: FSide := dsSideDoubleSuccessive;
      end;

      if ((Data[1] and $80) = $80) then
        FTrack := dsTrackDouble
      else
        FTrack := dsTrackSingle;

      FTracksPerSide := Data[2];
      FSectorsPerTrack := Data[3];

      Check := Power(2, (Data[4] + 7));
      if (Check >= 0) and (Check <= 255) then
        FSectorSize := Round(Check)
      else
        FSectorSize := 0;

      FReservedTracks := Data[5];

      Check := Power(2, Data[6]) * 128;
      if (Check >= 0) and (Check <= 255) then
        FBlockSize := Round(Check)
      else
        FBlockSize := 0;

      FDirectoryBlocks := Data[7];
      FGapReadWrite := Data[8];
      FGapFormat := Data[9];
      FChecksum := Data[15];
    end;
  Result := FFormat;
end;

function TDSKSpecification.Write: boolean;
begin
  Result := False;
  if FParentDisk.HasFirstSector then
    with FParentDisk.Side[0].Track[0].Sector[0] do
    begin
      case FFormat of
        dsFormatPCW_SS: Data[0] := 0;
        dsFormatCPC_System: Data[0] := 1;
        dsFormatCPC_Data: Data[0] := 2;
        dsFormatPCW_DS: Data[0] := 3;
      end;

      case FSide of
        dsSideSingle: Data[1] := 0;
        dsSideDoubleAlternate: Data[1] := 1;
        dsSideDoubleSuccessive: Data[1] := 2;
      end;
      if FTrack = dsTrackDouble then
        Data[1] := (Data[1] or $80);

      Data[2] := FTracksPerSide;
      Data[3] := FSectorsPerTrack;
      Data[4] := Trunc(Log2(FSectorSize) - 7);
      Data[5] := FReservedTracks;
      Data[6] := Trunc(Log2(FBlockSize / 128));
      Data[7] := FDirectoryBlocks;
      Data[8] := FGapReadWrite;
      Data[9] := FGapFormat;
      Data[10] := 0;
      Data[11] := 0;
      Data[12] := 0;
      Data[13] := 0;
      Data[14] := 0;
      Data[15] := FChecksum;
      Result := True;
    end;
end;

// Disk format specifications                                  .
function TDSKFormatSpecification.GetCapacityBytes: integer;
begin
  Result := TracksPerSide * GetSidesCount * SectorsPerTrack * SectorSize;
end;

function TDSKFormatSpecification.GetDirectoryEntries: integer;
begin
  Result := (DirBlocks * BlockSize) div 32;
end;

function TDSKFormatSpecification.GetUsableBytes: integer;
var
  UsableTracks, UsableSectors, UsableBytes, WastedBytes: integer;
begin
  UsableTracks := (TracksPerSide * GetSidesCount) - ResTracks;
  UsableSectors := (UsableTracks * SectorsPerTrack);
  UsableBytes := (UsableSectors * SectorSize) - (DirBlocks * BlockSize);
  WastedBytes := UsableBytes mod BlockSize;
  Result := UsableBytes - WastedBytes;
end;

function TDSKFormatSpecification.GetSidesCount: byte;
begin
  if (Sides = dsSideSingle) then
    Result := 1
  else
    Result := 2;
end;

function TDSKFormatSpecification.GetSectorID(Side: byte; LogicalTrack: word;
  Sector: byte): byte;
var
  TrackSkewIdx: integer;
begin
  BuildSectorIDs;

  if (SkewTrack = 0) and ((SkewSide = 0) or (Sides = dsSideSingle)) then
  begin
    Result := FSectorIDs[Sector];
    exit;
  end;

  TrackSkewIdx := (SkewTrack * LogicalTrack);

  case Sides of
    dsSideDoubleAlternate:
    begin
      TrackSkewIdx := (SkewTrack * LogicalTrack) + (SkewSide * Side);
    end;

    dsSideDoubleSuccessive:
    begin
      TrackSkewIdx := (SkewTrack * LogicalTrack) + (SkewSide * Side);
    end;

    dsSideDoubleReverse:
    begin
      if (Side = 1) then
        TrackSkewIdx := ((TracksPerSide - LogicalTrack) * SkewTrack) +
          (SkewSide * Side);
    end;
  end;

  Result := FSectorIDs[(TrackSkewIdx + Sector) mod SectorsPerTrack];
end;

// Build sector ID table for interleave/skew
procedure TDSKFormatSpecification.BuildSectorIDs;
var
  EIdx, LastSectorID: byte;
  SIdx: integer;
begin
  SIdx := 0;
  LastSectorID := FirstSector;

  SetLength(FSectorIDs, SectorsPerTrack);
  for EIdx := 0 to SectorsPerTrack - 1 do
    FSectorIDs[EIdx] := 0;

  for EIdx := 0 to SectorsPerTrack - 1 do
  begin
    while (FSectorIDs[(SIdx mod SectorsPerTrack)] <> 0) do
      if Interleave > 0 then
        Inc(SIdx)
      else
      begin
        Dec(SIdx);
        if SIdx < 0 then
          SIdx := SectorsPerTrack + SIdx;
      end;

    FSectorIDs[(SIdx mod SectorsPerTrack)] := LastSectorID;
    Inc(LastSectorID);
    SIdx := (SIdx + Interleave);
    if SIdx < 0 then
      SIdx := SectorsPerTrack + SIdx;
  end;
end;

constructor TDSKFormatSpecification.Create(Format: integer);
begin
  inherited Create();  // Call the parent method

  // Amstrad PCW/Spectrum +3 CF2 (start from this)
  Name := 'Amstrad PCW/Spectrum +3';
  Sides := dsSideSingle;
  TracksPerSide := 40;
  SectorsPerTrack := 9;
  SectorSize := 512;
  GapRW := 42;
  GapFormat := 82;
  ResTracks := 1;
  DirBlocks := 2;
  BlockSize := 1024;
  FillerByte := 229;
  FirstSector := 1;
  Interleave := 1;
  SkewSide := 0;
  SkewTrack := 0;

  // And make appropriate changes
  case Format of
    1:
    begin
      Name := 'Amstrad PCW CF2DD';
      Sides := dsSideDoubleAlternate;
      TracksPerSide := 80;
      DirBlocks := 4;
      BlockSize := 2048;
    end;
    2:
    begin
      Name := 'Amstrad CPC System';
      FirstSector := 65;
      Interleave := 2;
    end;
    3:
    begin
      Name := 'Amstrad CPC data';
      ResTracks := 0;
      FirstSector := 193;
      Interleave := 2;
    end;
    4:
    begin
      Name := 'HiForm 203/Ian High';
      TracksPerSide := 42;
      SectorsPerTrack := 10;
      GapFormat := 22;
      GapRW := 12;
      Interleave := 3;
    end;
    5:
    begin
      Name := 'SuperMat 192/XCF2';
      TracksPerSide := 40;
      SectorsPerTrack := 10;
      DirBlocks := 3;
      GapFormat := 23;
      GapRW := 12;
    end;
    6:
    begin
      Name := 'Ultra 208/Ian Max';
      TracksPerSide := 42;
      SectorsPerTrack := 10;
      DirBlocks := 2;
      ResTracks := 0;
      Interleave := 3;
      SkewTrack := 2;
      GapFormat := 22; // Puts 128 into the spec block!?
      GapRW := 12;
    end;
    7:
    begin
      Name := 'Amstrad CPC IBM';
      SectorsPerTrack := 8;
      FirstSector := 1;
      Interleave := 2;
      GapFormat := 80;
    end;
    8:
    begin
      Name := 'MGT Sam Coupe';
      Sides := dsSideDoubleAlternate;
      TracksPerSide := 80;
      SectorsPerTrack := 10;
    end;
  end;
  self.FDCSectorSize := GetFDCSectorSize(self.SectorSize);
end;

function GetFDCSectorSize(SectorSize: word): byte;
var
  Idx: integer;
begin
  Result := High(FDCSectorSizes);
  for Idx := High(FDCSectorSizes) downto Low(FDCSectorSizes) do
    if (SectorSize <= FDCSectorSizes[Idx]) then
      Result := Idx;
end;

end.
