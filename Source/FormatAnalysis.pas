unit FormatAnalysis;

{
  Disk Image Manager -  Copyright 2002-2009 Envy Technologies Ltd.

  Virtual disk format and protection analysis
}

interface

uses DskImage, SysUtils;

function AnalyseFormat(Disk: TDSKDisk): string;
function DetectUniformFormat(Disk: TDSKDisk): string;
function DetectProtection(Side: TDSKSide): string;
function DetectInterleave(Track: TDskTrack): string;

implementation

uses Utils;

function AnalyseFormat(Disk: TDSKDisk): string;
var
  Protection: string;
  Format: string;
begin
  if Disk.GetFirstSector = nil then
    Result := 'Unformatted'
  else
  begin
    Result := '';
    Format := '';
    Protection := DetectProtection(Disk.Side[0]);
    if (Disk.IsUniform(True)) then
      Format := DetectUniformFormat(Disk);
    if (Format <> '') then
      Result := Format;
    if (Protection <> '') then
      Result := Trim(Result + ' ' + Protection);
    if (Result = '') then
      Result := 'Unknown';
  end;
end;

const
  EINSTEIN_SIGNATURE: array[0..5] of byte = ($00, $E1, $00, $FB, $00, $FA);

function DetectUniformFormat(Disk: TDSKDisk): string;
var
  FirstTrack: TDSKTrack;
  FirstSector: TDSKSector;
begin
  FirstTrack := Disk.GetLogicalTrack(0);
  FirstSector := FirstTrack.GetFirstLogicalSector();
  Result := '';

  // Amstrad formats (9 sectors, 512 size, SS or DS)
  if (FirstTrack.Sectors = 9) and (FirstSector.DataSize = 512) then
  begin
    // TODO: Identify format by lowest sector ID
    case FirstTrack.LowSectorID of
      1: begin
        Result := 'Amstrad PCW/Spectrum +3';
        case FirstSector.GetModChecksum(256) of
          1: Result := 'Amstrad PCW 9512';
          3: Result := 'Spectrum +3';
          255: Result := 'Amstrad PCW 8256';
        end;
        if (Disk.Sides = 1) then
          Result := Result + ' CF2'
        else
          Result := Result + ' CF2DD';
      end;
      65: Result := 'Amstrad CPC system';
      193: Result := 'Amstrad CPC data';
    end;

    // Add indicator where more tracks than normal
    if (Disk.Side[0].HighTrackCount > (Disk.Sides * 40)) then Result := Result + ' (oversized)';
    if (Disk.Side[0].HighTrackCount < (Disk.Sides * 40)) then Result := Result + ' (undersized)';
  end
  else
  begin
    // Other possible formats...
    case FirstTrack.LowSectorID of
      1: if FirstTrack.Sectors = 8 then Result := 'Amstrad CPC IBM';
      65: Result := 'Amstrad CPC system custom (maybe)';
      193: Result := 'Amstrad CPC data custom (maybe)';
    end;
  end;

  // Einstein format
  if FirstSector.DataSize > 10 then
    if CompareMem(@FirstSector.Data, @EINSTEIN_SIGNATURE, Length(EINSTEIN_SIGNATURE)) then
      Result := 'Einstein';

  // Custom speccy formats (10 sectors, SS)
  if (Disk.Sides = 1) and (FirstTrack.Sectors = 10) then
  begin
    // HiForm/Ultra208 (Chris Pile) + Ian Collier's skewed versions
    if (FirstSector.DataSize > 10) then
    begin
      if (FirstSector.Data[2] = 42) and (FirstSector.Data[8] = 12) then
        case FirstSector.Data[5] of
          0: if (FirstTrack.Sector[1].ID = 8) then
              case Disk.Side[0].Track[1].Sector[0].ID of
                7: Result := 'Ultra 208/Ian Max';
                8: Result := 'Maybe Ultra 208 or Ian Max (skew lost)';
                else
                  Result := 'Maybe Ultra 208 or Ian Max (custom skew)';
              end
            else
              Result := 'Possibly Ultra 208 or Ian Max (interleave lost)';
          1: if (FirstTrack.Sector[1].ID = 8) then
              case Disk.Side[0].Track[1].Sector[0].ID of
                7: Result := 'Ian High';
                1: Result := 'HiForm 203';
                else
                  Result := 'Maybe HiForm 203 or Ian High (custom skew)';
              end;
          else
            Result := 'Possibly HiForm or Ian High (interleave lost)';
        end;
      // Supermat 192 (Ian Cull)
      if (FirstSector.Data[7] = 3) and (FirstSector.Data[9] = 23) and (FirstSector.Data[2] = 40) then
        Result := 'Supermat 192/XCF2';
    end;
  end;

  // Sam Coupe formats
  if (Disk.Sides = 2) and (FirstTrack.Sectors = 10) and (Disk.Side[0].HighTrackCount = 80) and
    (FirstTrack.LowSectorID = 1) and (FirstSector.DataSize = 512) then
  begin
    Result := 'MGT SAM Coupe';
    if StrInByteArray(FirstSector.Data, 'BDOS', 232) then
      Result := Result + ' BDOS'
    else
      case FirstSector.Data[210] of
        0, 255: Result := Result + ' SAMDOS';
        else
          Result := Result + ' MasterDOS';
      end;
  end;
