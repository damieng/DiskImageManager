unit DskImage;

{
  Disk Image Manager -  Copyright 2002-2009 Envy Technologies Ltd.

  Virtual disk management
}

interface

uses
  Utils,
  Classes, Dialogs, SysUtils, Windows, Math;

const
  LoadCorruptWarn = 'Loading will continue in corrupted mode.';
  MaxSectorSize = 6144;
  MaxTracks = 204;
  FDCSectorSizes: array[0..6] of Word = (128, 256, 512, 1024, 2048, 4096, MaxSectorSize );

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
     FCreator: String;
     FDisk: TDSKDisk;
     FFileName: TFileName;
     FFileSize: Int64;
     FFingerPrint: String;
     FIsChanged: Boolean;
     FCorrupt: Boolean;

     procedure SetIsChanged(NewValue: Boolean);

     function LoadFileDSK(DiskFile: TFileStream): Boolean;
     function SaveFileDSK(DiskFile: TFileStream; SaveFileFormat: TDSKImageFormat; Compress:Boolean): Boolean;
  public
     FileFormat: TDSKImageFormat;

     constructor Create;
     destructor Destroy; override;

     function LoadFile(LoadFileName: TFileName): Boolean;
     function SaveFile(SaveFileName: TFileName; SaveFileFormat: TDSKImageFormat;	Copy:Boolean; Compress:Boolean): Boolean;

     function FindText(From: TDSKSector; Text: String; CaseSensitive: Boolean) : TDSKSector;
     function GetNextLogicalSector(Sector: TDSKSector): TDSKSector;

     property Creator: String read FCreator write FCreator;
     property Corrupt: Boolean read FCorrupt write FCorrupt;
     property Disk: TDSKDisk read FDisk write FDisk;
     property FileName: TFileName read FFileName write FFileName;
     property FileSize: Int64 read FFileSize write FFileSize;
     property IsChanged: Boolean read FIsChanged write SetIsChanged;
     property FingerPrint: String read FFingerPrint;
  end;


  // Disk
  TDSKDisk = class(TObject)
  private
     FFileSystem: TDSKFileSystem;
     FParentImage: TDSKImage;
     FSpecification: TDSKSpecification;

     function GetFormattedCapacity: Integer;
     function GetSides: Byte;
     function GetTrackTotal: Word;
     procedure SetSides(NewSides: Byte);
  public
    Side: array of TDSKSide;

    constructor Create(ParentImage: TDSKImage);
    destructor Destroy; override;

		function BootableOn: String;
    function DetectFormat: String;
    function DetectUniformFormat: String;
    function DetectWeirdFormat: String;
    function GetLogicalTrack(LogicalTrack: Word): TDSKTrack;
		function HasFDCErrors: Boolean;
		function HasFirstSector: Boolean;
    function IsTrackSizeUniform: Boolean;
    function IsUniform(IgnoreEmptyTracks: Boolean): Boolean;

		procedure Format(Formatter: TDSKFormatSpecification);

    property FileSystem: TDSKFileSystem read FFileSystem;
    property FormattedCapacity: Integer read GetFormattedCapacity;
    property Sides: Byte read GetSides write SetSides;
    property Specification: TDSKSpecification read FSpecification;
    property TrackTotal: Word read GetTrackTotal;
		property ParentImage: TDSKImage read FParentImage;
  end;


  // Side
  TDSKSide = class(TObject)
  private
     FParentDisk: TDSKDisk;

     function GetTracks: Byte;
     function GetHighTrackCount: Byte;

     procedure SetTracks(NewTracks: Byte);
  public
     Side: Byte;
     Track: array of TDSKTrack;

     constructor Create(ParentDisk: TDSKDisk);
     destructor Destroy; override;

     property ParentDisk: TDSKDisk read FParentDisk;
     property HighTrackCount: Byte read GetHighTrackCount;
     property Tracks: Byte read GetTracks write SetTracks;
  end;


  // Disk track
  TDSKTrack = class(TObject)
  private
     FParentSide: TDSKSide;

     function GetSectors: Byte;
     function GetIsFormatted: Boolean;

     procedure SetSectors(NewSectors: Byte);
  public
     Track: Byte;
     Side: Byte;
     Logical: Word;
     GapLength: Byte;
     SectorSize: Word;
     Filler: Byte;
     Sector: array of TDSKSector;

     constructor Create(ParentSide: TDSKSide);
     destructor Destroy; override;

  	 procedure Format(Formatter: TDSKFormatSpecification);
     procedure Unformat;

     function GetTrackSizeFromSectors: Word;

     property IsFormatted: Boolean read GetIsFormatted;
     property ParentSide: TDSKSide read FParentSide;
     property Sectors: Byte read GetSectors write SetSectors;
     property Size: Word read GetTrackSizeFromSectors;
  end;


  // Sector
  TDSKSectorStatus = (ssUnformatted, ssFormattedBlank, ssFormattedFilled, ssFormattedInUse);
  TDSKSector = class(TObject)
  private
    FDataSize: Word;
    FAdvertisedSize: Integer;
    FParentTrack: TDSKTrack;
    FIsChanged: Boolean;
		function GetStatus: TDSKSectorStatus;
  public
    Sector: Byte;
    Track: Byte;
    Side: Byte;
    ID: Byte;
    FDCSize: Byte;
    FDCStatus: array[1..2] of Byte;

    Data: array[0..MaxSectorSize] of Byte;

    constructor Create(ParentTrack: TDSKTrack);
    destructor Destroy; override;

    function GetModChecksum(ModValue: Integer): Integer;
		function GetFillByte: Integer;
    function FindText(Text: String; CaseSensitive: Boolean): Integer;

    procedure FillSector(Filler: Byte);
		procedure ResetFDC;
    procedure Unformat;

    property AdvertisedSize: Integer read FAdvertisedSize write FAdvertisedSize;
		property DataSize: Word read FDataSize write FDataSize;
    property IsChanged: Boolean read FIsChanged write FIsChanged;
    property ParentTrack: TDSKTrack read FParentTrack;
    property Status: TDSKSectorStatus read GetStatus;
  end;


  // Specification (Optional PCW/CPC+3 disk specification)
  TDSKSpecFormat = (dsFormatPCW_SS, dsFormatCPC_System, dsFormatCPC_Data,
  	dsFormatPCW_DS, dsFormatAssumedPCW_SS, dsFormatInvalid);
  TDSKSpecSide = (dsSideSingle, dsSideDoubleAlternate,
  	dsSideDoubleSuccessive, dsSideDoubleReverse, dsSideInvalid);
  TDSKSpecTrack = (dsTrackSingle, dsTrackDouble, dsTrackInvalid);

  TDSKSpecification = class(TObject)
  private
     FParentDisk: TDSKDisk;
     FIsChanged: Boolean;

     FBlockSize: Integer;
     FChecksum: Byte;
     FDirectoryBlocks: Byte;
     FFormat: TDSKSpecFormat;
     FGapFormat: Byte;
     FGapReadWrite: Byte;
     FReservedTracks: Byte;
     FSectorsPerTrack: Byte;
     FFDCSectorSize: Byte;
     FSectorSize: Word;
     FSide: TDSKSpecSide;
     FTrack: TDSKSpecTrack;
     FTracksPerSide: Byte;

     procedure SetBlockSize(NewBlockSize: Integer);
     procedure SetChecksum(NewChecksum: Byte);
     procedure SetDirectoryBlocks(NewDirectoryBlocks: Byte);
     procedure SetFormat(NewFormat: TDSKSpecFormat);
     procedure SetGapFormat(NewGapFormat: Byte);
     procedure SetGapReadwrite(NewGapReadWrite: Byte);
     procedure SetReservedTracks(NewReservedTracks: Byte);
     procedure SetSectorsPerTrack(NewSectorsPerTrack: Byte);
     procedure SetFDCSectorSize(NewFDCSectorSize: Byte);
     procedure SetSectorSize(NewSectorSize: Word);
     procedure SetSide(NewSide: TDSKSpecSide);
     procedure SetTrack(NewTrack: TDSKSpecTrack);
     procedure SetTracksPerSide(NewTracksPerSide: Byte);
  public
    constructor Create(ParentDisk: TDSKDisk);
    destructor Destroy; override;

    function Read: TDSKSpecFormat;
    function Write: Boolean;

		property BlockSize: Integer read FBlockSize write SetBlockSize;
    property Checksum: Byte read FChecksum write SetChecksum;
    property DirectoryBlocks: Byte read FDirectoryBlocks write SetDirectoryBlocks;
    property Format: TDSKSpecFormat read FFormat write SetFormat;
    property GapFormat: Byte read FGapFormat write SetGapFormat;
    property GapReadWrite: Byte read FGapReadWrite write SetGapReadWrite;
    property ReservedTracks: Byte read FReservedTracks write SetReservedTracks;
    property SectorsPerTrack: Byte read FSectorsPerTrack write SetSectorsPerTrack;
    property FDCSectorSize: Byte read FFDCSectorSize write SetFDCSectorSize;
    property SectorSize: Word read FSectorSize write SetSectorSize;
    property Side: TDSKSpecSide read FSide write SetSide;
    property Track: TDSKSpecTrack read FTrack write SetTrack;
    property TracksPerSide: Byte read FTracksPerSide write SetTracksPerSide;

    property IsChanged: Boolean read FIsChanged write FIsChanged;
  end;


  // File system abstraction
  TDSKFileSystem = class(TObject)
  private
    FParentDisk: TDSKDisk;
  public
    DiskFile: array of TDSKFile;

    constructor Create(ParentDisk: TDSKDisk);
    destructor Destroy; override;

    function GetDiskFile(Offset: Integer): TDSKFile;
  end;


  // File abstraction
  TDSKFile = class(TObject)
  private
    FParentFileSystem: TDSKFileSystem;
  public
    Data: array of Byte;
    Deleted: Boolean;
    FileName: String;
    FileType: String;
    Size: Integer;

    constructor Create(ParentFileSystem: TDSKFileSystem);
    destructor Destroy; override;
  end;


  // Disk format specification
  TDSKFormatSpecification = class(TObject)
	private
  	FSectorIDs: array of Byte;
    procedure BuildSectorIDs;
  public
  	Name: String;

    Bootable: Boolean;
    BlockSize: Word;
    DirBlocks: Byte;
    FillerByte: Byte;
    FirstSector: Byte;
    GapFormat: Byte;
    GapRW: Byte;
    Interleave: ShortInt;
    ResTracks: Byte;
    FDCSectorSize: Byte;
    SectorSize: Word;
    SectorsPerTrack: Byte;
     SkewSide: ShortInt;
     SkewTrack: ShortInt;
  	 Sides: TDSKSpecSide;
     TracksPerSide: Word;

		function GetCapacityBytes: Integer;
    function GetDirectoryEntries: Integer;
		function GetSectorID(Side: Byte; LogicalTrack: Word; Sector: Byte): Byte;
    function GetSidesCount: Byte;
		function GetUsableBytes: Integer;
  end;


  // DSK file format structure
  TDSKInfoBlock = packed record // Disk
     DiskInfoBlock:     array[0..33] of Char;
     Disk_Creator:      array[0..13] of Char;	// diExtendedDSK only
     Disk_NumTracks:    Byte;
     Disk_NumSides:     Byte;
     Disk_StdTrackSize: Word;						// diStandardDSK only
     Disk_ExtTrackSize: array[0..MaxTracks-1] of Byte; // diExtendedDSK only
  end;

  TTRKInfoBlock = packed record // Track
     TrackData:       array[0..12] of Char;
     TIB_pad1:        array[0..2] of Byte;
     TIB_TrackNum:    Byte;
     TIB_SideNum:     Byte;
     TIB_pad2:        Word;
     TIB_SectorSize:  Byte;
     TIB_NumSectors:  Byte;
     TIB_GapLength:   Byte;
     TIB_FillerByte:  Byte;
     SectorInfoList:  array[0..231] of Byte;
     SectorData:      array[0..32767] of Byte;
  end;

  TSCTInfoBlock = packed record // Sector
     SIB_TrackNum:   Byte;
     SIB_SideNum:    Byte;
     SIB_ID:         Byte;
     SIB_Size:       Byte;
     SIB_FDC1:       Byte;
     SIB_FDC2:       Byte;
     SIB_DataLength: Word;
  end;


