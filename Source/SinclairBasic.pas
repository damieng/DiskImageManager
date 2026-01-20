unit SinclairBasic;

{$MODE Delphi}

{
  Disk Image Manager - Sinclair BASIC tokenized file decoder

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  DskImage, FileSystem, SysUtils, Math;

type
  TSinclairBasicMode = (sbMode48K, sbMode128K);

  TSinclairBasicParser = class
  private
    FMode: TSinclairBasicMode;
    function GetTokenText(Token: byte): string;
    function DecodeSpectrumIntegral(const Bytes: array of byte): string;
    function DecodeSpectrumFloat(const Bytes: array of byte): string;
    function DecodeLine(const Data: array of byte; StartPos, Length: integer): string;
    function GetSpecialChar(B: byte): string;
  public
    constructor Create(Mode: TSinclairBasicMode = sbMode128K);
    function Decode(const Data: array of byte): string;
    function DecodeFile(DiskImage: TDSKDisk; DiskFile: TCPMFile): string;
    property Mode: TSinclairBasicMode read FMode write FMode;
  end;

implementation

const
  Tokens: array[$A5..$FF] of string = (
    'RND', 'INKEY$', 'PI', 'FN', 'POINT', 'SCREEN$', 'ATTR', 'AT', 'TAB',
    'VAL$', 'CODE', 'VAL', 'LEN', 'SIN', 'COS', 'TAN', 'ASN', 'ACS', 'ATN',
    'LN', 'EXP', 'INT', 'SQR', 'SGN', 'ABS', 'PEEK', 'IN', 'USR', 'STR$',
    'CHR$', 'NOT', 'BIN', 'OR', 'AND', '<=', '>=', '<>', 'LINE', 'THEN',
    'TO', 'STEP', 'DEF FN', 'CAT', 'FORMAT', 'MOVE', 'ERASE', 'OPEN #',
    'CLOSE #', 'MERGE', 'VERIFY', 'BEEP', 'CIRCLE', 'INK', 'PAPER', 'FLASH',
    'BRIGHT', 'INVERSE', 'OVER', 'OUT', 'LPRINT', 'LLIST', 'STOP', 'READ',
    'DATA', 'RESTORE', 'NEW', 'BORDER', 'CONTINUE', 'DIM', 'REM', 'FOR',
    'GO TO', 'GO SUB', 'INPUT', 'LOAD', 'LIST', 'LET', 'PAUSE', 'NEXT',
    'POKE', 'PRINT', 'PLOT', 'RUN', 'SAVE', 'RANDOMIZE', 'IF', 'CLS',
    'DRAW', 'CLEAR', 'RETURN', 'COPY'
  );

constructor TSinclairBasicParser.Create(Mode: TSinclairBasicMode);
begin
  inherited Create;
  FMode := Mode;
end;

function TSinclairBasicParser.GetTokenText(Token: byte): string;
begin
  case Token of
    $A3:
      if FMode = sbMode128K then
        Result := 'SPECTRUM'
      else
        Result := 'UDG-A';
    $A4:
      if FMode = sbMode128K then
        Result := 'PLAY'
      else
        Result := 'UDG-B';
    $A5..$FF:
      Result := Tokens[Token];
  else
    Result := Format('?%02X?', [Token]);
  end;
end;

function TSinclairBasicParser.DecodeSpectrumIntegral(const Bytes: array of byte): string;
var
  SignByte: byte;
  Low, High: word;
  UnsignedValue: word;
  Value: integer;
begin
  if Length(Bytes) < 5 then
  begin
    Result := '';
    Exit;
  end;

  // Format: [0, sign_byte, low, high, 0]
  // Skip display - the ASCII representation precedes this
  SignByte := Bytes[1];
  Low := Bytes[2];
  High := Bytes[3];
  UnsignedValue := Low or (High shl 8);

  if SignByte = $FF then
    Value := integer(UnsignedValue) - 65536
  else
    Value := UnsignedValue;

  Result := '';  // Don't output - the number is already in ASCII form before this marker
end;

function TSinclairBasicParser.DecodeSpectrumFloat(const Bytes: array of byte): string;
var
  ExponentBiased: byte;
  Exponent: integer;
  IsNegative: boolean;
  Byte1WithoutSign: byte;
  MantissaLower31: cardinal;
  Mantissa: cardinal;
  MantissaF, ExpF, Value: double;
begin
  if Length(Bytes) < 5 then
  begin
    Result := '';
    Exit;
  end;

  ExponentBiased := Bytes[0];
  Exponent := integer(ExponentBiased) - 128;

  // Extract sign from bit 7 of byte 1
  IsNegative := (Bytes[1] and $80) <> 0;

  // Clear sign bit and reconstruct mantissa (big-endian in bytes 1-4)
  Byte1WithoutSign := Bytes[1] and $7F;
  MantissaLower31 := (cardinal(Byte1WithoutSign) shl 24) or
                     (cardinal(Bytes[2]) shl 16) or
                     (cardinal(Bytes[3]) shl 8) or
                     cardinal(Bytes[4]);
  MantissaLower31 := MantissaLower31 and $7FFFFFFF;

  // Reconstruct full mantissa with implicit bit 31 set
  Mantissa := $80000000 or MantissaLower31;

  // Calculate value: (mantissa / 2^31) * 2^exponent
  MantissaF := Mantissa / 2147483648.0;  // 2^31
  ExpF := Power(2.0, Exponent);
  Value := MantissaF * ExpF;

  if IsNegative then
    Value := -Value;

  Result := '';  // Don't output - the number is already in ASCII form before this marker
end;

function TSinclairBasicParser.GetSpecialChar(B: byte): string;
begin
  case B of
    $7F: Result := #$C2#$A9;  // Copyright symbol (UTF-8)
    $80..$8F: Result := '[UDG]';
    $90..$9F: Result := '[GRAPH]';
    $A0: Result := ' ';
    $A1: Result := #$C2#$A3;  // Pound sign (UTF-8)
    $A2: Result := '$';
  else
    Result := '?';
  end;
end;

function TSinclairBasicParser.DecodeLine(const Data: array of byte; StartPos, Length: integer): string;
var
  Pos, EndPos: integer;
  B: byte;
  LastWasSpace: boolean;
begin
  Result := '';
  Pos := StartPos;
  EndPos := StartPos + Length;
  LastWasSpace := True;  // Start of line counts as "after space"

  while Pos < EndPos do
  begin
    if Pos >= System.Length(Data) then
      Break;

    B := Data[Pos];
    Inc(Pos);

    case B of
      // End of line marker
      $0D:
        Break;

      // Number marker (integral format) - skip 5 bytes
      // The ASCII representation precedes this, so we just skip the binary
      $0E:
        begin
          if Pos + 5 <= EndPos then
            Inc(Pos, 5)  // Skip the 5-byte number representation
          else
            Pos := EndPos;  // Not enough data, skip to end
        end;

      // Number marker (floating point format) - skip 5 bytes
      // Same as above - ASCII already displayed
      $7E:
        begin
          if Pos + 5 <= EndPos then
            Inc(Pos, 5)  // Skip the 5-byte number representation
          else
            Pos := EndPos;  // Not enough data, skip to end
        end;

      // Tokens $A3 and $A4 (mode-dependent)
      $A3, $A4:
        begin
          if not LastWasSpace then
            Result := Result + ' ';
          Result := Result + GetTokenText(B) + ' ';
          LastWasSpace := True;
        end;

      // Tokens $A5-$FF are BASIC keywords
      $A5..$FF:
        begin
          if not LastWasSpace then
            Result := Result + ' ';
          Result := Result + GetTokenText(B) + ' ';
          LastWasSpace := True;
        end;

      // Regular printable ASCII (excluding 0x7E which is the float marker)
      $20..$7D, $7F:
        begin
          if B = $7F then
            Result := Result + GetSpecialChar(B)  // Copyright symbol
          else
            Result := Result + Chr(B);
          LastWasSpace := (B = $20);
        end;

      // Extended characters (0x80-0xA2, note: 0x7F is handled above with ASCII)
      $80..$A2:
        begin
          Result := Result + GetSpecialChar(B);
          LastWasSpace := False;
        end;

      // Control characters and others - skip
    else
      // Unknown - skip
    end;
  end;
end;

function TSinclairBasicParser.Decode(const Data: array of byte): string;
var
  Pos, DataLen: integer;
  LineNum: word;
  LineLen: word;
  LineText: string;
begin
  Result := '';
  Pos := 0;
  DataLen := System.Length(Data);

  while Pos < DataLen do
  begin
    // Need at least 4 bytes for line header
    if Pos + 4 > DataLen then
      Break;

    // Read line number (2 bytes, big-endian)
    LineNum := (word(Data[Pos]) shl 8) or word(Data[Pos + 1]);
    Inc(Pos, 2);

    // Check for end marker
    if LineNum = $8080 then
      Break;

    // Read line length (2 bytes, little-endian)
    LineLen := word(Data[Pos]) or (word(Data[Pos + 1]) shl 8);
    Inc(Pos, 2);

    // Validate line length
    if LineLen < 1 then
      Break;

    // Decode the line
    LineText := DecodeLine(Data, Pos, LineLen);
    Result := Result + Format('%d %s'#13#10, [LineNum, LineText]);

    // Move to next line
    Inc(Pos, LineLen);
  end;
end;

function TSinclairBasicParser.DecodeFile(DiskImage: TDSKDisk; DiskFile: TCPMFile): string;
var
  FileData: TDiskByteArray;
  BasicData: TDiskByteArray;
begin
  Result := '';

  // Check if this is a PLUS3DOS BASIC file
  if (DiskFile.HeaderType <> 'PLUS3DOS') or
     (not DiskFile.Meta.StartsWith('BASIC')) then
    Exit;

  // Get file data without header
  FileData := DiskFile.GetData(False);
  if System.Length(FileData) = 0 then
    Exit;

  // Decode the BASIC program
  BasicData := FileData;
  Result := Decode(BasicData);
end;

end.