end;

// We have two techniques for copy-protection detection - ASCII signatures
// and structural characteristics.
function DetectProtection(Side: TDSKSide): string;
var
  TIdx, SIdx, Offset: integer;
  Sector: TDSKSector;
begin
  Result := '';
  if Side.Tracks < 2 then exit;

  // Alkatraz copy-protection
  Offset := StrBufPos(Side.Track[0].Sector[0].Data, ' THE ALKATRAZ PROTECTION SYSTEM   (C) 1987  Appleby Associates');
  if Offset > -1 then
  begin
    Result := 'Alkatraz +3 (signed at ' + StrInt(Offset) + ')';
    exit;
  end;

  // Frontier copy-protection
  if (Side.Tracks > 10) and (Side.Track[1].Sectors > 0) and (Side.Track[0].Sector[0].DataSize > 1) then
  begin
    Offset := StrBufPos(Side.Track[1].Sector[0].Data, 'W DISK PROTECTION SYSTEM. (C) 1990 BY NEW FRONTIER SOFT.');
    if Offset > -1 then
    begin
      Result := 'Frontier (signed at ' + StrInt(Offset) + ')';
      exit;
    end;

    if (Side.Track[9].Sectors = 1) and (Side.Track[0].Sector[0].DataSize = 4096) and
      (Side.Track[0].Sector[0].FDCStatus[1] = 0) then
      Result := 'Frontier (probably, unsigned)';
  end;

  // Hexagon
  if (Side.Track[0].Sectors = 10) and (Side.Track[0].Sector[8].DataSize = 512) then
  begin
    Offset := StrBufPos(Side.Track[0].Sector[8].Data, 'GON DISK PROTECTION c 1989 A.R.P');
    if Offset > -1 then
    begin
      Result := 'Hexagon (signed at ' + StrInt(Offset) + ')';
      exit;
    end;

    if (Side.Track[1].Sectors = 1) and (Side.Track[1].Sector[0].FDCSize = 6) and
      (Side.Track[1].Sector[0].FDCStatus[1] = 32) and (Side.Track[1].Sector[0].FDCStatus[2] = 96) then
      Result := 'Hexagon (probably, unsigned)';
  end;

  // Paul Owens
  if (Side.Track[0].Sectors = 9) and (Side.Tracks > 10) and (Side.Track[1].Sectors = 0) then
  begin
    Offset := StrBufPos(Side.Track[0].Sector[2].Data, 'PAUL OWENS' + #128 + 'PROTECTION SYS');
    if Offset > -1 then
    begin
      Result := 'Paul Owens (signed at ' + StrInt(Offset) + ')';
      exit;
    end
    else
    if (Side.Track[2].Sectors = 6) and (Side.Track[2].Sector[0].DataSize = 256) then
      Result := 'Paul Owens (probably, unsigned)';
  end;

  // Speedlock +3 1987
  Offset := StrBufPos(Side.Track[0].Sector[0].Data, 'SPEEDLOCK +3 DISC PROTECTION SYSTEM COPYRIGHT 1987 SPEEDLOCK ASSOCIATES');
  if Offset > -1 then
  begin
    Result := 'Speedlock +3 1987 (signed at ' + StrInt(Offset) + ')';
    exit;
  end;

  if (Side.Track[0].Sectors = 9) and (Side.Track[1].Sectors = 5) and (Side.Track[1].Sector[0].DataSize = 1024) and
    (Side.Track[0].Sector[6].FDCStatus[2] = 64) and (Side.Track[0].Sector[8].FDCStatus[2] = 0) then
    Result := 'Speedlock +3 1987 (probably, unsigned)';

  // Speedlock +3 1988
  Offset := StrBufPos(Side.Track[0].Sector[0].Data, 'SPEEDLOCK +3 DISC PROTECTION SYSTEM COPYRIGHT 1988 SPEEDLOCK ASSOCIATES');
  if Offset > -1 then
  begin
    Result := 'Speedlock +3 1988 (signed at ' + StrInt(Offset) + ')';
    exit;
  end;
  if (Side.Track[0].Sectors = 9) and (Side.Track[1].Sectors = 5) and (Side.Track[1].Sector[0].DataSize = 1024) and
    (Side.Track[0].Sector[6].FDCStatus[2] = 64) and (Side.Track[0].Sector[8].FDCStatus[2] = 64) then
    Result := 'Speedlock +3 1988 (probably, unsigned)';

  // Speedlock 1988
  Offset := StrBufPos(Side.Track[0].Sector[0].Data, 'SPEEDLOCK DISC PROTECTION SYSTEMS (C) 1988 SPEEDLOCK ASSOCIATES');
  if Offset > -1 then
  begin
    Result := 'Speedlock 1988 (signed at ' + StrInt(Offset) + ')';
    exit;
  end;

  // Speedlock 1989
  Offset := StrBufPos(Side.Track[0].Sector[0].Data, 'SPEEDLOCK DISC PROTECTION SYSTEMS (C) 1989 SPEEDLOCK ASSOCIATES');
  if Offset > -1 then
  begin
    Result := 'Speedlock 1989 (signed at ' + StrInt(Offset) + ')';
    exit;
  end;
  if (Side.Track[0].Sectors > 7) and (Side.Tracks > 40) and (Side.Track[1].Sectors = 1) and
    (Side.Track[1].Sector[0].ID = 193) and (Side.Track[1].Sector[0].FDCStatus[1] = 32) then
    Result := 'Speedlock 1989 (probably, unsigned)';

  // Three Inch Loader
  Offset := StrBufPos(Side.Track[0].Sector[0].Data,
    '***Loader Copyright Three Inch Software 1988, All Rights Reserved. Three Inch Software, 73 Surbiton Road, Kingston upon Thames, KT1 2HG***');
  if Offset > -1 then
  begin
    Result := 'Three Inch Loader type 1 (signed at ' + StrInt(Offset) + ')';
    exit;
  end;

  if Side.Track[0].Sectors > 7 then
  begin
    Offset := StrBufPos(Side.Track[0].Sector[7].Data,
      '***Loader Copyright Three Inch Software 1988, All Rights Reserved. Three Inch Software, 73 Surbiton Road, Kingston upon Thames, KT1 2HG***');
    if Offset > -1 then
    begin
      Result := 'Three Inch Loader type 1-0-7 (signed at ' + StrInt(Offset) + ')';
      exit;
    end;
  end;

  Offset := StrBufPos(Side.Track[0].Sector[0].Data,
    '***Loader Copyright Three Inch Software 1988, All Rights Reserved. 01-546 2754');
  if Offset > -1 then
  begin
    Result := 'Three Inch Loader type 2 (signed at ' + StrInt(Offset) + ')';
    exit;
  end;

  // Microprose Soccer
  if (Side.Tracks > 1) and (Side.Track[1].Sectors > 4) then
  begin
    Offset := StrBufPos(Side.Track[1].Sector[4].Data, 'Loader ' + #127 + '1988 Three Inch Software');
    if Offset > -1 then
    begin
      Result := 'Three Inch Loader type 3-1-4 (signed at ' + StrInt(Offset) + ')';
      exit;
    end;
  end;

  // Laser loader (War in Middle Earth CPC)
  if (Side.Track[0].Sectors > 2) then
  begin
    Offset := StrBufPos(Side.Track[0].Sector[2].Data, 'Laser Load   By C.J.Pink For Consult Computer    Systems');
    if Offset > -1 then
      Result := 'Laser Load by C.J. Pink (signed at ' + StrInt(Offset) + ')';
  end;

  // P.M.S.Loader
  Offset := StrBufPos(Side.Track[0].Sector[0].Data, 'P.M.S.LOADER [C]1987');
  if Offset > -1 then
  begin
    Result := 'P.M.S. Loader 1987 (signed at ' + StrInt(Offset) + ')';
    exit;
  end;
  if ((Side.Tracks > 2) and Side.Track[0].IsFormatted) and (not Side.Track[1].IsFormatted and Side.Track[2].IsFormatted) then
    Result := 'P.M.S. Loader 1987 (probably, unsigned)';

  /// ERE/Remi HERBULOT (La Bataille D'Angleterre CPC)
  if (Side.Track[0].Sectors > 4) then
  begin
    Offset := StrBufPos(Side.Track[0].Sector[5].Data, 'PROTECTION      Remi HERBULOT   ');
    if Offset > 0 then
    begin
      Result := 'ERE/Remi HERBULOT (signed at ' + StrInt(Offset) + ')';
      exit;
    end;
  end;

  // Players?
  for TIdx := 0 to Side.Tracks - 1 do
    if (Side.Track[TIdx].Sectors = 16) then
    begin
      for SIdx := 0 to Side.Track[TIdx].Sectors - 1 do
      begin
        Sector := Side.Track[TIdx].Sector[SIdx];
        if (Sector.ID <> SIdx) or (Sector.FDCSize <> SIdx) then
          break;
      end;
      Result := Format('Players (maybe, super-sized %d byte track %d)', [Side.GetLargestTrackSize(), TIdx]);
    end;

  // Unknown copy protection
  if (Result = '') and (not side.ParentDisk.IsUniform(True)) and (side.ParentDisk.HasFDCErrors) then
  begin
    Result := 'Unknown copy protection';
  end;
end;


function DetectInterleave(Track: TDskTrack): string;
var
  LowIdx, NextLowIdx, LowID, NextLowID, SIdx, ExpectedID: byte;
  Interleave: integer;
begin
  LowIdx := 255;
  NextLowIdx := 255;
  Interleave := 0;

  if (Track.Sectors < 3) then
  begin
    Result := ' Too few sectors';
    Exit;
  end;

  // Scan through the track and figure out the lowest two ID's
  LowID := 255;
  NextLowID := 255;
  for SIdx := 0 to Track.Sectors - 1 do
    if (Track.Sector[SIdx].ID < LowID) then
    begin
      NextLowID := LowID;
      NextLowIDX := LowIdx;
      LowID := Track.Sector[SIdx].ID;
      LowIdx := SIdx;
    end
    else
    if (Track.Sector[SIdx].ID < NextLowID) then
    begin
      NextLowID := Track.Sector[SIdx].ID;
      NextLowIdx := SIdx;
    end;

  // Make sure the ID's are sequential
  if (LowIdx < 255) and (NextLowIdx < 255) and (NextLowID = LowID - 1) then
  begin
    // Positive skew (or negative less than sector-count)
    if (LowIdx < NextLowIdx) then
      Interleave := NextLowIdx - LowIdx;
    // Negative skew (or positive greater than sector-count)
    if (LowIdx > NextLowIdx) then
      Interleave := LowIdx - NextLowIdx;
  end
  else
    Result := 'Non-sequential IDs';

  // Confirm the interleave for every sector
  ExpectedID := Track.Sector[0].ID;
  for SIdx := 0 to Track.Sectors - 1 do
    if Track.Sector[SIdx].ID <> ExpectedID then
    begin
      Result := Format('Expected %d but sector %d ID was %d not %d', [Interleave, SIdx, Track.Sector[SIdx].ID, ExpectedID]);
      Exit;
    end;

  Result := Format('%d', [Interleave]);
end;

end.
