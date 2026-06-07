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
  Graphics, Classes, SysUtils;

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

class function TAmstradScreen.IsValidScreenSize(Size: integer): boolean;
begin
  // Accept anything from a bare visible image up to a screen with a small
  // header/trailer (some .SCR files carry a few extra bytes and span 17 blocks)
  Result := (Size >= CPCVisibleBytes) and (Size <= CPCScreenMaxBytes);
end;

class procedure TAmstradScreen.RenderToBitmap(const Data: array of byte;
  Mode: TAmstradMode; Bitmap: TBitmap; Zoom: integer; Offset: integer);
var
  PenColor: array[0..15] of TColor;
  PixelsPerLine, PixelsPerByte, PixelWidth: integer;
  Y, Col, LineBase, P, LX, Left, Top, BlockW, BlockH: integer;
  B: byte;
  DataLen: integer;

  function ModePen(AByte: byte; Pixel: integer): integer;
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

begin
  if Zoom < 1 then
    Zoom := 1;

  case Mode of
    amMode0: begin PixelsPerLine := 160; PixelsPerByte := 2; end;
    amMode1: begin PixelsPerLine := 320; PixelsPerByte := 4; end;
  else
    begin PixelsPerLine := 640; PixelsPerByte := 8; end;
  end;
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
    // CPC screen interleave: 8 scanlines per character row, 2048 bytes apart
    LineBase := (Y mod 8) * 2048 + (Y div 8) * CPCBytesPerLine;
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
        Bitmap.Canvas.Brush.Color := PenColor[ModePen(B, P)];
        Bitmap.Canvas.FillRect(Left, Top, Left + BlockW, Top + BlockH);
      end;
    end;
  end;
end;

end.
