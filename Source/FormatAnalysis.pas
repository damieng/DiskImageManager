unit FormatAnalysis;

{
  Disk Image Manager -  Copyright 2002-2009 Envy Technologies Ltd.

  Virtual disk format and protection analysis
}

interface

uses DskImage, SysUtils;

const
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
  ProtPMSLoader: String = 'P.M.S.LOADER [C]1987';

  // War In Middle Earth (CPC)
  ProtLaserLoad: String = 'Laser Load   By C.J.Pink For Consult Computer    Systems';

  // Bataille d'Angletter, La (CPC)
  ProtEREHerbulot: String = 'PROTECTION      Remi HERBULOT   ';

function AnalyseFormat(Disk: TDSKDisk): String;
function DetectUniformFormat(Disk: TDSKDisk): String;
function DetectProtection(Side: TDSKSide): String;
function DetectInterleave(Track: TDskTrack): String;

implementation

uses Utils;

function AnalyseFormat(Disk: TDSKDisk): String;
var
  Protection: String;
  Format: String;
begin
 if (not Disk.HasFirstSector) then
 	Result := 'Unformatted'
 else
 begin
   Result := '';
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

function DetectUniformFormat(Disk: TDSKDisk): String;
var
	FirstTrack: TDSKTrack;
begin
  FirstTrack := Disk.Side[0].Track[0];

	// Amstrad formats (9 sectors, 512 size, SS or DS)
  if (FirstTrack.Sectors = 9) and
    (Disk.Side[0].Track[0].Sector[0].DataSize = 512) then
    begin
      // TODO: Identify format by lowest sector ID
      case FirstTrack.LowSectorID of
				  1:    begin
		          		Result := 'Amstrad PCW/Spectrum +3';
             	    case Disk.Side[0].Track[0].Sector[0].GetModChecksum(256) of
						     	    1:	Result := 'Amstrad PCW 9512';
  							  	  3:	Result := 'Spectrum +3';
	  							  255:  Result := 'Amstrad PCW 8256';
							    end;
	                if (Disk.Sides = 1) then
                    Result := Result + ' CF2'
                 	else
                 	  Result := Result + ' CF2DD';
		        		end;
		     	65: 	Result := 'Amstrad CPC system';
	        193: 	Result := 'Amstrad CPC data';
       	end;

        // Add indicator where more tracks than normal
				if (Disk.Side[0].HighTrackCount > (Disk.Sides*40)) then Result := Result + ' (oversized)';
				if (Disk.Side[0].HighTrackCount < (Disk.Sides*40)) then Result := Result + ' (undersized)';
    end
    else
    begin
      // Other possible formats...
      case Disk.Side[0].Track[0].LowSectorID of
          1:  if (Disk.Side[0].Track[0].Sectors = 8) then Result := 'Amstrad CPC IBM';
         65:  Result := 'Amstrad CPC system custom (maybe)';
        193:  Result := 'Amstrad CPC data custom (maybe)';
      end;
    end;

    // Custom speccy formats (10 sectors, SS)
  	if (Disk.Sides = 1) and (Disk.Side[0].Track[0].Sectors = 10) then
    begin
    	// HiForm/Ultra208 (Chris Pile) + Ian Collier's skewed versions
      if (Disk.Side[0].Track[0].Sector[0].DataSize > 10) then
      begin
        if (Disk.Side[0].Track[0].Sector[0].Data[2] = 42) and
          (Disk.Side[0].Track[0].Sector[0].Data[8] = 12) then
        case Disk.Side[0].Track[0].Sector[0].Data[5] of
          0:	if (Disk.Side[0].Track[0].Sector[1].ID = 8) then
              		case Disk.Side[0].Track[1].Sector[0].ID of
                    7:		Result := 'Ultra 208/Ian Max';
                    8:		Result := 'Maybe Ultra 208 or Ian Max (skew lost)';
                    else	Result := 'Maybe Ultra 208 or Ian Max (custom skew)';
                  end
              else
                Result := 'Possibly Ultra 208 or Ian Max (interleave lost)';
          1:  if (Disk.Side[0].Track[0].Sector[1].ID = 8) then
              		case Disk.Side[0].Track[1].Sector[0].ID of
                    7:    Result := 'Ian High';
								    1:    Result := 'HiForm 203';
                    else 	Result := 'Maybe HiForm 203 or Ian High (custom skew)';
              		end;
          		else
                Result := 'Possibly HiForm or Ian High (interleave lost)';
        end;
       	// Supermat 192 (Ian Cull)
        if (Disk.Side[0].Track[0].Sector[0].Data[7] = 3) and
          (Disk.Side[0].Track[0].Sector[0].Data[9] = 23) and
        	(Disk.Side[0].Track[0].Sector[0].Data[2] = 40) then
        	  Result := 'Supermat 192/XCF2';
      end
    end;

    // Sam Coupe formats
    if (Disk.Sides = 2) and (Disk.Side[0].Track[0].Sectors = 10) and
      (Disk.Side[0].HighTrackCount = 80) and
      (Disk.Side[0].Track[0].LowSectorID = 1) and
      (Disk.Side[0].Track[0].Sector[0].DataSize = 512) then
    begin
      Result := 'MGT SAM Coupe';
      if (StrInByteArray(Disk.Side[0].Track[0].Sector[0].Data,'BDOS',232)) then
        Result := Result + ' BDOS'
      else
        case (Disk.Side[0].Track[0].Sector[0].Data[210]) of
          0, 255: Result := Result + ' SAMDOS';
        else      Result := Result + ' MasterDOS';
      end;
    end;