const
  DSKImageFormats: array[TDSKImageFormat] of String = (
     'Standard DSK',
     'Extended DSK',
     'Not yet saved',
     'Invalid'
  );

  DSKSpecFormats: array[TDSKSpecFormat] of String = (
     'Amstrad PCW/+3 DD/SS/ST',
     'Amstrad CPC DD/SS/ST system',
     'Amstrad CPC DD/SS/ST data',
     'Amstrad PCW DD/DS/DT',
     'Amstrad PCW/+3 DD/SS/ST (Assumed)',
     'Invalid'
  );

  DSKSpecSides: array[TDSKSpecSide] of String = (
     'Single',
     'Double (Alternate)',
     'Double (Successive)',
     'Double (Reverse)',
     'Invalid'
  );

  DSKSpecTracks: array[TDSKSpecTrack] of String = (
     'Single',
     'Double',
     'Invalid'
  );

  DSKSectorStatus: array[TDSKSectorStatus] of String = (
  	'Unformatted',
     'Formatted (track filler)',
     'Formatted (odd filler)',
     'Formatted (in use)'
  );

	// DSK file strings
  DiskInfoStandard = 'MV - CPCEMU Disk-File' + #13 + #10 + 'Disk-Info' + #13 + #10;
  DiskInfoExtended = 'EXTENDED CPC DSK File' + #13 + #10 + 'Disk-Info' + #13 + #10;
  DiskInfoTrack = 'Track-Info' + #13 + #10;
  CreatorSig = 'SPIN Disk Man';
  CreatorDU54 = 'Disk Image (DU54)' + #13 + #10;

	// Copy protection ID strings
  ProtAlkatrazP3: String = ' THE ALKATRAZ PROTECTION SYSTEM   (C) 1987  Appleby Associates';
	ProtFrontier: String = 'W DISK PROTECTION SYSTEM. (C) 1990 BY NEW FRONTIER SOFT.';
  ProtHexagon: String = 'GON DISK PROTECTION c 1989 A.R.P';
  ProtPaulOwen : String = 'PAUL OWENS' + #128 + 'PROTECTION SYS';
  ProtSpeedLock1988: String = 'SPEEDLOCK DISC PROTECTION SYSTEMS (C) 1988 SPEEDLOCK ASSOCIATES';
  ProtSpeedLock1989: String = 'SPEEDLOCK DISC PROTECTION SYSTEMS (C) 1989 SPEEDLOCK ASSOCIATES';
  ProtSpeedLock1987P3: String = 'SPEEDLOCK +3 DISC PROTECTION SYSTEM COPYRIGHT 1987 SPEEDLOCK ASSOCIATES';
  ProtSpeedLock1988P3: String = 'SPEEDLOCK +3 DISC PROTECTION SYSTEM COPYRIGHT 1988 SPEEDLOCK ASSOCIATES';
  ProtThreeInchType1: String = '***Loader Copyright Three Inch Software 1988, All Rights Reserved. Three Inch Software, 73 Surbiton Road, Kingston upon Thames, KT1 2HG***';
  ProtThreeInchType2: String = '***Loader Copyright Three Inch Software 1988, All Rights Reserved. 01-546 2754';

  // FileSystem
  DirEntSize = 32;
  function GetFDCSectorSize(SectorSize: Word): Byte;

