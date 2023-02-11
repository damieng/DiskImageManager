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
  DSKFormat, Utils, Classes, Dialogs, SysUtils, Math, Character;

const
  MaxSectorSize = 32768;
  Alt8KSize = 6144;
  FDCSectorSizes: array[0..8] of word = (128, 256, 512, 1024, 2048, 4096, 8192, 16384, MaxSectorSize);

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
    function SaveFileDSK(DiskFile: TFileStream; SaveFileFormat: TDSKImageFormat; Compress: boolean): boolean;
  public
    FileFormat: TDSKImageFormat;
    Messages: TStringList;

    constructor Create;
    destructor Destroy; override;

    function LoadFile(LoadFileName: TFileName): boolean;
    function LoadStream(FileStream: TFileStream): boolean;
    function SaveFile(SaveFileName: TFileName; SaveFileFormat: TDSKImageFormat; Copy: boolean; Compress: boolean): boolean;
    function FindText(From: TDSKSector; Text: string; CaseSensitive: boolean): TDSKSector;

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
    function DetectCopyProtection: string;
    function GetFirstSector: TDSKSector;
    function GetLogicalTrack(LogicalTrack: word): TDSKTrack;
    function GetNextLogicalSector(Sector: TDSKSector): TDSKSector;
    function GetSectorByBlock(Block: integer): TDSKSector;
    function GetAllStrings(MinLength: integer; MinUniques: integer): TStringList;
    function HasFDCErrors: boolean;
    function IsTrackSizeUniform: boolean;
    function IsUniform(IgnoreEmptyTracks: boolean): boolean;
    procedure Format(Formatter: TDSKFormatSpecification);

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

    function GetLargestTrackSize: integer;

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
    function GetFirstLogicalSector(): TDSKSector;

    property IsFormatted: boolean read GetIsFormatted;
    property LowSectorID: byte read GetLowSectorID;
    property ParentSide: TDSKSide read FParentSide;
    property Sectors: byte read GetSectors write SetSectors;
    property Size: word read GetTrackSizeFromSectors;
  end;


  // Sector
  TDSKSectorStatus = (ssUnformatted, ssFormattedBlank, ssFormattedFilled, ssFormattedInUse);

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
  TDSKSpecFormat = (dsFormatPCW_SS, dsFormatCPC_System, dsFormatCPC_Data, dsFormatPCW_DS,
    dsFormatAssumedPCW_SS, dsFormatInvalid);
  TDSKSpecSide = (dsSideSingle, dsSideDoubleAlternate, dsSideDoubleSuccessive, dsSideDoubleReverse, dsSideInvalid);
  TDSKSpecTrack = (dsTrackSingle, dsTrackDouble, dsTrackInvalid);

  TDSKSpecification = class(TObject)
  private
    FParentDisk: TDSKDisk;
    FIsChanged: boolean;
    FBlockShift: byte;
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
    procedure SetBlockShift(NewBlockShift: byte);
    procedure SetChecksum(NewChecksum: byte);
    procedure SetDefaults;
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
    Source: string;

    constructor Create(ParentDisk: TDSKDisk);
    destructor Destroy; override;

    procedure Read;
    function Write: boolean;
    function GetBlockSize: integer;
    function GetBlockCount: word;
    function GetUsableCapacity: integer;
    function GetRecordsPerTrack: integer;

    property BlockShift: byte read FBlockShift write SetBlockShift;
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

  // Disk format specification
  TDSKFormatSpecification = class(TObject)
  private
    FSectorIDs: array of byte;
    procedure BuildSectorIDs;
  public
    Bootable: boolean;
    BlockShift: byte;
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
    function GetBlockSize: integer;
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

function TDSKImage.FindText(From: TDSKSector; Text: string; CaseSensitive: boolean): TDSKSector;
var
  NextSector: TDSKSector;
begin
  if From = nil then
    NextSector := Disk.Side[0].Track[0].Sector[0]
  else
    NextSector := Disk.GetNextLogicalSector(From);

  while (NextSector <> nil) and (NextSector.FindText(Text, CaseSensitive) < 0) do
  begin
    NextSector := Disk.GetNextLogicalSector(NextSector);
  end;

  if NextSector = nil then
    MessageDlg(SysUtils.Format('Cannot find "%s"', [Text]), mtInformation, [mbOK], 0)
  else
    Result := NextSector;
