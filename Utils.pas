unit Utils;

{
  Disk Image Manager -  Copyright 2002-2009 Envy Technologies Ltd.

  Utility functions
}

interface

uses
  Classes, Graphics, Windows, SysUtils;

const
  BytesPerKB: Integer = 1024;
  Power2: array[1..17] of Integer = (1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536);

type
  TSpinBorderStyle = (bsRaised,bsLowered,bsNone);

function StrInt(I: Integer): String;
function StrHex(I: Integer): String;
function IntStr(S: String): Integer;
function StrBlockClean(S: array of Char; Start, Len: Integer): String;
function StrYesNo(IsEmpty: Boolean): String;
function StrInByteArray(ByteArray: array of byte; SubString: String; Start: Integer): Boolean;

function CompareBlock(A: array of Char; B: String): Boolean;
function CompareBlockStart(A: array of Char; B: String; Start: Integer): Boolean;

function FontToDescription(ThisFont: TFont): String;
function FontFromDescription(Description: String): TFont;
function FontDescription(ThisFont: TFont): String;
function FontCopy(ThisFont: TFont): TFont;

function FingerPrintFile(FileName: TFileName): String;

procedure DrawBorder(Canvas: TCanvas; var Rect: TRect; BorderStyle: TSpinBorderStyle);

implementation

// Get integer as a decimal string
function StrInt(I: Integer): String;
begin
  Str(I, Result);
end;

// Get integer as a hex string
function StrHex(I: Integer): String;
begin
  Result := Format('%.2x',[I]);
end;

// Get string as an integer
function IntStr(S: String): Integer;
var
  Temp: Integer;
begin
  Val(S, Result, Temp);
end;

// Extract ASCII string from a char array
function StrBlockClean(S: array of Char; Start, Len: Integer): String;
var
  Idx: Integer;
begin
	for Idx := Start to Len-1 do
  	if ((Ord(S[Idx]) > 31) and (Ord(S[Idx]) < 128)) then
    	Result := Result + S[Idx];
end;

// Compare two char arrays
function CompareBlock(A: array of Char; B: String): Boolean;
var
  Idx: Integer;
begin
  Result := True;
  Idx := 0;
  while (Result and (Idx < Length(B)-1)) do
  begin
  	if (A[Idx] <> B[Idx+1]) then
     	Result := False;
    inc(Idx);
  end;
end;

// Compare two char arrays
function CompareBlockStart(A: array of Char; B: String; Start: Integer): Boolean;
var
  Idx: Integer;
begin
  Result := True;
  Idx := 0;
  while (Result and (Idx < Length(B)-1)) do
  begin
  	if (A[Idx+Start] <> B[Idx+1]) then
    	Result := False;
    inc(Idx);
  end;
end;

// Draw a windows style 3D border
procedure DrawBorder(Canvas: TCanvas; var Rect: TRect; BorderStyle: TSpinBorderStyle);
var
  OTL, ITL, OBR, IBR: TColor;
begin
  case BorderStyle of
  	bsLowered:
    begin
    	OTL := clBtnShadow;
      ITL := cl3DDkShadow;
      IBR := cl3DLight;
      OBR := clBtnHighlight;
    end;

    bsRaised:
    begin
    	OBR := clBtnShadow;
      IBR := cl3DDkShadow;
      OTL := clBtnHighlight;
      ITL := cl3DLight;
  	end;

    else exit;
  end;

  with Canvas do
  begin
  	dec(Rect.Bottom);
    dec(Rect.Right);
    Pen.Color := OTL;
    MoveTo(Rect.Left, Rect.Bottom);
    LineTo(Rect.Left, Rect.Top);
    LineTo(Rect.Right, Rect.Top);

    Pen.Color := OBR;
    LineTo(Rect.Right, Rect.Bottom);
    LineTo(Rect.Left, Rect.Bottom);
    InflateRect(Rect,-1,-1);

    Pen.Color := ITL;
    MoveTo(Rect.Left, Rect.Bottom);
    LineTo(Rect.Left, Rect.Top);
    LineTo(Rect.Right, Rect.Top);

    Pen.Color := IBR;
    LineTo(Rect.Right, Rect.Bottom);
    LineTo(Rect.Left, Rect.Bottom);
    inc(Rect.Top);
    inc(Rect.Left);
  end;
end;

// Convert a font into a textual description
function FontToDescription(ThisFont: TFont): String;
begin
  Result := ThisFont.Name + ',' + StrInt(ThisFont.Size) + 'pt,';
  if (fsBold in ThisFont.Style) then Result := Result + 'Bold';
  Result := Result + ',';
  if (fsItalic in ThisFont.Style) then Result := Result + 'Italic';
end;

// Create a font from a textual description
function FontFromDescription(Description: String): TFont;
var
  Break: TStringList;
begin
  Break := TStringList.Create;
  Break.Delimiter := ',';
  Break.DelimitedText := StringReplace(Description,' ','_',[rfReplaceAll]);
  Result := TFont.Create;
  Result.Name := StringReplace(Break[0],'_',' ',[rfReplaceAll]);
  Result.Size := IntStr(StringReplace(Break[1],'pt','',[rfReplaceAll]));
  if (Break[1] = 'Bold') then Result.Style := Result.Style + [fsBold];
  if (Break[2] = 'Italic') then Result.Style := Result.Style + [fsItalic];
  Break.Free;
end;

// Copy a font
function FontCopy(ThisFont: TFont): TFont;
begin
  Result := TFont.Create;
  with Result do
  begin
  	Name := ThisFont.Name;
    Style := ThisFont.Style;
    Size := ThisFont.Size;
  end;
end;

// Font as human readable description
function FontDescription(ThisFont: TFont): String;
begin
  Result := StringReplace(FontToDescription(ThisFont),',',' ',[rfReplaceAll]);
end;

function StrYesNo(IsEmpty: Boolean): String;
begin
  if IsEmpty then
  	Result := 'Yes'
  else
  	Result := 'No';
end;

function StrInByteArray(ByteArray: array of Byte; SubString: String; Start: Integer): Boolean;
var
	Idx, Last: Integer;
begin
	Result := True;
	Idx := 0;
  Last := Length(ByteArray)-Length(SubString)-1;
	while ((Result) and (Start+Idx < Last) and (Idx < Length(SubString))) do
  begin
		if ByteArray[Start+Idx] <> Byte(SubString[Idx+1]) then Result := False;
    inc(Idx);
  end;
end;

function FingerPrintFile(FileName: TFileName): String;
var
  //Hasher: TDCP_sha1;
  HashDigest: array of Byte;
  FileStream: TFileStream;
  Buffer: array[0..65535] of Byte;
  ReadBytes, Idx: Integer;
begin
  FileStream := TFileStream.Create(FileName,fmOpenRead);
  try
    //Hasher := TDCP_sha1.Create(nil);
    //Hasher.Init;
    repeat
      ReadBytes := FileStream.Read(Buffer,SizeOf(Buffer));
      //Hasher.Update(Buffer,ReadBytes);
    until ReadBytes <> SizeOf(Buffer);
    FileStream.Free;

    //SetLength(HashDigest,Hasher.HashSize div 8);
    //Hasher.Final(HashDigest[0]);  // get the output

    Result := '';
    for Idx := 0 to Length(HashDigest) - 1 do  // convert it into a hex string
    begin
      if (((Idx mod 4) = 0) and (Idx > 0)) then Result := Result + ' ';
    	 Result := Result + IntToHex(HashDigest[Idx],2);
    end;
  except
    //Hasher.Free;
    FileStream.Free;
    Result := 'Error reading file.';
  end;
end;

end.
