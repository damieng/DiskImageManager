unit DSKFormat;

interface

const
	// DSK file strings
  DiskInfoStandard = 'MV - CPCEMU Disk-File' + #13 + #10 + 'Disk-Info' + #13 + #10;
  DiskInfoExtended = 'EXTENDED CPC DSK File' + #13 + #10 + 'Disk-Info' + #13 + #10;
  DiskInfoTrack = 'Track-Info' + #13 + #10;
  DiskSectorOffsetBlock = 'Offset-Info' + #13 + #10;
  CreatorSig = 'SPIN Disk Man';
  CreatorDU54 = 'Disk Image (DU54)' + #13 + #10;

  MaxTracks = 204;

type
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

implementation

end.