end;

// We have two techniques for copy-protection detection - ASCII signatures
// and structural characteristics.
function DetectProtection(Side: TDSKSide): String;
var
	TIdx, SIdx: Integer;
  Sector: TDSKSector;
begin
  // Alkatraz copy-protection
  if StrInByteArray(Side.Track[0].Sector[0].Data,ProtAlkatrazP3,320) then
    Result := 'Alkatraz +3 copy-protection (signed)';

  // Frontier copy-protection
  if (Side.Tracks > 10) and (Side.Track[1].Sectors > 0) then
     	if Side.Track[0].Sector[0].DataSize > 1 then
        if (StrInByteArray(Side.Track[1].Sector[0].Data,ProtFrontier,16)) then
      		Result := 'Frontier copy-protection (signed)'
        else
          if (Side.Track[9].Sectors = 1) then
            if (Side.Track[0].Sector[0].DataSize = 4096) then
              if (Side.Track[0].Sector[0].FDCStatus[1] = 0) then
                Result := 'Frontier copy-protection (probably, unsigned)';

  // Hexagon
  if (Side.Tracks > 1) and (Side.Track[1].Sectors = 1) then
  	if (Side.Track[1].Sector[0].DataSize = 6144) and
    	(Side.Track[1].Sector[0].FDCStatus[1] = 32) and
      (Side.Track[1].Sector[0].FDCStatus[2] = 96) then
      	Result := 'Hexagon copy-protection (probably, unsigned)';

	if (Side.Tracks > 1) and (Side.Track[0].Sectors = 10) then
   	if (Side.Track[0].Sector[8].DataSize = 512) then
     	if (StrInByteArray(Side.Track[0].Sector[8].Data,ProtHexagon,40)) then
       	Result := 'Hexagon copy-protection (signed)';

  // Paul Owens
  if (Side.Track[0].Sectors = 9) then
    if (Side.Tracks > 10) then
      if (Side.Track[1].Sectors = 0) then
        if (StrInByteArray(Side.Track[0].Sector[2].Data,ProtPaulOwen,7)) then
          Result := 'Paul Owens copy-protection (signed)'
        else
          if (Side.Track[2].Sectors = 6) then
            if (Side.Track[2].Sector[0].DataSize = 256) then
              Result := 'Paul Owens copy-protection (probably, unsigned)';

  // Speedlock variants
  if (Side.Tracks > 1) and (Side.Track[0].Sectors > 0) then
  begin
    // Speedlock +3 1987
    if (StrInByteArray(Side.Track[0].Sector[0].Data,ProtSpeedlock1987P3,304)) or
    	(StrInByteArray(Side.Track[0].Sector[0].Data,ProtSpeedlock1987P3,301)) then
      Result := 'Speedlock +3 1987 copy-protection (signed)'
    else
      if (Side.Track[0].Sectors = 9) and
        (Side.Track[1].Sectors = 5) and
        (Side.Track[1].Sector[0].DataSize = 1024) and
        (Side.Track[0].Sector[6].FDCStatus[2] = 64) and
        (Side.Track[0].Sector[8].FDCStatus[2] = 0) then
        Result := 'Speedlock +3 1987 copy-protection (probably, unsigned)';

    // Speedlock +3 1988
    if (StrInByteArray(Side.Track[0].Sector[0].Data,ProtSpeedlock1988P3,304)) then
      Result := 'Speedlock +3 1988 copy-protection (signed)'
    else
      if (Side.Track[0].Sectors = 9) and (Side.Tracks > 1) then
        if (Side.Track[1].Sectors = 5) and
          (Side.Track[1].Sector[0].DataSize = 1024) and
          (Side.Track[0].Sector[6].FDCStatus[2] = 64) and
          (Side.Track[0].Sector[8].FDCStatus[2] = 64) then
          Result := 'Speedlock +3 1988 copy-protection (probably, unsigned)';

    // Speedlock 1988
  	if (StrInByteArray(Side.Track[0].Sector[0].Data,ProtSpeedlock1988,129)) then
      Result := 'Speedlock 1988 copy-protection (signed)';

    // Speedlock 1989
   	if (StrInByteArray(Side.Track[0].Sector[0].Data,ProtSpeedlock1989,176)) then
      Result := 'Speedlock 1989 copy-protection (signed)'
    else
      if (Side.Track[0].Sectors > 7) and
        (Side.Tracks > 40) and
        (Side.Track[1].Sectors = 1) and
        (Side.Track[1].Sector[0].ID = 193) and
        (Side.Track[1].Sector[0].FDCStatus[1] = 32) then
        Result := 'Speedlock 1989 copy-protection (probably, unsigned)';
  end;

  // Three Inch Loader
  if (StrInByteArray(Side.Track[0].Sector[0].Data,ProtThreeInchType1,41)) then
    Result := 'Three Inch Loader type 1 copy-protection (signed)';

 	if (StrInByteArray(Side.Track[0].Sector[0].Data,ProtThreeInchType2,41)) then
    Result := 'Three Inch Loader type 2 copy-protection (signed)';

  // Laser loader
  if (Side.Track[0].Sectors > 2) and
  	(StrInByteArray(Side.Track[0].Sector[2].Data,ProtLaserLoad,3)) then
    Result := 'Laser Load by C.J. Pink (signed)';

  // P.M.S.Loader
  if (StrInByteArray(Side.Track[0].Sector[0].Data,ProtPMSLoader,191)) then
     Result := 'P.M.S. Loader 1987 (signed)'
  else
      if ((Side.Tracks > 2) and Side.Track[0].IsFormatted) then
         if (not Side.Track[1].IsFormatted and Side.Track[2].IsFormatted) then
            Result := 'P.M.S. Loader 1987 (probably, unsigned)';

  if (Side.Track[0].Sectors > 4) then
     if (StrInByteArray(Side.Track[0].Sector[5].Data, ProtEREHerbulot, 0)) then
        Result := 'ERE/Remi HERBULOT (signed)';
     // TODO: Some heuristics if we find more instances of this

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
      Result := Format('Players (maybe, super-sized track %d)',[TIdx]);
    end;

  // Unknown copy protection
  if (Result = '') and (not side.ParentDisk.IsUniform(true)) and
  	(side.ParentDisk.HasFDCErrors) then
    begin
      Result := 'Unknown copy protection';
    end;
end;


function DetectInterleave(Track: TDskTrack): String;
var
	LowIdx, NextLowIdx, LowID, NextLowID, SIdx, ExpectedID: Byte;
  Interleave: Integer;
begin
	LowIdx := 255;
  NextLowIdx := 255;

  if (Track.Sectors < 3) then
  begin
  	Result :=' Too few sectors';
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
      Result := Format('Expected %d but sector %d ID was %d not %d',
        [Interleave, SIdx, Track.Sector[SIdx].ID, ExpectedID]);
      Exit;
    end;

  Result := Format('%d', [Interleave]);
end;

end.