implementation

// Image
constructor TDSKImage.Create;
begin
  inherited Create;
  Disk := TDSKDisk.Create(Self);
  Creator := CreatorSig;
  Corrupt := False;
end;

destructor TDSKImage.Destroy;
begin
  Disk.Free;
  inherited Destroy;
end;

procedure TDSKImage.SetIsChanged(NewValue: Boolean);
begin
	If NewValue then FFingerPrint := '';
  FIsChanged := NewValue;
end;

function TDSKImage.FindText(From: TDSKSector; Text: String; CaseSensitive: Boolean) : TDSKSector;
var
  NextSector: TDSKSector;
begin
  If (From = nil) then
    NextSector := Disk.Side[0].Track[0].Sector[0]
  else
    NextSector := GetNextLogicalSector(From);

  while (NextSector.FindText(Text, CaseSensitive) < 0) do
  begin
    NextSector := GetNextLogicalSector(NextSector);
  end;

  Result := NextSector;
end;

// This is not logical sectors at the moment, that needs to consider ID's and alternate sides
function TDSKImage.GetNextLogicalSector(Sector: TDSKSector): TDSKSector;
var
  SIdx, TIdx, AIdx: Integer;
  Disk: TDSKDisk;
begin
  Disk := Sector.ParentTrack.ParentSide.ParentDisk;
  SIdx := Sector.Sector;
  TIdx := Sector.ParentTrack.Track;
  AIdx := Sector.ParentTrack.ParentSide.Side;

  // Next sector
  inc(SIdx);

  // At end of sector, next track
  if (SIdx >= Sector.ParentTrack.Sectors) then
  begin
    SIdx := 0;
    inc(TIdx);
    // Some tracks are unformatted, skip them
    while (Disk.Side[AIdx].Track[TIdx].Sectors = 0) do
    begin
      inc(TIdx);
      if (TIdx = Sector.ParentTrack.ParentSide.Tracks) then
      begin
        inc(AIdx);
        if (AIdx = Sector.ParentTrack.ParentSide.ParentDisk.Sides) then
        begin
          Result := nil;
          exit;
        end
      end
    end
  end;

  Result := Sector.ParentTrack.ParentSide.ParentDisk.Side[AIdx].Track[TIdx].Sector[SIdx];
end;

function TDSKImage.LoadFile(LoadFileName: TFileName): Boolean;
var
  DiskFile: TFileStream;
  DSKInfoBlock: TDSKInfoBlock;
begin
  Result := False;
  FileFormat := diInvalid;

  DiskFile := TFileStream.Create(LoadFileName, fmOpenRead or fmShareDenyNone);
  DiskFile.ReadBuffer(DSKInfoBlock,SizeOf(DSKInfoBlock));
  DiskFile.Seek(0,soFromBeginning);
  FileSize := DiskFile.Size;

  // Detect image format and load
  if (CompareBlock(DSKInfoBlock.DiskInfoBlock,'MV - CPC')) then
  begin
     FileFormat := diStandardDSK;
     Result := LoadFileDSK(DiskFile);
  end;
  if (CompareBlock(DSKInfoBlock.DiskInfoBlock,'EXTENDED CPC DSK File')) then
  begin
     FileFormat := diExtendedDSK;
     Result := LoadFileDSK(DiskFile);
  end;
  DiskFile.Free;

  if Result then
  begin
     FIsChanged := False;
     FFingerPrint := FingerPrintFile(LoadFileName);
     FileName := LoadFileName;
  end
  else
  	if (FileFormat = diInvalid) then
     	MessageDlg('Unknown file type. Load aborted.',mtWarning,[mbOK],0);
end;

function TDSKImage.LoadFileDSK(DiskFile: TFileStream): Boolean;
var
  DSKInfoBlock: TDSKInfoBlock;
  TRKInfoBlock: TTRKInfoBlock;
  SCTInfoBlock: TSCTInfoBlock;
  SIdx, TIdx, EIdx: Integer;
  TOff, EOff: Integer;
  ReadSize: Integer;
  TrackSizeIdx: Integer;
  SizeT: Word;
