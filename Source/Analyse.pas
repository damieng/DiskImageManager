unit Analyse;

{
  Disk Image Manager -  Copyright 2002-2009 Envy Technologies Ltd.

  Disk operating file system
}

interface

uses
  DskImage, Utils,
  Classes, SysUtils;

type
  TDSKSpecification = class;
  TDSKXDPB = class;
  TDSKFileSystem = class;
  TDSKFile = class;

  // Specification (PCW/CPC+3 disk specification; abstract in future)
  TDSKSpecFormat = (dsFormatPCW_SS, dsFormatCPC_System, dsFormatCPC_Data, dsFormatPCW_DS, dsFormatInvalid);
  TDSKSpecSide = (dsSideSingle, dsSideDoubleAlternate, dsSideDoubleSuccessive, dsSideInvalid);
  TDSKSpecTrack = (dsTrackSingle, dsTrackMulti);
  TDSKSpecification = class(TObject)
  private
     FParentDisk: TDSKDisk;
     function GetDirectoryBlocks: Byte;
     function GetFormat: TDSKSpecFormat;
     function GetGapFormat: Byte;
     function GetGapReadWrite: Byte;
     function GetReservedTracks: Byte;
     function GetSectorsPerTrack: Byte;
     function GetSide: TDSKSpecSide;
     function GetTrack: TDSKSpecTrack;
     function GetTracksPerSide: Byte;
  public
     constructor Create(ParentDisk: TDSKDisk);
     destructor Destroy; override;
     property DirectoryBlocks: Byte read GetDirectoryBlocks;
     property Format: TDSKSpecFormat read GetFormat;
     property GapFormat: Byte read GetGapFormat;
     property GapReadWrite: Byte read GetGapReadWrite;
     property ReservedTracks: Byte read GetReservedTracks;
     property SectorsPerTrack: Byte read GetSectorsPerTrack;
     property Side: TDSKSpecSide read GetSide;
     property Track: TDSKSpecTrack read GetTrack;
     property TracksPerSide: Byte read GetTracksPerSide;
  end;

  // File system (PCW/CPC/+3 file system; abstract in future)
  TDSKFileSystem = class(TObject)
  private
     FParentDisk: TDSKDisk;
  public
     DiskFile: array of TDSKFile;
     constructor Create(ParentDisk: TDSKDisk);
     destructor Destroy; override;
     function GetDiskFile(Offset: Integer): TDSKFile;
  end;

  // File (+3 file type; abstract in future)
  TDSKFile = class(TObject)
  private
     FParentFileSystem: TDSKFileSystem;
  public
     Data: array of Byte;
     Deleted: Boolean;
     FileName: String;
     Size: Integer;
     FileType: String;
     constructor Create(ParentFileSystem: TDSKFileSystem);
     destructor Destroy; override;
  end;

const
  DSKSpecFormats: array[TDSKSpecFormat] of String =
  (
     'Amstrad PCW/+3 DD/SS/ST',
     'Amstrad CPC DD/SS/ST system',
     'Amstrad CPC DD/SS/ST data',
     'Amstrad PCW DD/DS/DT',
     'Invalid'
  );
  DSKSpecSides: array[TDSKSpecSide] of String =
  (
     'Single',
     'Double (Alternate)',
     'Double (Successive)',
     'Invalid'
  );
  DSKSpecTracks: array[TDSKSpecTrack] of String =
  (
     'Single',
     'Multi'
  );

implementation

// File system
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
const
  DirEntSize = 32; // +3 disk directory entry size
var
  DirBlock: TDSKSector;
  DirEnt: array[0..32] of Char;
begin
  Result := TDSKFile.Create(Self);
  DirBlock := FParentDisk.GetLogicalTrack(2).Sector[0];
  with Result do
  begin
     Move(DirBlock.Data[Offset * DirEntSize],DirEnt,DirEntSize);
     FileName := StrBlockClean(DirEnt,1,8);
     Size := (Integer(DirEnt[12]) * 256) + Integer(DirEnt[13]);;
     FileType := 'BASIC';
  end;
end;


// File
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


// Disk specification
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

function TDSKSpecification.GetDirectoryBlocks: Byte;
begin
  Result := FParentDisk.Side[0].Track[0].Sector[0].Data[7];
end;

function TDSKSpecification.GetFormat: TDSKSpecFormat;
begin
  if (Byte(FParentDisk.Side[0].Track[0].Sector[0].Data[0]) < Byte(Ord(dsFormatInvalid))) then
     Result := TDSKSpecFormat(FParentDisk.Side[0].Track[0].Sector[0].Data[0])
  else
     Result := dsFormatInvalid;
end;

function TDSKSpecification.GetGapFormat: Byte;
begin
  Result :=  FParentDisk.Side[0].Track[0].Sector[0].Data[8];
end;

function TDSKSpecification.GetGapReadWrite: Byte;
begin
  Result :=  FParentDisk.Side[0].Track[0].Sector[0].Data[9];
end;

function TDSKSpecification.GetSide: TDSKSpecSide;
begin
  Result := dsSideInvalid;
  case (FParentDisk.Side[0].Track[0].Sector[0].Data[1] and $3) of
     0: Result := dsSideSingle;
     1: Result := dsSideDoubleAlternate;
     2: Result := dsSideDoubleSuccessive;
  end;
end;

function TDSKSpecification.GetTrack: TDSKSpecTrack;
begin
  if ((FParentDisk.Side[0].Track[0].Sector[0].Data[1] and $80) = $80) then
     Result := dsTrackMulti
  else
     Result := dsTrackSingle;
end;

function TDSKSpecification.GetTracksPerSide: Byte;
begin
  Result :=  FParentDisk.Side[0].Track[0].Sector[0].Data[2];
end;

function TDSKSpecification.GetSectorsPerTrack: Byte;
begin
  Result :=  FParentDisk.Side[0].Track[0].Sector[0].Data[3];
end;

function TDSKSpecification.GetReservedTracks: Byte;
begin
  Result :=  FParentDisk.Side[0].Track[0].Sector[0].Data[5];
end;

end.
