unit AmstradScreen;

{$MODE Delphi}

{
  Disk Image Manager - Amstrad CPC screen (raw SCREEN RAM) decoder

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  Graphics, Classes, SysUtils, Utils;

const
  CPCScreenSize = 16384;       // Standard CPC screen RAM dump
  CPCLines = 200;              // Visible scanlines
  CPCBytesPerLine = 80;        // Bytes per scanline for a standard screen
  CPCVisibleBytes = 16000;     // Bytes actually displayed (200 * 80)
  CPCScreenMaxBytes = 17408;   // Allow a header/trailer (up to 17 x 1K blocks)
  CPCDisplayWidth = 640;       // Normalised display width (all modes)
  CPCDisplayHeight = 400;      // Normalised display height (200 lines doubled)

type
  TAmstradMode = (amMode0, amMode1, amMode2);

  TAmstradScreen = class
  public
    class function IsValidScreenSize(Size: integer): boolean;
    // True if Data begins with an "MJH" Advanced OCP Art Studio compressed block.
    class function IsMJHCompressed(const Data: array of byte): boolean;
    // Decompress concatenated "MJH" RLE blocks into raw screen bytes. Returns an
    // empty array if Data is not a valid MJH stream.
    class function DecompressMJH(const Data: array of byte): TDiskByteArray;
    // Return displayable screen bytes from a file's data, expanding MJH
    // compression if present. Returns an empty array unless the result is a
    // valid full-screen size (so .WIN window clips and non-screens are rejected).
    class function GetScreenData(const Data: array of byte): TDiskByteArray;
    // Guess the intended graphics mode by looking for the vertical-line/banding
    // artifacts that appear when screen data is decoded at too high a resolution.
    class function GuessMode(const Data: array of byte; Offset: integer = 0): TAmstradMode;
    class procedure RenderToBitmap(const Data: array of byte; Mode: TAmstradMode;
      Bitmap: TBitmap; Zoom: integer; Offset: integer = 0);
  end;

implementation

type
  TCPCColor = record
    R, G, B: byte;
  end;

const
  // The 27 CPC hardware colours indexed by firmware colour number.
  // Each RGB gun has three levels: $00 (off), $80 (half), $FF (full).
  HardwarePalette: array[0..26] of TCPCColor = (
    (R: $00; G: $00; B: $00),  //  0 Black
    (R: $00; G: $00; B: $80),  //  1 Blue
    (R: $00; G: $00; B: $FF),  //  2 Bright Blue
    (R: $80; G: $00; B: $00),  //  3 Red
    (R: $80; G: $00; B: $80),  //  4 Magenta
    (R: $80; G: $00; B: $FF),  //  5 Mauve
    (R: $FF; G: $00; B: $00),  //  6 Bright Red
    (R: $FF; G: $00; B: $80),  //  7 Purple
    (R: $FF; G: $00; B: $FF),  //  8 Bright Magenta
    (R: $00; G: $80; B: $00),  //  9 Green
    (R: $00; G: $80; B: $80),  // 10 Cyan
    (R: $00; G: $80; B: $FF),  // 11 Sky Blue
    (R: $80; G: $80; B: $00),  // 12 Yellow
    (R: $80; G: $80; B: $80),  // 13 White
    (R: $80; G: $80; B: $FF),  // 14 Pastel Blue
    (R: $FF; G: $80; B: $00),  // 15 Orange
    (R: $FF; G: $80; B: $80),  // 16 Pink
    (R: $FF; G: $80; B: $FF),  // 17 Pastel Magenta
    (R: $00; G: $FF; B: $00),  // 18 Bright Green
    (R: $00; G: $FF; B: $80),  // 19 Sea Green
    (R: $00; G: $FF; B: $FF),  // 20 Bright Cyan
    (R: $80; G: $FF; B: $00),  // 21 Lime
    (R: $80; G: $FF; B: $80),  // 22 Pastel Green
    (R: $80; G: $FF; B: $FF),  // 23 Pastel Cyan
    (R: $FF; G: $FF; B: $00),  // 24 Bright Yellow
    (R: $FF; G: $FF; B: $80),  // 25 Pastel Yellow
    (R: $FF; G: $FF; B: $FF)   // 26 Bright White
  );

  // Firmware default ink table: pen 0-15 -> hardware colour number.
  // (Pens 14/15 flash on real hardware; the first colour is shown here.)
  DefaultInk: array[0..15] of byte = (
    1, 24, 20, 6, 26, 0, 2, 8, 10, 12, 14, 16, 18, 22, 1, 11
  );

// Pixels across a line and pixels packed per byte for each mode.
procedure ModeMetrics(Mode: TAmstradMode; out PixelsPerLine, PixelsPerByte: integer);
begin
  case Mode of
    amMode0: begin PixelsPerLine := 160; PixelsPerByte := 2; end;
    amMode1: begin PixelsPerLine := 320; PixelsPerByte := 4; end;
  else
    begin PixelsPerLine := 640; PixelsPerByte := 8; end;
  end;
end;

// Byte offset of the first byte of scanline Y, accounting for the CPC screen
// interleave: 8 scanlines per character row, the rows 2048 bytes apart.
function ScreenLineBase(Y: integer): integer;
begin
  Result := (Y mod 8) * 2048 + (Y div 8) * CPCBytesPerLine;
end;

// Decode the logical pen (0..15) of pixel Pixel within byte AByte for the mode.
function DecodePen(AByte: byte; Pixel: integer; Mode: TAmstradMode): integer;
begin
  case Mode of
    amMode0:
      if Pixel = 0 then
        Result := ((AByte shr 7) and 1) or (((AByte shr 3) and 1) shl 1) or
                  (((AByte shr 5) and 1) shl 2) or (((AByte shr 1) and 1) shl 3)
      else
        Result := ((AByte shr 6) and 1) or (((AByte shr 2) and 1) shl 1) or
                  (((AByte shr 4) and 1) shl 2) or ((AByte and 1) shl 3);
    amMode1:
      Result := ((AByte shr (7 - Pixel)) and 1) or
                (((AByte shr (3 - Pixel)) and 1) shl 1);
  else // amMode2
    Result := (AByte shr (7 - Pixel)) and 1;
  end;
end;

// Decode one scanline into Row (length PixelsPerLine) for the given mode.
procedure DecodeRow(const Data: array of byte; Mode: TAmstradMode;
  Offset, Y, PixelsPerByte: integer; var Row: array of integer);
var
  Col, P, Idx, DataLen, LineBase: integer;
  B: byte;
begin
  DataLen := Length(Data);
  LineBase := ScreenLineBase(Y);
  for Col := 0 to CPCBytesPerLine - 1 do
  begin
    Idx := Offset + LineBase + Col;
    if (Idx >= 0) and (Idx < DataLen) then
      B := Data[Idx]
    else
      B := 0;
    for P := 0 to PixelsPerByte - 1 do
      Row[Col * PixelsPerByte + P] := DecodePen(B, P, Mode);
  end;
end;

class function TAmstradScreen.IsValidScreenSize(Size: integer): boolean;
begin
  // Accept anything from a bare visible image up to a screen with a small
  // header/trailer (some .SCR files carry a few extra bytes and span 17 blocks)
  Result := (Size >= CPCVisibleBytes) and (Size <= CPCScreenMaxBytes);
end;

class function TAmstradScreen.IsMJHCompressed(const Data: array of byte): boolean;
begin
  Result := (Length(Data) >= 5) and (Data[0] = Ord('M')) and
            (Data[1] = Ord('J')) and (Data[2] = Ord('H'));
end;

class function TAmstradScreen.DecompressMJH(const Data: array of byte): TDiskByteArray;
const
  MJHMarker = $01;
var
  Pos, Len, OutLen, Produced, Count, BlockLen, I: integer;
  Value: byte;
begin
  Result := nil;
  Len := Length(Data);
  Pos := 0;
  OutLen := 0;

  // The file is one or more concatenated "MJH" blocks (each a quarter screen).
  while (Pos + 5 <= Len) and (Data[Pos] = Ord('M')) and
        (Data[Pos + 1] = Ord('J')) and (Data[Pos + 2] = Ord('H')) do
  begin
    BlockLen := Data[Pos + 3] or (Data[Pos + 4] shl 8);  // uncompressed length
    Pos := Pos + 5;
    SetLength(Result, OutLen + BlockLen);

    Produced := 0;
    while (Produced < BlockLen) and (Pos < Len) do
    begin
      if Data[Pos] = MJHMarker then
      begin
        if Pos + 2 >= Len then
          Break;  // truncated run packet
        Count := Data[Pos + 1];
        Value := Data[Pos + 2];
        Pos := Pos + 3;
        if Count = 0 then
          Count := 256;  // a count of zero means 256 repeats
        if Count > BlockLen - Produced then
          Count := BlockLen - Produced;  // never overrun the block (surplus ignored)
        for I := 1 to Count do
        begin
          Result[OutLen + Produced] := Value;
          Inc(Produced);
        end;
      end
      else
      begin
        Result[OutLen + Produced] := Data[Pos];
        Inc(Pos);
        Inc(Produced);
      end;
    end;
    OutLen := OutLen + Produced;
  end;

  SetLength(Result, OutLen);  // trim any over-allocation from a short final block
end;

class function TAmstradScreen.GetScreenData(const Data: array of byte): TDiskByteArray;
begin
  if IsMJHCompressed(Data) then
    Result := DecompressMJH(Data)
  else
  begin
    SetLength(Result, Length(Data));
    if Length(Data) > 0 then
      Move(Data[0], Result[0], Length(Data));
  end;

  // A real screen is ~16K; MJH window (.WIN) clips and other files decompress
  // to something smaller, so reject anything outside the valid screen range.
  if not IsValidScreenSize(Length(Result)) then
    Result := nil;
end;

const
  // A mode is judged "banded" when its busiest within-byte edge phase exceeds
  // the average within-byte phase by these factors. Decoding data at too high a
  // resolution piles edges onto the bit-interleave-aligned boundary, so the
  // ratio towers; a coherent image spreads edges evenly and stays near 1.
  //
  // Two thresholds because the two decision points have different phase counts
  // (mode 2 has 7 within-byte boundaries, mode 1 has 3) and so different scales.
  // Calibrated against known mode-0/1 sample screens: mode-1 screens score
  // <= 1.28 at mode 1 while mode-0 screens score >= 1.60, and every non-mode-2
  // screen scores >= 1.44 at mode 2. The thresholds sit in those gaps.
  Mode2BandingThreshold = 1.38;  // below this, mode 2 looks coherent -> mode 2
  Mode1BandingThreshold = 1.44;  // at/above this, mode 1 still bands -> mode 0
  // Screens with almost no horizontal detail give no banding signal at all;
  // treat any overall edge fraction below this as "flat" and fall back to mode 1.
  FlatEdgeFloor = 0.01;

// Score how strongly a mode shows vertical-line banding. Returns the ratio of
// the busiest within-byte edge phase to the mean within-byte phase (>= 1, higher
// means more banding) and reports the overall edge fraction via OverallEdgeFrac.
function ModeBandingScore(const Data: array of byte; Mode: TAmstradMode;
  Offset: integer; out OverallEdgeFrac: Double): Double;
var
  PixelsPerLine, PixelsPerByte, Y, X, Phase, NumPhases: integer;
  Row: array of integer;
  PhaseEdges, PhaseBounds: array of int64;
  TotalEdges, TotalBounds: int64;
  EdgeFrac, MaxFrac, SumFrac, MeanFrac: double;
begin
  Result := 0;
  OverallEdgeFrac := 0;
  Row := nil;
  PhaseEdges := nil;
  PhaseBounds := nil;
  ModeMetrics(Mode, PixelsPerLine, PixelsPerByte);
  if PixelsPerByte < 2 then
    Exit;  // need at least one within-byte boundary to measure

  SetLength(Row, PixelsPerLine);
  SetLength(PhaseEdges, PixelsPerByte);
  SetLength(PhaseBounds, PixelsPerByte);
  for X := 0 to PixelsPerByte - 1 do
  begin
    PhaseEdges[X] := 0;
    PhaseBounds[X] := 0;
  end;

  for Y := 0 to CPCLines - 1 do
  begin
    DecodeRow(Data, Mode, Offset, Y, PixelsPerByte, Row);
    for X := 0 to PixelsPerLine - 2 do
    begin
      Phase := X mod PixelsPerByte;  // 0..ppb-2 within a byte, ppb-1 crosses bytes
      Inc(PhaseBounds[Phase]);
      if Row[X] <> Row[X + 1] then
        Inc(PhaseEdges[Phase]);
    end;
  end;

  TotalEdges := 0;
  TotalBounds := 0;
  for X := 0 to PixelsPerByte - 1 do
  begin
    TotalEdges := TotalEdges + PhaseEdges[X];
    TotalBounds := TotalBounds + PhaseBounds[X];
  end;
  if TotalBounds > 0 then
    OverallEdgeFrac := TotalEdges / TotalBounds;

  // Compare only the within-byte boundaries (phases 0..ppb-2); the cross-byte
  // boundary reflects genuine adjacent content and is excluded.
  MaxFrac := 0;
  SumFrac := 0;
  NumPhases := 0;
  for Phase := 0 to PixelsPerByte - 2 do
    if PhaseBounds[Phase] > 0 then
    begin
      EdgeFrac := PhaseEdges[Phase] / PhaseBounds[Phase];
      SumFrac := SumFrac + EdgeFrac;
      Inc(NumPhases);
      if EdgeFrac > MaxFrac then
        MaxFrac := EdgeFrac;
    end;
  if NumPhases = 0 then
    Exit;
  MeanFrac := SumFrac / NumPhases;
  if MeanFrac > 0 then
    Result := MaxFrac / MeanFrac;
end;

class function TAmstradScreen.GuessMode(const Data: array of byte;
  Offset: integer): TAmstradMode;
var
  Score2, Score1, Overall2, Overall1: double;
begin
  // Start at the highest resolution and step down: a coherent image stays put,
  // banding means the data was authored for a lower-resolution mode.
  Score2 := ModeBandingScore(Data, amMode2, Offset, Overall2);

  // No horizontal detail at all - nothing to analyse, keep the historical default.
  if Overall2 < FlatEdgeFloor then
  begin
    Result := amMode1;
    Exit;
  end;

  // Mode 2 looks coherent -> the screen was meant for mode 2.
  if Score2 < Mode2BandingThreshold then
  begin
    Result := amMode2;
    Exit;
  end;

  // Mode 2 banded; retry at mode 1. Coherent -> mode 1, still banded -> mode 0.
  Score1 := ModeBandingScore(Data, amMode1, Offset, Overall1);
  if Score1 < Mode1BandingThreshold then
    Result := amMode1
  else
    Result := amMode0;
end;

class procedure TAmstradScreen.RenderToBitmap(const Data: array of byte;
  Mode: TAmstradMode; Bitmap: TBitmap; Zoom: integer; Offset: integer);
var
  PenColor: array[0..15] of TColor;
  PixelsPerLine, PixelsPerByte, PixelWidth: integer;
  Y, Col, LineBase, P, LX, Left, Top, BlockW, BlockH: integer;
  B: byte;
  DataLen: integer;

begin
  if Zoom < 1 then
    Zoom := 1;

  ModeMetrics(Mode, PixelsPerLine, PixelsPerByte);
  PixelWidth := CPCDisplayWidth div PixelsPerLine;  // 4, 2 or 1

  for P := 0 to 15 do
    PenColor[P] := RGBToColor(HardwarePalette[DefaultInk[P]].R,
      HardwarePalette[DefaultInk[P]].G, HardwarePalette[DefaultInk[P]].B);

  Bitmap.PixelFormat := pf24bit;
  Bitmap.Width := CPCDisplayWidth * Zoom;
  Bitmap.Height := CPCDisplayHeight * Zoom;

  DataLen := Length(Data);
  BlockW := PixelWidth * Zoom;
  BlockH := 2 * Zoom;  // scanlines are doubled to keep a sensible aspect ratio

  for Y := 0 to CPCLines - 1 do
  begin
    LineBase := ScreenLineBase(Y);
    Top := Y * BlockH;

    for Col := 0 to CPCBytesPerLine - 1 do
    begin
      if (Offset + LineBase + Col >= 0) and (Offset + LineBase + Col < DataLen) then
        B := Data[Offset + LineBase + Col]
      else
        B := 0;

      for P := 0 to PixelsPerByte - 1 do
      begin
        LX := Col * PixelsPerByte + P;
        Left := LX * BlockW;
        Bitmap.Canvas.Brush.Color := PenColor[DecodePen(B, P, Mode)];
        Bitmap.Canvas.FillRect(Left, Top, Left + BlockW, Top + BlockH);
      end;
    end;
  end;
end;

end.