begin
  Result := False;

  DiskFile.ReadBuffer(DSKInfoBlock,SizeOf(DSKInfoBlock));

  // Get the creator (DU54 puts in wrong place)
  if (CompareBlockStart(DSKInfoBlock.DiskInfoBlock,CreatorDU54,16)) then
  	Creator := CreatorDU54
  else
  	Creator := StrBlockClean(DSKInfoBlock.Disk_Creator,0,14);

  if (DSKInfoBlock.Disk_NumTracks > MaxTracks) then
  begin
 		MessageDlg(Sysutils.Format('Image indicates %d tracks, my limit is %d. %s',
      [DSKInfoBlock.Disk_NumTracks,MaxTracks,LoadCorruptWarn]),mtWarning,[mbOK],0);
    Corrupt := True;
  end;

  // Build sides & tracks
  Disk.Sides := DSKInfoBlock.Disk_NumSides;
  for SIdx := 0 to DSKInfoBlock.Disk_NumSides-1 do
     Disk.Side[SIdx].Tracks := DSKInfoBlock.Disk_NumTracks;

  // Load the tracks in
  for TIdx := 0 to DSKInfoBlock.Disk_NumTracks-1 do
     for SIdx := 0 to DSKInfoBlock.Disk_NumSides-1 do
     begin
        with Disk.Side[SIdx].Track[TIdx] do
        begin
           case FileFormat of
              diStandardDSK: SizeT := DSKInfoBlock.Disk_StdTrackSize - 256;
              diExtendedDSK:
              begin
                TrackSizeIdx := (TIdx * DSKInfoBlock.Disk_NumSides) + SIdx;
	              SizeT := (DSKInfoBlock.Disk_ExtTrackSize[TrackSizeIdx] * 256);
                if (SizeT > 0) then SizeT := SizeT - 256; // Remove track-info size
              end;

              else SizeT := 0;
           end;

           TRKInfoBlock.TrackData := 'Damien';
           TOff := DiskFile.Position;
           Logical := (TIdx * DSKInfoBlock.Disk_NumSides) + SIdx;

           if (SizeT > 0) then // Don't load if track is unformatted
           begin
              ReadSize := SizeT+256;
              if (TOff+ReadSize > FileSize) then
              begin
                MessageDlg(Sysutils.Format('Side %d track %d indicates %d bytes of data' +
                          ' but file had only %d bytes left. %s',
                       	 [SIdx,TIdx,SizeT,FileSize-TOff,LoadCorruptWarn]),mtWarning,[mbOK],0);
                Corrupt := True;
                ReadSize := FileSize - TOff;
              end;

              if (ReadSize > SizeOf(TRKInfoBlock)) then
              begin
              	MessageDlg(Sysutils.Format('Side %d track %d indicated %d bytes of data' +
                             ' which is more than my %d byte track buffer. %s',
                         		[SIdx,TIdx,SizeT,SizeOf(TRKInfoBlock.SectorData),LoadCorruptWarn]),mtWarning,[mbOK],0);
                Corrupt := True;
            		DiskFile.ReadBuffer(TRKInfoBlock,SizeOf(TRKInfoBlock));
                DiskFile.Seek(ReadSize-SizeOf(TRKInfoBlock), soCurrent);
              end
              else
              begin
            		DiskFile.ReadBuffer(TRKInfoBlock,ReadSize);
              end;

           // Test to make sure this was a track
           if (TRKInfoBlock.TrackData <> DiskInfoTrack) then
           begin
              MessageDlg(Sysutils.Format('Side %d track %d not found at offset %d to %d. Load aborted.',
                 [SIdx,TIdx,TOff,DiskFile.Position]),mtError,[mbOK],0);
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
           for EIdx := 0 to Sectors-1 do
               with Sector[EIdx] do
               begin
                 Move(TRKInfoBlock.SectorInfoList[EIdx * SizeOf(SCTInfoBlock)], SCTInfoBlock, SizeOf(SCTInfoBlock));
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
                    else DataSize := 0;
                 end;

                 AdvertisedSize := DataSize;
                 if (DataSize > MaxSectorSize) then
                 begin
		              MessageDlg(Sysutils.Format('Side %d track %d sector %d exceeds %d byte size limit. %s',
     	            	[TIdx,SIdx,EIdx,MaxSectorSize,LoadCorruptWarn]),mtWarning,[mbOK],0);
                    Corrupt := True;
                    DataSize := MaxSectorSize;
                 end;

                 if (DataSize+EOff > SizeOf(TRKInfoBlock.SectorData)) then
                 begin
                   if (SizeOf(TRKInfoBlock.SectorData)-EOff) > 0 then
                     DataSize := SizeOf(TRKInfoBlock.SectorData)-EOff
                   else
                     DataSize := 0;
                   Corrupt := True;
                 end;

                 if (DataSize > 0) then
                    Move(TRKInfoBlock.SectorData[EOff],Data,DataSize);
                 EOff := EOff + AdvertisedSize;
           end;
        end;
     end;
  end;

  Result := True;
end;

function TDSKImage.SaveFile(SaveFileName: TFileName; SaveFileFormat: TDSKImageFormat; Copy: Boolean; Compress:Boolean): Boolean;
var
  DiskFile: TFileStream;
begin
  Result := False;
  if (Corrupt) then
  begin
    MessageDlg('Image is corrupt. Save aborted.', mtError,[mbOK],0);
    exit;
  end;

  DiskFile := TFileStream.Create(SaveFileName, fmCreate or fmOpenWrite);

  case SaveFileFormat of
     diStandardDSK:
        Result :=
           SaveFileDSK(DiskFile, FileFormat, False);
     diExtendedDSK:
        Result :=
           SaveFileDSK(DiskFile, FileFormat, Compress);
  end;

  DiskFile.Free;
  if Not Result then
     MessageDlg('Could not save file. Save aborted.',mtError,[mbOK],0)
  else
  	if Not Copy then
	   begin
     	FIsChanged := False;
        FFingerPrint := FingerPrintFile(SaveFileName);
     	FileName := SaveFileName;
        Self.FileFormat := SaveFileFormat;
  	end;
end;

// Save a DSK file
function TDSKImage.SaveFileDSK(DiskFile: TFileStream; SaveFileFormat: TDSKImageFormat; Compress:Boolean): Boolean;
var
  DSKInfoBlock: TDSKInfoBlock;
  TRKInfoBlock: TTRKInfoBlock;
  SCTInfoBlock: TSCTInfoBlock;
  SIdx, TIdx, EIdx, EOff: Integer;
  TrackSize: Word;
begin
  Result := False;

	FillChar(DSKInfoBlock,SizeOf(DSKInfoBlock),0);

  // Construct disk info
  with DSKInfoBlock do
  begin
     Disk_NumTracks := Disk.Side[0].Tracks;
     Disk_NumSides := Disk.Sides;
     Move(CreatorSig,Disk_Creator,Length(CreatorSig));
     case SaveFileFormat of

      	diStandardDSK:
        	begin
	           DiskInfoBlock := DiskInfoStandard;
             if Disk.Side[0].Track[0].Size > 0 then
                Disk_StdTrackSize := Disk.Side[0].Track[0].Size + 256
             else
                Disk_StdTrackSize := 0;

	           for SIdx := 0 to Disk_NumSides-1 do
	              for TIdx := 0 To Disk_NumTracks-1 do
	                 if (Disk.Side[SIdx].Track[TIdx].Size > Disk_StdTrackSize) then
                      Disk_StdTrackSize := Disk.Side[SIdx].Track[TIdx].Size + 256;
	        end;

        diExtendedDSK:
    		    begin
        	   DiskInfoBlock := DiskInfoExtended;
           	for SIdx := 0 to Disk_NumSides-1 do
              	for TIdx := 0 To Disk_NumTracks-1 do
                 	if (Compress and (Disk.Side[SIdx].Track[TIdx].Sectors=0)) then
	                 		Disk_ExtTrackSize[(TIdx * Disk_NumSides) + SIdx] := 0
                    else
                    	if (Disk.Side[SIdx].Track[TIdx].Size > 0) then
                         begin
                           TrackSize := (Disk.Side[SIdx].Track[TIdx].Size div 256) + 1; // Track info 256
                           if (Disk.Side[SIdx].Track[TIdx].Size mod 256 > 0) then TrackSize := TrackSize + 1;
	                 			   Disk_ExtTrackSize[(TIdx * Disk_NumSides) + SIdx] := TrackSize;
                         end
                       else
	                 			 Disk_ExtTrackSize[(TIdx * Disk_NumSides) + SIdx] := 0;
        end;
     end;
  end;

  DiskFile.WriteBuffer(DSKInfoBlock,SizeOf(DSKInfoBlock));

  // Write the tracks out
  for TIdx := 0 to DSKInfoBlock.Disk_NumTracks-1 do
     for SIdx := 0 to Disk.Sides-1 do
     begin
        with Disk.Side[SIdx].Track[TIdx] do
        begin
           // Set various track info properties
				FillChar(TRKInfoBlock,SizeOf(TRKInfoBlock),0);
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
           for EIdx := 0 to Sectors-1 do
              with Sector[EIdx] do
              begin
                 FillChar(SCTInfoBlock,SizeOf(SCTInfoBlock),0);
                 with SCTInfoBlock do
                 begin
                    SIB_TrackNum := Track;
                    SIB_SideNum := Side;
                    SIB_ID := ID;
                    SIB_Size := FDCSize;
                    SIB_FDC1 := FDCStatus[1];
                    SIB_FDC2 := FDCStatus[2];
                    if (FileFormat = diExtendedDSK) then SIB_DataLength := DataSize;
                 end;

                 Move(SCTInfoBlock,TRKInfoBlock.SectorInfoList[EIdx * SizeOf(SCTInfoBlock)],SizeOf(SCTInfoBlock));
                 Move(Data,TRKInfoBlock.SectorData[EOff],DataSize);
                 EOff := EOff + DataSize;
              end;

           // Write the whole track out
				   if (Size > 0) then
	            case FileFormat of
    	         	diStandardDSK:
                    DiskFile.WriteBuffer(TRKInfoBlock,DSKInfoBlock.Disk_StdTrackSize);
              	diExtendedDSK:
                    if not (Compress and (Sectors = 0)) then
                     	DiskFile.WriteBuffer(TRKInfoBlock,DSKInfoBlock.Disk_ExtTrackSize[(TIdx * Disk.Sides) + SIdx] * 256);
           	end;
        end;
     end;
  Result := True;