end;

function TDSKImage.LoadFile(LoadFileName: TFileName): boolean;
var
  FileStream: TFileStream;
begin
  Result := False;

  FileStream := TFileStream.Create(LoadFileName, fmOpenRead or fmShareDenyNone);
  FileSize := FileStream.Size;
  FileName := LoadFileName;

  Result := LoadStream(FileStream);
  FileStream.Free;
end;

function TDSKImage.LoadStream(FileStream: TFileStream): boolean;
var
  DSKInfoBlock: TDSKInfoBlock;
begin
  FileFormat := diInvalid;
  FileStream.ReadBuffer(DSKInfoBlock, SizeOf(DSKInfoBlock));

  // Detect image format
  if CompareBlock(DSKInfoBlock.DiskInfoBlock, 'MV - CPC') then
    FileFormat := diStandardDSK;
  if CompareBlock(DSKInfoBlock.DiskInfoBlock, 'EXTENDED CPC DSK File') then
    FileFormat := diExtendedDSK;

  if FileFormat <> diInvalid then
  begin
    FileStream.Seek(0, soFromBeginning);
    Result := LoadFileDSK(FileStream);
    FIsChanged := False;
  end
  else
  begin
    MessageDlg('Unknown file type. Load aborted.', mtWarning, [mbOK], 0);
    Result := False;
  end;
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
  if CompareBlockStart(DSKInfoBlock.DiskInfoBlock, CreatorDU54, 16) then
    Creator := CreatorDU54
  else
    Creator := StrBlockClean(DSKInfoBlock.Disk_Creator, 0, 14);

  if DSKInfoBlock.Disk_NumTracks > MaxTracks then
  begin
    Messages.Add(SysUtils.Format('Image indicates %d tracks, my limit is %d.', [DSKInfoBlock.Disk_NumTracks, MaxTracks]));
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

        if SizeT > 0 then // Don't load if track is unformatted
        begin
          ReadSize := SizeT + 256;
          if TOff + ReadSize > FileSize then
          begin
            Messages.Add(SysUtils.Format('Side %d track %d indicated %d bytes of data' +
              ' but file had only %d bytes left.', [SIdx, TIdx, SizeT, FileSize - TOff]));
            Corrupt := True;
            ReadSize := FileSize - TOff;
          end;

          if ReadSize > SizeOf(TRKInfoBlock) then
          begin
            Messages.Add(SysUtils.Format('Side %d track %d indicated %d bytes of data' +
              ' which is more than the %d bytes I can handle.', [SIdx, TIdx, SizeT,
              SizeOf(TRKInfoBlock.SectorData)]));
            Corrupt := True;
            DiskFile.ReadBuffer(TRKInfoBlock, SizeOf(TRKInfoBlock));
            DiskFile.Seek(ReadSize - SizeOf(TRKInfoBlock), soCurrent);
          end
          else
          begin
            DiskFile.ReadBuffer(TRKInfoBlock, ReadSize);
          end;

          // Test to make sure this was a track
          if TRKInfoBlock.TrackData <> DiskInfoTrack then
          begin
            MessageDlg(SysUtils.Format('Side %d track %d not found at offset %d to %d. Load aborted.',
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
              if DataSize > MaxSectorSize then
              begin
                Messages.Add(SysUtils.Format('Side %d track %d sector %d exceeds %d byte size limit.',
                  [TIdx, SIdx, EIdx, MaxSectorSize]));
                Corrupt := True;
                DataSize := MaxSectorSize;
              end;

              if DataSize + EOff > SizeOf(TRKInfoBlock.SectorData) then
              begin
                if (SizeOf(TRKInfoBlock.SectorData) - EOff) > 0 then
                  DataSize := SizeOf(TRKInfoBlock.SectorData) - EOff
                else
                  DataSize := 0;
                Corrupt := True;
              end;

              if DataSize > 0 then
                Move(TRKInfoBlock.SectorData[EOff], Data, DataSize);
              EOff := EOff + AdvertisedSize;
            end;
        end;
      end;
    end;

  Result := True;
end;

function TDSKImage.SaveFile(SaveFileName: TFileName; SaveFileFormat: TDSKImageFormat; Copy: boolean; Compress: boolean): boolean;
var
  DiskFile: TFileStream;
  FileSize: int64;
begin
  Result := False;
  if Corrupt then
  begin
    MessageDlg('Image is corrupt. Save aborted.', mtError, [mbOK], 0);
    exit;
  end;

  DiskFile := TFileStream.Create(SaveFileName, fmCreate or fmOpenWrite);

  case SaveFileFormat of
    diStandardDSK: Result := SaveFileDSK(DiskFile, diStandardDSK, False);
    diExtendedDSK: Result := SaveFileDSK(DiskFile, diExtendedDSK, Compress);
    else
      MessageDlg(SysUtils.Format('Unknown file format %i', [SaveFileFormat]), mtError, [mbOK], 0);
  end;

  FileSize := DiskFile.Size;
  DiskFile.Free;

  if not Result then
    MessageDlg('Could not save file. Save aborted.', mtError, [mbOK], 0)
  else
  if not Copy then
  begin
    FIsChanged := False;
    FileName := SaveFileName;
    Self.FileFormat := SaveFileFormat;
    Self.FileSize := FileSize;
  end;
end;

// Save a DSK file
function TDSKImage.SaveFileDSK(DiskFile: TFileStream; SaveFileFormat: TDSKImageFormat; Compress: boolean): boolean;
var
  DSKInfoBlock: TDSKInfoBlock;
  TRKInfoBlock: TTRKInfoBlock;
  SCTInfoBlock: TSCTInfoBlock;
  SIdx, TIdx, EIdx, EOff: integer;
  TrackSize: word;
  Side: TDSKSide;
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
      diExtendedDSK:
      begin
        DiskInfoBlock := DiskInfoExtended;
        for SIdx := 0 to Disk_NumSides - 1 do
          for TIdx := 0 to Disk_NumTracks - 1 do
            if (Compress and (Disk.Side[SIdx].Track[TIdx].Sectors = 0)) then
              Disk_ExtTrackSize[(TIdx * Disk_NumSides) + SIdx] := 0
            else
            if Disk.Side[SIdx].Track[TIdx].Size > 0 then
            begin
              TrackSize := (Disk.Side[SIdx].Track[TIdx].Size div 256) + 1;
              // Track info 256
              if Disk.Side[SIdx].Track[TIdx].Size mod 256 > 0 then
                TrackSize := TrackSize + 1;
              Disk_ExtTrackSize[(TIdx * Disk_NumSides) + SIdx] := TrackSize;
            end
            else
              Disk_ExtTrackSize[(TIdx * Disk_NumSides) + SIdx] := 0;
      end;

      else
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
    end;
  end;

  DiskFile.WriteBuffer(DSKInfoBlock, SizeOf(DSKInfoBlock));

  // Write the tracks out
  for TIdx := 0 to DSKInfoBlock.Disk_NumTracks - 1 do
    for Side in Disk.Side do
    begin
      with Side.Track[TIdx] do
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
              if (SaveFileFormat = diExtendedDSK) then
                SIB_DataLength := DataSize;
            end;

            Move(SCTInfoBlock, TRKInfoBlock.SectorInfoList[EIdx * SizeOf(SCTInfoBlock)], SizeOf(SCTInfoBlock));
            Move(Data, TRKInfoBlock.SectorData[EOff], DataSize);
            EOff := EOff + DataSize;
          end;

        // Write the whole track out
        if Size > 0 then
          case SaveFileFormat of
            diStandardDSK: DiskFile.WriteBuffer(TRKInfoBlock, DSKInfoBlock.Disk_StdTrackSize);
            diExtendedDSK:
              if not (Compress and (Sectors = 0)) then
                DiskFile.WriteBuffer(TRKInfoBlock, DSKInfoBlock.Disk_ExtTrackSize[(TIdx * Disk.Sides) +
                  SIdx] * 256);
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
end;

destructor TDSKDisk.Destroy;
begin
  FParentImage := nil;
  FSpecification.Free;
  inherited Destroy;
end;

function TDSKDisk.GetSectorByBlock(Block: integer): TDSKSector;
var
  TargetOffset, Offset: integer;
  Sector: TDSKSector;
begin
  // In theory blocks should be a multiple of sectors
  TargetOffset := Block * Specification.GetBlockSize();

  Offset := 0;
  Sector := GetLogicalTrack(Specification.ReservedTracks).GetFirstLogicalSector();

  while (Sector <> nil) and (Offset + Sector.DataSize <= TargetOffset) do
  begin
    Offset := Offset + Sector.DataSize;
    Sector := GetNextLogicalSector(Sector);
  end;

  Result := Sector;
end;

function TDSKDisk.GetNextLogicalSector(Sector: TDSKSector): TDSKSector;
var
  NextSectorID: integer;
  CheckSector: TDSKSector;
  CheckTrack: TDSKTrack;
begin
  Result := nil;
  NextSectorId := Sector.ID + 1;
  CheckTrack := Sector.ParentTrack;

  while (CheckTrack <> nil) do
  begin
    // Find the next highest sector number on this track
    for CheckSector in CheckTrack.Sector do
    begin
      if CheckSector.ID >= NextSectorID then
        if (Result = nil) or (Result.ID > CheckSector.ID) then
          Result := CheckSector;
    end;
    if (Result <> nil) then exit;

    // Find the next logical track
    NextSectorID := 0;
    CheckTrack := GetLogicalTrack(CheckTrack.Logical + 1);
  end;
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
  if Side = nil then
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
  if OldSides > NewSides then
  begin
    for Idx := NewSides - 1 to OldSides do
      Side[Idx].Free;
    SetLength(Side, NewSides);
  end;

  if NewSides > OldSides then
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
  Side: TDSKSide;
  Track: TDSKTrack;
begin
  Result := 0;
  for Side in self.Side do
    for Track in Side.Track do
      Result := Result + Track.Size;
end;

function TDSKDisk.GetTrackTotal: word;
var
  Side: TDSKSide;
begin
  Result := 0;
  for Side in self.Side do
    Result := Result + Side.Tracks;
end;

function TDSKDisk.GetLogicalTrack(LogicalTrack: word): TDSKTrack;
var
  Side: TDSKSide;
  Track: TDSKTrack;
begin
  for Side in self.Side do
    for Track in Side.Track do
    begin
      if Track.Logical = LogicalTrack then
      begin
        Result := Track;
        exit;
      end;
    end;

  Result := nil;
end;

function TDSKDisk.IsTrackSizeUniform: boolean;
var
  Side: TDSKSide;
  Track: TDSKTrack;
  Size: integer;
begin
  Result := True;
  Size := self.Side[0].Track[0].Size;
  for Side in self.Side do
    for Track in Side.Track do
      if Size <> Track.Size then
      begin
        Result := False;
        exit;
      end;
end;

function TDSKDisk.DetectFormat: string;
begin
  Result := DetectUniformFormat(self);
end;

function TDSKDisk.DetectCopyProtection: string;
begin
  Result := DetectProtection(self.Side[0]);
end;

function TDSKDisk.BootableOn: string;
var
  Mod256: integer;
begin
  Result := '';
  if GetFirstSector <> nil then
  begin
    if Side[0].Track[0].Sector[1].Status = ssFormattedInUse then
    begin
      Mod256 := Side[0].Track[0].Sector[1].GetModChecksum(256);
      case Mod256 of
        1: Result := 'Amstrad PCW 9512';
        3: Result := 'Spectrum +3';
        255: Result := 'Amstrad PCW 8256';
        else
          case Side[0].Track[0].LowSectorID of
            65: Result := 'Amstrad CPC 664/6128';
            193: Result := ''; // CPC Data is not bootable
            else
              Result := SysUtils.Format('Unknown (%d checksum)', [Mod256]);
          end;
      end;
    end;
    with Side[0].Track[0].Sector[0] do
      if (FDCStatus[1] and 32 = 32) or (FDCStatus[2] and 64 = 64) then
        Result := Result + ' (Corrupt?)';
  end;
end;

const
  TrimChars: array[0..30] of char = (' ', '''', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '{',
    '}', ':', '"', '<', '>', '?', '-', '=', '[', ']', ';', ',', '.', '/', '`', '~');

function TDSKDisk.GetAllStrings(MinLength: integer; MinUniques: integer): TStringList;
var
  Sector: TDSKSector;
  CurrentText: string;
  Index, CIdx: integer;
  NextByte: byte;
  Uniques: TStringList;
  CurrChar: char;
begin
  Result := TStringList.Create;
  Result.Duplicates := DupIgnore;
  Result.Sorted := True;
  CurrentText := '';
  Sector := Side[0].Track[0].Sector[0];
  Index := Sides;
  Index := 0;
  Uniques := TStringList.Create;
  Uniques.Duplicates := DupIgnore;
  Uniques.Sorted := True;

  while Sector <> nil do
  begin
    NextByte := Sector.Data[Index];
    if (NextByte >= 32) and (NextByte <= 127) then
    begin
      CurrentText := CurrentText + Chr(NextByte);
    end
    else
    begin
      if CurrentText.Trim(TrimChars).Length >= MinLength then
      begin
        Uniques.Clear;
        for CIdx := 0 to CurrentText.Length - 1 do
        begin
          CurrChar := CurrentText[CIdx];
          if IsUpper(CurrChar) or IsLower(CurrChar) then Uniques.Append(CurrChar);
          if (Uniques.Count >= MinUniques) then break;
        end;

        if (Uniques.Count >= MinUniques) then
          Result.Append(CurrentText.Trim());
      end;
      CurrentText := '';
    end;

    Inc(Index);
    if Index = Sector.DataSize then
    begin
      Sector := GetNextLogicalSector(Sector);
      Index := 0;
    end;
  end;
end;

function TDSKDisk.HasFDCErrors: boolean;
var
  Side: TDSKSide;
  Track: TDSKTrack;
  Sector: TDSKSector;
begin
  Result := False;
  for Side in self.Side do
    for Track in Side.Track do
      for Sector in Track.Sector do
        if (Sector.FDCStatus[1] <> 0) or (Sector.FDCStatus[2] <> 0) then
        begin
          Result := True;
          exit;
        end;
end;

function TDSKDisk.IsUniform(IgnoreEmptyTracks: boolean): boolean;
var
  CheckTracks, CheckSectors, CheckSectorSize: integer;
  Side: TDSKSide;
  Track: TDSKTrack;
  Sector: TDSKSector;
begin
  Result := True;
  if GetFirstSector <> nil then
  begin
    CheckTracks := self.Side[0].Tracks;
    CheckSectors := self.Side[0].Track[0].Sectors;
    CheckSectorSize := self.Side[0].Track[0].Sector[0].DataSize;
    for Side in self.Side do
    begin
      if CheckTracks <> Side.Tracks then
      begin
        Result := False;
        exit;
      end;

      for Track in Side.Track do
      begin
        if not ((Track.Sectors = 0) and IgnoreEmptyTracks) then
          if CheckSectors <> Track.Sectors then
          begin
            Result := False;
            exit;
          end;

        for Sector in Track.Sector do
          if CheckSectorSize <> Sector.DataSize then
          begin
            Result := False;
            exit;
          end;
      end;
    end;
  end;
end;

function TDSKDisk.GetFirstSector: TDSKSector;
begin
  Result := nil;
  if (Sides > 0) and (Side[0].Tracks > 0) and (Side[0].Track[0].Sectors > 0) then
    Result := Side[0].Track[0].Sector[0];
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
  if Track = nil then
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

function TDSKSide.GetLargestTrackSize: integer;
var
  Track: TDSKTrack;
  Size: integer;
begin
  Result := 0;
  for Track in self.Track do
  begin
    Size := Track.GetTrackSizeFromSectors();
    if Size > Result then
      Result := Size;
  end;
end;

procedure TDSKSide.SetTracks(NewTracks: byte);
var
  OldTracks: byte;
  Idx: byte;
begin
  OldTracks := Tracks;
  if OldTracks > NewTracks then
  begin
    for Idx := NewTracks - 1 to OldTracks do
      Track[Idx].Free;
    SetLength(Track, NewTracks);
  end;

  if NewTracks > OldTracks then
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
  Sector: TDSKSector;
begin
  Result := 255;
  for Sector in self.Sector do
    if Sector.ID < Result then
      Result := Sector.ID;
end;

function TDSKTrack.GetTrackSizeFromSectors: word;
var
  Sector: TDSKSector;
begin
  Result := 0;
  for Sector in self.Sector do
    Result := Result + Sector.DataSize;
end;

function TDSKTrack.GetFirstLogicalSector: TDSKSector;
var
  Sector: TDSKSector;
begin
  if not IsFormatted then exit;

  Result := self.Sector[0];
  for Sector in self.Sector do
    if Sector.ID < Result.ID then
      Result := Sector;
end;

function TDSKTrack.GetIsFormatted: boolean;
begin
  Result := Sectors > 0;
end;

function TDSKTrack.GetSectors: byte;
begin
  if Sector = nil then
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
  if NewSectors = 0 then
  begin
    SetLength(Sector, 0);
    exit;
  end;

  OldSectors := Sectors;

  if OldSectors > NewSectors then
  begin
    for SIdx := NewSectors - 1 to OldSectors do
      Sector[SIdx].Free;
    SetLength(Sector, NewSectors);
  end;

  if NewSectors > OldSectors then
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

  case Formatter.Sides of
    dsSideSingle: Logical := Track;
    dsSideDoubleAlternate: Logical := (Track * Formatter.GetSidesCount) + Side;
    dsSideDoubleSuccessive: Logical := (Side * Formatter.TracksPerSide) + Track;
    dsSideDoubleReverse:
      if Side = 0 then
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
      if FillByte = ParentTrack.Filler then
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
  if DataSize > 0 then
    Result := Data[0];
  for Idx := 0 to DataSize - 1 do
    if Data[Idx] <> Data[0] then
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
    if FDCStatus[Idx] <> 0 then
    begin
      FDCStatus[Idx] := 0;
      IsChanged := True;
    end;
end;

procedure TDSKSector.FillSector(Filler: byte);
begin
  if GetFillByte <> Filler then
  begin
    FillChar(Data, DataSize, Filler);
    IsChanged := True;
  end;
end;

procedure TDSKSector.Unformat;
begin
  if DataSize > 0 then
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
  if DataSize = 0 then
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

    if CharFound then
      Inc(SIdx)
    else
      SIdx := 1;

    if SIdx = Length(Text) + 1 then
    begin
      Result := Idx;
      exit;
    end;
  end;

  Result := -1;
end;

// Disk specification                                        .
constructor TDSKSpecification.Create(ParentDisk: TDSKDisk);
begin
  inherited Create;
  FParentDisk := ParentDisk;
  Read;
end;

destructor TDSKSpecification.Destroy;
begin
  FParentDisk := nil;
  inherited Destroy;
end;

procedure TDSKSpecification.SetBlockShift(NewBlockShift: byte);
begin
  if NewBlockShift <> FBlockShift then
  begin
    FIsChanged := True;
    FBlockShift := NewBlockShift;
  end;
end;

function TDSKSpecification.GetBlockSize: integer;
begin
  Result := 2 << (BlockShift + 6);
end;

function TDSKSpecification.GetBlockCount: word;
begin
  Result := GetUsableCapacity div GetBlockSize;
end;

function TDSKSpecification.GetUsableCapacity: integer;
var
  UsableTracks: integer;
begin
  UsableTracks := FTracksPerSide;
  if Side <> dsSideSingle then UsableTracks := UsableTracks + UsableTracks;
  UsableTracks := UsableTracks - ReservedTracks;
  Result := UsableTracks * SectorsPerTrack * SectorSize;
end;

function TDSKSpecification.GetRecordsPerTrack: integer;
begin
  Result := (SectorSize * SectorsPerTrack) div 128;
end;

procedure TDSKSpecification.SetChecksum(NewChecksum: byte);
begin
  if NewChecksum <> FChecksum then
  begin
    FIsChanged := True;
    FChecksum := NewChecksum;
  end;
end;

procedure TDSKSpecification.SetDirectoryBlocks(NewDirectoryBlocks: byte);
begin
  if NewDirectoryBlocks <> FDirectoryBlocks then
  begin
    FIsChanged := True;
    FDirectoryBlocks := NewDirectoryBlocks;
  end;
end;

procedure TDSKSpecification.SetFormat(NewFormat: TDSKSpecFormat);
begin
  if NewFormat <> FFormat then
  begin
    FIsChanged := True;
    FFormat := NewFormat;
  end;
end;

procedure TDSKSpecification.SetGapFormat(NewGapFormat: byte);
begin
  if NewGapFormat <> FGapFormat then
  begin
    FIsChanged := True;
    FGapFormat := NewGapFormat;
  end;
end;

procedure TDSKSpecification.SetGapReadwrite(NewGapReadWrite: byte);
begin
  if NewGapReadWrite <> FGapReadWrite then
  begin
    FIsChanged := True;
    FGapReadWrite := NewGapReadWrite;
  end;
end;

procedure TDSKSpecification.SetReservedTracks(NewReservedTracks: byte);
begin
  if NewReservedTracks <> FReservedTracks then
  begin
    FIsChanged := True;
    FReservedTracks := NewReservedTracks;
  end;
end;

procedure TDSKSpecification.SetSectorsPerTrack(NewSectorsPerTrack: byte);
begin
  if NewSectorsPerTrack <> FSectorsPerTrack then
  begin
    FIsChanged := True;
    FSectorsPerTrack := NewSectorsPerTrack;
  end;
end;

procedure TDSKSpecification.SetFDCSectorSize(NewFDCSectorSize: byte);
begin
  if NewFDCSectorSize <> FFDCSectorSize then
  begin
    FIsChanged := True;
    FFDCSectorSize := NewFDCSectorSize;
  end;
end;

procedure TDSKSpecification.SetSectorSize(NewSectorSize: word);
begin
  if NewSectorSize <> FSectorSize then
  begin
    FIsChanged := True;
    FSectorSize := NewSectorSize;
  end;
end;

procedure TDSKSpecification.SetSide(NewSide: TDSKSpecSide);
begin
  if NewSide <> FSide then
  begin
    FIsChanged := True;
    FSide := NewSide;
  end;
end;

procedure TDSKSpecification.SetTrack(NewTrack: TDSKSpecTrack);
begin
  if NewTrack <> FTrack then
  begin
    FIsChanged := True;
    FTrack := NewTrack;
  end;
end;

procedure TDSKSpecification.SetTracksPerSide(NewTracksPerSide: byte);
begin
  if NewTracksPerSide <> FTracksPerSide then
  begin
    FIsChanged := True;
    FTracksPerSide := NewTracksPerSide;
  end;
end;

procedure TDSKSpecification.SetDefaults;
begin
  FFormat := dsFormatAssumedPCW_SS;
  FSide := dsSideSingle;
  FTrack := dsTrackSingle;
  FTracksPerSide := 40;
  FSectorsPerTrack := 9;
  FSectorSize := 512;
  FReservedTracks := 1;
  FBlockShift := 3;
  FDirectoryBlocks := 2;
  FGapReadWrite := 42;
  FGapFormat := 82;
end;

procedure TDSKSpecification.Read;
var
  FirstSector: TDSKSector;
  CheckByte: byte;
  Idx: integer;
  Check: extended;
begin
  FFormat := dsFormatInvalid;
  FirstSector := FParentDisk.GetFirstSector;
  if FirstSector = nil then exit;

  with FirstSector do
  begin
    case ID of
      65: begin // CPC System
        SetDefaults;
        Source := 'Sector 0 has ID of 65';
        FFormat := dsFormatCPC_System;
        FReservedTracks := 2;
        exit;
      end;
      193: begin // CPC Data
        SetDefaults;
        Source := 'Sector 0 has ID of 193';
        FFormat := dsFormatCPC_Data;
        FReservedTracks := 0;
        exit;
      end;
    end;

    if FirstSector.DataSize < 10 then exit;

    // If first 10 bytes are same value then PCW/+3
    CheckByte := FirstSector.Data[0];
    Idx := 1;
    while (CheckByte = FirstSector.Data[Idx]) and (Idx <= 10) do
      Inc(Idx);
    if Idx = 11 then
    begin
      SetDefaults;
      Source := SysUtils.Format('Sector 0 spec block is all %x', [CheckByte]);
    end;

    // Okay, finally lets check for a disk specification
    case Data[0] of
      0: FFormat := dsFormatPCW_SS;
      1: FFormat := dsFormatCPC_System;
      2: FFormat := dsFormatCPC_Data;
      3: FFormat := dsFormatPCW_DS;
      else
        exit;
    end;

    Source := 'Sector 0 spec block';

    case (Data[1] and $3) of
      0: FSide := dsSideSingle;
      1: FSide := dsSideDoubleAlternate;
      2: FSide := dsSideDoubleSuccessive;
    end;

    if (Data[1] and $80) = $80 then
      FTrack := dsTrackDouble
    else
      FTrack := dsTrackSingle;

    FTracksPerSide := Data[2];
    FSectorsPerTrack := Data[3];

    Check := Power(2, (Data[4] + 7));
    if (Check >= 0) and (Check <= 512) then
      FSectorSize := Round(Check)
    else
      FSectorSize := 0;

    FReservedTracks := Data[5];
    FBlockShift := Data[6];
    FDirectoryBlocks := Data[7];
    FGapReadWrite := Data[8];
    FGapFormat := Data[9];
    FChecksum := Data[15];
  end;
end;

function TDSKSpecification.Write: boolean;
begin
  Result := False;
  if FParentDisk.GetFirstSector <> nil then
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
      Data[6] := FBlockShift;
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

function TDSKFormatSpecification.GetBlockSize: integer;
begin
  Result := 2 << (BlockShift + 6);
end;

function TDSKFormatSpecification.GetDirectoryEntries: integer;
begin
  Result := (DirBlocks * GetBlockSize) div 32;
end;

function TDSKFormatSpecification.GetUsableBytes: integer;
var
  UsableTracks, UsableSectors, UsableBytes, WastedBytes: integer;
begin
  UsableTracks := (TracksPerSide * GetSidesCount) - ResTracks;
  UsableSectors := (UsableTracks * SectorsPerTrack);
  UsableBytes := (UsableSectors * SectorSize) - (DirBlocks * GetBlockSize);
  WastedBytes := UsableBytes mod GetBlockSize;
  Result := UsableBytes - WastedBytes;
end;

function TDSKFormatSpecification.GetSidesCount: byte;
begin
  if Sides = dsSideSingle then
    Result := 1
  else
    Result := 2;
end;

function TDSKFormatSpecification.GetSectorID(Side: byte; LogicalTrack: word; Sector: byte): byte;
var
  TrackSkewIdx: integer;
begin
  BuildSectorIDs;

  if (SkewTrack = 0) and ((SkewSide = 0) or (Sides = dsSideSingle)) then
  begin
    Result := FSectorIDs[Sector];
    exit;
  end;

  TrackSkewIdx := SkewTrack * LogicalTrack;

  case Sides of
    dsSideDoubleAlternate:
    begin
      TrackSkewIdx := TrackSkewIdx + (SkewSide * Side);
    end;

    dsSideDoubleSuccessive:
    begin
      TrackSkewIdx := TrackSkewIdx + (SkewSide * Side);
    end;

    dsSideDoubleReverse:
    else
    begin
      if (Side = 1) then
        TrackSkewIdx := ((TracksPerSide - LogicalTrack) * SkewTrack) + (SkewSide * Side);
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
    while FSectorIDs[(SIdx mod SectorsPerTrack)] <> 0 do
      if Interleave > 0 then
        Inc(SIdx)
      else
      begin
        Dec(SIdx);
        if SIdx < 0 then
          SIdx := SectorsPerTrack + SIdx;
      end;

    FSectorIDs[SIdx mod SectorsPerTrack] := LastSectorID;
    Inc(LastSectorID);
    SIdx := SIdx + Interleave;
    if SIdx < 0 then
      SIdx := SectorsPerTrack + SIdx;
  end;
end;

constructor TDSKFormatSpecification.Create(Format: integer);
begin
  inherited Create();

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
  BlockShift := 3;
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
      BlockShift := 4;
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
    if SectorSize <= FDCSectorSizes[Idx] then
      Result := Idx;
end;

end.