end;


// Disk																								  .
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
	SIdx, TIdx: Integer;
begin
	FParentImage.IsChanged := True;
  Sides := Formatter.GetSidesCount;
	for SIdx := 0 to Formatter.GetSidesCount-1 do
	  for TIdx := 0 to Formatter.TracksPerSide-1 do
    begin
    	 Side[SIdx].SetTracks(Formatter.TracksPerSide);
      Side[SIdx].Track[TIdx].Track := TIdx;
      Side[SIdx].Track[TIdx].Side := SIdx;
      Side[SIdx].Track[TIdx].Format(Formatter);
    end;
end;

function TDSKDisk.GetSides: Byte;
begin
  if (Side = nil) then
     Result := 0
  else
     Result := High(Side) + 1;
end;

procedure TDSKDisk.SetSides(NewSides: Byte);
var
  OldSides: Byte;
  Idx: Byte;
begin
  OldSides := Sides;
  if (OldSides > NewSides) then
  begin
     for Idx := NewSides-1 to OldSides do Side[Idx].Free;
     SetLength(Side,NewSides);
  end;

  if (NewSides > OldSides) then
  begin
     SetLength(Side,NewSides);
     for Idx := OldSides to NewSides-1 do
     begin
       Side[Idx] := TDSKSide.Create(Self);
       Side[Idx].Side := Idx;
     end;
  end;
end;

function TDSKDisk.GetFormattedCapacity: Integer;
var
  SIdx,TIdx: Byte;
begin
  Result := 0;
  for SIdx := 0 to Sides-1 do
     for TIdx := 0 to Side[SIdx].Tracks-1 do
        Result := Result + Side[SIdx].Track[TIdx].Size;
end;

function TDSKDisk.GetTrackTotal: Word;
var
  SIdx: Byte;
begin
  Result := 0;
  if (Sides > 0) then
     for SIdx := 0 to Sides-1 do Result := Result + Side[SIdx].Tracks;
end;

function TDSKDisk.GetLogicalTrack(LogicalTrack: Word): TDSKTrack;
var
  PhTrack, PhSide: Byte;
begin
  PhTrack := (LogicalTrack div Sides);
  PhSide := LogicalTrack mod Sides;
  Result := Side[PhSide].Track[phTrack];
end;

function TDSKDisk.IsTrackSizeUniform: Boolean;
var
	SIdx, TIdx, LastSize: Integer;
begin
	Result := True;
  LastSize := Side[0].Track[0].Size;
	for SIdx := 0 to Sides-1 do
  	for TIdx := 0 to Side[SIdx].Tracks-1 do
			if (LastSize <> Side[SIdx].Track[TIdx].Size) then
        	Result := False;
end;

function TDSKDisk.DetectFormat: String;
var
  Weird: String;
begin
  if (not HasFirstSector) then
  	Result := 'Unformatted'
  else
  begin
    Weird := DetectWeirdFormat();
    if (IsUniform(True)) then
      if (Weird = '') then
        Result := DetectUniformFormat()
      else
        Result := DetectUniformFormat() + ' with ' + Weird
    else
      Result := Weird;
    if (Result = '') then
      Result := 'Unknown';
  end;
end;

function TDSKDisk.DetectUniformFormat: String;
begin
	// Amstrad formats (9 sectors, 512 size, SS or DS)
  if (Side[0].Track[0].Sectors = 9) and
    (Side[0].Track[0].Sector[0].DataSize = 512) then
    begin
      case Side[0].Track[0].Sector[0].ID of
				  1:    begin
		          		Result := 'Amstrad PCW/Spectrum +3';
             	    case Side[0].Track[0].Sector[0].GetModChecksum(256) of
						     	    1:	Result := 'Amstrad PCW 9512';
  							  	  3:	Result := 'Spectrum +3';
	  							  255:  Result := 'Amstrad PCW 8256';
							    end;
	                if (Sides = 1) then
                    Result := Result + ' CF2'
                 	else
                 	  Result := Result + ' CF2DD';
		        		end;
		     	65: 	Result := 'Amstrad CPC system';
	        193: 	Result := 'Amstrad CPC data';
       	end;
				if (Side[0].HighTrackCount > (Sides*40)) then Result := Result + ' (oversized)';
				if (Side[0].HighTrackCount < (Sides*40)) then Result := Result + ' (undersized)';
    end
    else
    begin
      // Other possible formats...
      case Side[0].Track[0].Sector[0].ID of
          1:  if (Side[0].Track[0].Sectors = 8) then Result := 'Amstrad CPC IBM';
         65:  Result := 'Amstrad CPC system custom (maybe)';
        193:  Result := 'Amstrad CPC data custom (maybe)';
      end;
    end;

    // Custom speccy formats (10 sectors, SS)
  	if (Sides = 1) and (Side[0].Track[0].Sectors = 10) then
    begin
    	// HiForm/Ultra208 (Chris Pile) + Ian Collier's skewed versions
      if (Side[0].Track[0].Sector[0].DataSize > 10) then
      begin
        if (Side[0].Track[0].Sector[0].Data[2] = 42) and
          (Side[0].Track[0].Sector[0].Data[8] = 12) then
        case Side[0].Track[0].Sector[0].Data[5] of
          0:	if (Side[0].Track[0].Sector[1].ID = 8) then
              		case Side[0].Track[1].Sector[0].ID of
                    7:		Result := 'Ultra 208/Ian Max';
                    8:		Result := 'Possibly Ultra 208 or Ian Max (skew lost)';
                    else	Result := 'Possibly Ultra 208 or Ian Max (custom skew)';
                  end
              else
                Result := 'Possibly Ultra 208 or Ian Max (interleave lost)';
          1:  if (Side[0].Track[0].Sector[1].ID = 8) then
              		case Side[0].Track[1].Sector[0].ID of
                    7:    Result := 'Ian High';
								    1:    Result := 'HiForm 203';
                    else 	Result := 'Possibly HiForm 203 or Ian High (custom skew)';
              		end;
          		else
                Result := 'Possibly HiForm or Ian High (interleave lost)';
        end;
       	// Supermat 192 (Ian Cull)
        if (Side[0].Track[0].Sector[0].Data[7] = 3) and
          (Side[0].Track[0].Sector[0].Data[9] = 23) and
        	(Side[0].Track[0].Sector[0].Data[2] = 40) then
        	  Result := 'Supermat 192/XCF2';
      end
    end;

    // Sam Coupe formats
    if (Sides = 2) and (Side[0].Track[0].Sectors = 10) and
      (Side[0].GetHighTrackCount = 80) and
      (Side[0].Track[0].Sector[0].ID = 1) and
      (Side[0].Track[0].Sector[0].DataSize = 512) then
    begin
      Result := 'MGT SAM Coupe';
      if (StringInByteArray(Side[0].Track[0].Sector[0].Data,'BDOS',232)) then
        Result := Result + ' BDOS'
      else
        case (Side[0].Track[0].Sector[0].Data[210]) of
          0, 255: Result := Result + ' SAMDOS';
        else      Result := Result + ' MasterDOS';
      end;
    end;
end;

function TDSKDisk.DetectWeirdFormat: String;
begin
  // Alkatraz copy-protection
  if StringInByteArray(Side[0].Track[0].Sector[0].Data,ProtAlkatrazP3,320) then
    Result := 'Alkatraz +3 copy-protection (signed)';

  // Frontier copy-protection
  if (Side[0].Tracks > 10) and (Side[0].Track[1].Sectors > 0) then
     	if Side[0].Track[0].Sector[0].DataSize > 1 then
        if (StringInByteArray(Side[0].Track[1].Sector[0].Data,ProtFrontier,16)) then
      		Result := 'Frontier copy-protection'
        else
          if (Side[0].Track[9].Sectors = 1) then
            if (Side[0].Track[0].Sector[0].DataSize = 4096) then
              if (Side[0].Track[0].Sector[0].FDCStatus[1] = 0) then
                Result := 'Frontier copy-protection (probably, unsigned)';

  // Hexagon
	if (Side[0].Tracks > 1) and (Side[0].Track[0].Sectors = 10) then
   	if (Side[0].Track[0].Sector[8].DataSize = 512) then
     	if (StringInByteArray(Side[0].Track[0].Sector[8].Data,ProtHexagon,40)) then
       	Result := 'Hexagon copy-protection'
      else
        if (Side[0].Track[1].Sectors = 1) then
          if (Side[0].Track[1].Sector[0].DataSize = 6144) and
            (Side[0].Track[1].Sector[0].FDCStatus[1] = 32) and
            (Side[0].Track[1].Sector[0].FDCStatus[2] = 96) then
             Result := 'Hexagon copy-protection (probably, unsigned)';

  // Paul Owens
  if (Side[0].Track[0].Sectors = 9) then
    if (Side[0].Tracks > 10) then
      if (Side[0].Track[1].Sectors = 0) then
        if (StringInByteArray(Side[0].Track[0].Sector[2].Data,ProtPaulOwen,7)) then
          Result := 'Paul Owens copy-protection'
        else
          if (Side[0].Track[2].Sectors = 6) then
            if (Side[0].Track[2].Sector[0].DataSize = 256) then
              Result := 'Paul Owens copy-protection (probably, unsigned)';

  // Speedlock variants
  if (Side[0].Tracks > 1) and (Side[0].Track[0].Sectors > 0) then
  begin
    // Speedlock +3 1987
    if (StringInByteArray(Side[0].Track[0].Sector[0].Data,ProtSpeedlock1987P3,304)) then
      Result := 'Speedlock +3 1987 copy-protection (signed)'
    else
      if (Side[0].Track[0].Sectors = 9) and
        (Side[0].Track[1].Sectors = 5) and
        (Side[0].Track[1].Sector[0].DataSize = 1024) and
        (Side[0].Track[0].Sector[6].FDCStatus[2] = 64) and
        (Side[0].Track[0].Sector[8].FDCStatus[2] = 0) then
        Result := 'Speedlock +3 1987 copy-protection (probably, unsigned)';

    // Speedlock +3 1988
    if (StringInByteArray(Side[0].Track[0].Sector[0].Data,ProtSpeedlock1988P3,304)) then
      Result := 'Speedlock +3 1988 copy-protection (signed)'
    else
      if (Side[0].Track[0].Sectors = 9) and (Side[0].Tracks > 1) then
        if (Side[0].Track[1].Sectors = 5) and
          (Side[0].Track[1].Sector[0].DataSize = 1024) and
          (Side[0].Track[0].Sector[6].FDCStatus[2] = 64) and
          (Side[0].Track[0].Sector[8].FDCStatus[2] = 64) then
          Result := 'Speedlock +3 1988 copy-protection (probably, unsigned)';

    // Speedlock 1988
  	if (StringInByteArray(Side[0].Track[0].Sector[0].Data,ProtSpeedlock1988,129)) then
      Result := 'Speedlock 1988 copy-protection (signed)';

    // Speedlock 1989
   	if (StringInByteArray(Side[0].Track[0].Sector[0].Data,ProtSpeedlock1989,176)) then
      Result := 'Speedlock 1989 copy-protection'
    else
      if (Side[0].Track[0].Sectors > 7) and
        (Side[0].Tracks > 39) and
        (Side[0].Track[1].Sectors = 1) and
        (Side[0].Track[1].Sector[0].DataSize = 4096) and
        (Side[0].Track[40].Sectors = 1) and
        (Side[0].Track[40].Sector[0].DataSize = 6144) then
        Result := 'Speedlock 1989 copy-protection (probably, unsigned)';
  end;

  // Three Inch Loader
  if (StringInByteArray(Side[0].Track[0].Sector[0].Data,ProtThreeInchType1,41)) then
    Result := 'Three Inch Loader type 1 copy-protection (signed)';

 	if (StringInByteArray(Side[0].Track[0].Sector[0].Data,ProtThreeInchType2,41)) then
    Result := 'Three Inch Loader type 2 copy-protection (signed)';
end;

function TDSKDisk.BootableOn: String;
var
	Mod256: Integer;
begin
	Result :='None';
	if HasFirstSector then
     begin
      	if (Side[0].Track[0].Sector[0].Status = ssFormattedInUse)  then
          	begin
			  		Mod256 := Side[0].Track[0].Sector[0].GetModChecksum(256);
					case Mod256 of
						1:		Result := 'Amstrad PCW 9512';
						3:		Result := 'Spectrum +3';
						255:	Result := 'Amstrad PCW 8256';
		     			else
                    if (Side[0].Track[0].Sector[0].ID = 65) then
                    	Result := 'Amstrad CPC 664/6128'
                    else
                 		Result := SysUtils.Format('Unknown (%d)',[Mod256]);
		     		end;
          	end;
  			if ((Side[0].Track[0].Sector[0].FDCStatus[1] and 32) = 32) or
     			((Side[0].Track[0].Sector[0].FDCStatus[2] and 64) = 64) then
        		Result := Result + ' (Corrupt?)';
    	end;
end;

function TDSKDisk.HasFDCErrors: Boolean;
var
	SIdx, TIdx, EIdx: Integer;
begin
	Result := False;
	for SIdx := 0 to Sides-1 do
		for TIdx := 0 to Side[SIdx].Tracks-1 do
			for EIdx := 0 to Side[SIdx].Track[TIdx].Sectors-1 do
				with Side[SIdx].Track[TIdx].Sector[EIdx] do
           	if (FDCStatus[1] <> 0) or (FDCStatus[2] <> 0) then Result := True;
end;

function TDSKDisk.IsUniform(IgnoreEmptyTracks: Boolean): Boolean;
var
	SIdx, TIdx, EIdx: Integer;
  CheckTracks, CheckSectors, CheckSectorSize: Integer;
begin
	Result := True;
  if HasFirstSector then
  begin
		CheckTracks := Side[0].Tracks;
     CheckSectors := Side[0].Track[0].Sectors;
     CheckSectorSize := Side[0].Track[0].Sector[0].DataSize;
		for SIdx := 0 to Sides-1 do
  	begin
     	if CheckTracks <> Side[SIdx].Tracks then Result := False;
			for TIdx := 0 to Side[SIdx].Tracks-1 do
	      begin
	         if not ((Side[SIdx].Track[TIdx].Sectors = 0) and IgnoreEmptyTracks) then
					if CheckSectors <> Side[SIdx].Track[TIdx].Sectors then Result := False;
	     		for EIdx := 0 to Side[SIdx].Track[TIdx].Sectors-1 do
	        		if CheckSectorSize <> Side[SIdx].Track[TIdx].Sector[EIdx].DataSize then
	           		Result := False;
        end;
     end;
  end;
end;

function TDSKDisk.HasFirstSector: Boolean;
begin
	Result := False;
  if Sides>0 then
  	if Side[0].Tracks>0 then
     	if Side[0].Track[0].Sectors >0 then
        	Result := True;
end;


// Side																								  .
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

function TDSKSide.GetTracks: Byte;
begin
  if (Track = nil) then
     Result := 0
  else
     Result := High(Track) + 1;
end;

function TDSKSide.GetHighTrackCount: Byte;
begin
  Result := Tracks;
  while (not Track[Result-1].IsFormatted) and (Result > 1) do
    Result := Result - 1;
end;

procedure TDSKSide.SetTracks(NewTracks: Byte);
var
  OldTracks: Byte;
  Idx: Byte;
begin
  OldTracks := Tracks;
  if (OldTracks > NewTracks) then
  begin
     for Idx := NewTracks-1 To OldTracks do Track[Idx].Free;
     SetLength(Track,NewTracks);
  end;

  if (NewTracks > OldTracks) then
  begin
     SetLength(Track,NewTracks);
     for Idx := OldTracks to NewTracks-1 do Track[Idx] := TDSKTrack.Create(Self);
  end;
end;


// Track																							  .
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

function TDSKTrack.GetTrackSizeFromSectors: Word;
var
	Idx: Byte;
begin
	Result := 0;
  if (Sectors > 0) then
		for Idx := 0 to Sectors-1 do
  		Result := Result + Sector[Idx].DataSize;
end;

function TDSKTrack.GetIsFormatted: Boolean;
begin
  Result := (Sectors > 0);
end;

function TDSKTrack.GetSectors: Byte;
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

procedure TDSKTrack.SetSectors(NewSectors: Byte);
var
	OldSectors: Byte;
  Idx: Byte;
begin
  if (NewSectors = 0) then
  begin
    SetLength(Sector,0);
    exit;
  end;

  OldSectors := Sectors;

  if (OldSectors > NewSectors) then
  begin
     for Idx := NewSectors-1 to OldSectors do Sector[Idx].Free;
     SetLength(Sector,NewSectors);
  end;

  if (NewSectors > OldSectors) then
  begin
     SetLength(Sector,NewSectors);
     for Idx := OldSectors to NewSectors-1 do Sector[Idx] := TDSKSector.Create(Self);
  end;
end;

procedure TDSKTrack.Format(Formatter: TDSKFormatSpecification);
var
	EIdx: Byte;
begin
	Filler := Formatter.FillerByte;
  SectorSize := Formatter.SectorSize;
  Sectors := Formatter.SectorsPerTrack;
	GapLength := Formatter.GapFormat;
//  Size := Formatter.SectorsPerTrack * Formatter.SectorSize;

  case Formatter.Sides of
		dsSideSingle:
     	Logical := Track;
     dsSideDoubleAlternate:
     	Logical := (Track * Formatter.GetSidesCount) + Side;
     dsSideDoubleSuccessive:
     	Logical := (Side * Formatter.TracksPerSide) + Track;
     dsSideDoubleReverse:
     	if (Side=0) then
        	Logical := Track
        else
        	Logical := Formatter.TracksPerSide - Track;
  end;

  for EIdx := 0 To Sectors-1 do
	begin
		Sector[EIdx].Side := Side;
		Sector[EIdx].Track := Track;
		Sector[EIdx].Sector := EIdx;
    Sector[EIdx].FDCSize := Formatter.FDCSectorSize;
		Sector[EIdx].DataSize := Formatter.SectorSize;
    Sector[EIdx].ID := Formatter.GetSectorID(Side,Logical,Sector[EIdx].Sector);
		Sector[EIdx].FillSector(Formatter.FillerByte);
  end;
end;


// Sector																							  .
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
	FillByte: Integer;
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
function TDSKSector.GetFillByte: Integer;
var
  Idx: Integer;
begin
  Result := -2;
  if (DataSize > 0) then
		Result := Data[0];
  	for Idx := 0 to DataSize-1 do
     	if (Data[Idx] <> Data[0]) then
     	begin
        	Result := -1;
        	break;
     	end;
end;

procedure TDSKSector.ResetFDC;
var
	Idx: Integer;
begin
	for Idx := 1 To SizeOf(FDCStatus) do
  	if (FDCStatus[Idx] <> 0) then
  	begin
			FDCStatus[Idx] := 0;
     	IsChanged := True;
  	end;
end;

procedure TDSKSector.FillSector(Filler: Byte);
begin
	if (GetFillByte <> Filler) then
  begin
		FillChar(Data,DataSize,Filler);
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

function TDSKSector.GetModChecksum(ModValue: Integer): Integer;
var
	Idx: Integer;
begin
	Result := 0;
	for Idx := 0 to DataSize-1 do
		Result := (Result + Data[Idx]) Mod ModValue;
end;

function TDSKSector.FindText(Text: String; CaseSensitive: Boolean): Integer;
var
  Idx: Integer;
  SIdx: Integer;
  CharFound: Boolean;
  TestChar: Char;
begin
  if (DataSize = 0) then
  begin
    Result := -1;
    exit;
  end;

  SIdx := 1;
  for Idx := 0 To DataSize-1 do
  begin
    CharFound := false;
    TestChar := Char(Data[Idx]);

    if (CaseSensitive) and (TestChar = Text[SIdx]) then CharFound := true;
    if (not CaseSensitive) and (UpperCase(TestChar) = UpperCase(Text[SIdx])) then CharFound := true;

    if (CharFound) then
      inc(SIdx)
    else
      SIdx := 1;

    if (SIdx = Length(Text)+1) then
    begin
      Result := Idx;
      exit;
    end;
  end;

  Result := -1;
end;


// File system																					  .
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

function TDSKFileSystem.GetDiskFile(Offset: Integer): TDSKFile;
var
  DirBlock: TDSKSector;
  DirEnt: array[0..32] of Char;
  Idx: Integer;
begin
  Result := TDSKFile.Create(Self);
	for Idx := 0 to FParentDisk.Specification.DirectoryBlocks-1 do
  begin
	  DirBlock := FParentDisk.GetLogicalTrack(FParentDisk.Specification.FReservedTracks + Idx).Sector[0];
    with Result do
	  begin
	     Move(DirBlock.Data[Offset * DirEntSize],DirEnt,DirEntSize);
	     FileName := StrBlockClean(DirEnt,1,8);
	     Size := (Integer(DirEnt[12]) * 256) + Integer(DirEnt[13]);;
	     FileType := 'BASIC';
	  end;
  end;
end;


// File																								  .
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


// Disk specification																			  .
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

procedure TDSKSpecification.SetBlockSize(NewBlockSize: Integer);
begin
	if (NewBlockSize <> FBlockSize) then
  begin
  	FIsChanged := True;
     FBlockSize := NewBlockSize;
  end;
end;

procedure TDSKSpecification.SetChecksum(NewChecksum: Byte);
begin
	if (NewChecksum <> FChecksum) then
  begin
  	FIsChanged := True;
     FChecksum := NewChecksum;
  end;
end;

procedure TDSKSpecification.SetDirectoryBlocks(NewDirectoryBlocks: Byte);
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

procedure TDSKSpecification.SetGapFormat(NewGapFormat: Byte);
begin
	if (NewGapFormat <> FGapFormat) then
  begin
  	FIsChanged := True;
     FGapFormat := NewGapFormat;
  end;
end;

procedure TDSKSpecification.SetGapReadwrite(NewGapReadWrite: Byte);
begin
	if (NewGapReadWrite <> FGapReadWrite) then
  begin
  	FIsChanged := True;
     FGapReadWrite := NewGapReadWrite;
  end;
end;

procedure TDSKSpecification.SetReservedTracks(NewReservedTracks: Byte);
begin
	if (NewReservedTracks <> FReservedTracks) then
  begin
  	FIsChanged := True;
     FReservedTracks := NewReservedTracks;
  end;
end;

procedure TDSKSpecification.SetSectorsPerTrack(NewSectorsPerTrack: Byte);
begin
	if (NewSectorsPerTrack <> FSectorsPerTrack) then
  begin
  	FIsChanged := True;
     FSectorsPerTrack := NewSectorsPerTrack;
  end;
end;

procedure TDSKSpecification.SetFDCSectorSize(NewFDCSectorSize: Byte);
begin
	if (NewFDCSectorSize <> FFDCSectorSize) then
  begin
  	FIsChanged := True;
    FFDCSectorSize := NewFDCSectorSize;
  end;
end;

procedure TDSKSpecification.SetSectorSize(NewSectorSize: Word);
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

procedure TDSKSpecification.SetTracksPerSide(NewTracksPerSide: Byte);
begin
	if (NewTracksPerSide <> FTracksPerSide) then
  begin
  	FIsChanged := True;
     FTracksPerSide := NewTracksPerSide;
  end;
end;

function TDSKSpecification.Read: TDSKSpecFormat;
var
	Check: Extended;
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
        else	exit;
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

        Check := Power(2,(Data[4] + 7));
        if (Check >= 0) and (Check <= 255) then
        	FSectorSize := Round(Check)
        else
        	FSectorSize := 0;

 			FReservedTracks := Data[5];

			Check := Power(2,Data[6]) * 128;
        if (Check >=0) and (Check <= 255) then
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

function TDSKSpecification.Write: Boolean;
begin
	Result := False;
	if FParentDisk.HasFirstSector then
		with FParentDisk.Side[0].Track[0].Sector[0] do
  	begin
     	case FFormat of
				dsFormatPCW_SS: 		Data[0] := 0;
		    	dsFormatCPC_System:	Data[0] := 1;
	     		dsFormatCPC_Data:		Data[0] := 2;
	     		dsFormatPCW_DS:		Data[0] := 3;
			end;

        case FSide of
        	dsSideSingle:					Data[1] := 0;
        	dsSideDoubleAlternate:     Data[1] := 1;
        	dsSideDoubleSuccessive:    Data[1] := 2;
        end;
        if FTrack = dsTrackDouble then Data[1] := (Data[1] or $80);

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

// Disk format specifications																  .
function TDSKFormatSpecification.GetCapacityBytes: Integer;
begin
	Result := TracksPerSide * GetSidesCount * SectorsPerTrack * SectorSize;
end;

function TDSKFormatSpecification.GetDirectoryEntries: Integer;
begin
	Result := (DirBlocks * BlockSize) div 32;
end;

function TDSKFormatSpecification.GetUsableBytes: Integer;
var
	UsableTracks, UsableSectors, UsableBytes, WastedBytes: Integer;
begin
	UsableTracks := (TracksPerSide * GetSidesCount) - ResTracks;
	UsableSectors := (UsableTracks * SectorsPerTrack);
	UsableBytes := (UsableSectors * SectorSize) - (DirBlocks * BlockSize);
  WastedBytes := UsableBytes mod BlockSize;
	Result := UsableBytes - WastedBytes;
end;

function TDSKFormatSpecification.GetSidesCount: Byte;
begin
  if (Sides = dsSideSingle) then
  	Result := 1
  else
	   Result := 2;
end;

function TDSKFormatSpecification.GetSectorID(Side: Byte; LogicalTrack: Word; Sector: Byte): Byte;
var
	TrackSkewIdx: Integer;
begin
	BuildSectorIDs;

  if (SkewTrack = 0) and ((SkewSide = 0) or (Sides=dsSideSingle)) then
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
       if (Side=1) then
       	 TrackSkewIdx := ((TracksPerSide - LogicalTrack) * SkewTrack) + (SkewSide * Side);
     end;
  end;

  Result := FSectorIDs[(TrackSkewIdx + Sector) mod SectorsPerTrack];
end;

// Build sector ID table for interleave/skew
procedure TDSKFormatSpecification.BuildSectorIDs;
var
	EIdx, LastSectorID: Byte;
  SIdx: Integer;
begin
  SIdx := 0;
  LastSectorID := FirstSector;

	SetLength(FSectorIDs,SectorsPerTrack);
	for EIdx := 0 to SectorsPerTrack-1 do
  	FSectorIDs[EIdx] := 0;

	for EIdx := 0 to SectorsPerTrack-1 do
  begin
    while (FSectorIDs[(SIdx mod SectorsPerTrack)] <> 0) do
      if Interleave > 0 then
    	 	inc(SIdx)
      else
      begin
      	dec(SIdx);
			if SIdx<0 then SIdx := SectorsPerTrack + SIdx;
      end;

    FSectorIDs[(SIdx mod SectorsPerTrack)] := LastSectorID;
    inc(LastSectorID);
    SIdx := (SIdx + Interleave);
    if SIdx<0 then SIdx := SectorsPerTrack + SIdx;
  end;
end;

function GetFDCSectorSize(SectorSize: Word): Byte;
var
  Idx: Integer;
begin
  Result := High(FDCSectorSizes);
  for Idx := High(FDCSectorSizes) downto Low(FDCSectorSizes) do
    if (SectorSize <= FDCSectorSizes[Idx]) then
       Result := Idx;
end;

end.
