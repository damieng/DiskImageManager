unit Settings;

{$MODE Delphi}

{
  Disk Image Manager -  Options window

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  Utils, DskImage,
  Classes, Dialogs, SysUtils, IniFiles, Graphics, Forms, FileUtil,
  LazFileUtils;

type TSettings = class(TObject)
  public
    // Disk map
    DarkBlankSectors: boolean;
    DiskMapFont: TFont;
    DiskMapBackgroundColor: TColor;
    DiskMapGridColor: TColor;
    DiskMapTrackMark: integer;

    // Window
    WindowFont: TFont;
    RestoreWindow: boolean;

    // Sector view
    UnknownASCII: string;
    BytesPerLine: integer;
    SectorFont: TFont;
    WarnSectorChange: boolean;

    // Workspace
    RestoreWorkspace: boolean;
    OpenView: string;

    // Saving
    WarnConversionProblems: boolean;
    RemoveEmptyTracks: boolean;
    SaveDiskMapHeight, SaveDiskMapWidth: integer;

    constructor Create(Owner: TForm);
    procedure Load;
    procedure Apply;
    procedure Save;
    procedure Reset;
end;

implementation

uses Main;

var
  frmMain: TFrmMain;

constructor TSettings.Create(Owner: TForm);
begin
  frmMain := TFrmMain(Owner);
end;

// Apply some settings directly to other places
procedure TSettings.Apply;
begin
  with frmMain do
  begin
    Font := WindowFont;
    DiskMap.DarkBlankSectors := DarkBlankSectors;
    DiskMap.GridColor := DiskMapGridColor;
    DiskMap.Color := DiskMapBackgroundColor;
    DiskMap.TrackMark := DiskMapTrackMark;
  end;
end;

// Load system settings
procedure TSettings.Load;
var
  Reg: TIniFile;
  Idx: integer;
  FileName: TFileName;
  S: string;
begin
  Reg := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));

  S := 'DiskMap';
  DarkBlankSectors := Reg.ReadBool(S, 'DarkBlankSectors', True);
  DiskMapFont := FontFromDescription(Reg.ReadString(S, 'Font', 'Tahoma,7pt,,'));
  DiskMapBackgroundColor := TColor(Reg.ReadInteger(S, 'BackgroundColour', integer(clGray)));
  DiskMapGridColor := TColor(Reg.ReadInteger(S, 'GridColour', integer(clSilver)));
  DiskMapTrackMark := Reg.ReadInteger(S, 'TrackMark', 5);

  S := 'Window';
  WindowFont := FontFromDescription(Reg.ReadString(S, 'Font', 'Tahoma,8pt,,'));
  RestoreWindow := Reg.ReadBool(S, 'Restore', False);
  if RestoreWindow then
  with frmMain do
  begin
    Left := Reg.ReadInteger(S, 'Left', Left);
    Top := Reg.ReadInteger(S, 'Top', Top);
    Height := Reg.ReadInteger(S, 'Height', Height);
    Width := Reg.ReadInteger(S, 'Width', Width);
    tvwMain.Width := Reg.ReadInteger(S, 'TreeWidth', tvwMain.Width);
  end;

  S := 'SectorView';
  UnknownASCII := Reg.ReadString(S, 'UnknownASCII', '?');
  BytesPerLine := Reg.ReadInteger(S, 'BytesPerLine', 8);
  SectorFont := FontFromDescription(Reg.ReadString(S, 'Font', 'Consolas,8pt,,'));
  WarnSectorChange := Reg.ReadBool(S, 'WarnSectorChange', True);

  S := 'Workspace';
  RestoreWorkspace := Reg.ReadBool(S, 'Restore', False);
  if RestoreWorkspace then
  begin
    Idx := 1;
    repeat
      FileName := Reg.ReadString(S, StrInt(Idx), '*end');
      if (FileName <> '*end') and (FileExistsUTF8(FileName)) then
        frmMain.LoadImage(FileName);
      inc(Idx);
    until FileName = '*end';
  end;

  S := 'Saving';
  WarnConversionProblems := Reg.ReadBool(S, 'WarnConversionProblems', True);
  RemoveEmptyTracks := Reg.ReadBool(S, 'RemoveEmptyTracks', False);
  SaveDiskMapWidth := Reg.ReadInteger(S, 'MapWidth', 640);
  SaveDiskMapHeight := Reg.ReadInteger(S, 'MapHeight', 480);

  Reg.Free;

  Apply;
end;


procedure TSettings.Save;
var
  Reg: TIniFile;
  Idx, Count: integer;
  S: string;
begin
  Reg := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));

  S := 'DiskMap';
  Reg.WriteInteger(S, 'BackgroundColour', integer(DiskMapBackgroundColor));
  Reg.WriteBool(s, 'DarkBlankSectors', DarkBlankSectors);
  Reg.WriteInteger(S, 'GridColour', integer(DiskMapGridColor));
  Reg.WriteInteger(S, 'TrackMark', DiskMapTrackMark);
  Reg.WriteString(S, 'Font', FontToDescription(DiskMapFont));

  S := 'Window';
  with frmMain do
  begin
    Reg.WriteBool(S, 'Restore', RestoreWindow);
    Reg.WriteInteger(S, 'Left', Left);
    Reg.WriteInteger(S, 'Top', Top);
    Reg.WriteInteger(S, 'Height', Height);
    Reg.WriteInteger(S, 'Width', Width);
    Reg.WriteInteger(S, 'TreeWidth', tvwMain.Width);
    Reg.WriteString(S, 'Font', FontToDescription(Font));
  end;

  S := 'SectorView';
  Reg.WriteString(S, 'UnknownASCII', UnknownASCII);
  Reg.WriteInteger(S, 'BytesPerLine', BytesPerLine);
  Reg.WriteString(S, 'Font', FontToDescription(SectorFont));
  Reg.WriteBool(S, 'WarnSectorChange', WarnSectorChange);

  S := 'Workspace';
  Count := 1;
  Reg.EraseSection(S);
  Reg.WriteBool(S, 'Restore', RestoreWorkspace);
  with frmMain do
    for Idx := 0 to tvwMain.Items.Count - 1 do
      if (tvwMain.Items[Idx].Data <> nil) and
        (TObject(tvwMain.Items[Idx].Data).ClassType = TDSKImage) then
      begin
        Reg.WriteString(S, StrInt(Count), TDSKImage(tvwMain.Items[Idx].Data).FileName);
        Inc(Count);
      end;

  S := 'Saving';
  Reg.WriteBool(S, 'WarnConversionProblems', WarnConversionProblems);
  Reg.WriteBool(S, 'RemoveEmptyTracks', RemoveEmptyTracks);
  Reg.WriteInteger(S, 'MapWidth', SaveDiskMapWidth);
  Reg.WriteInteger(S, 'MapHeight', SaveDiskMapHeight);

  Reg.Free;
end;

procedure TSettings.Reset;
begin
  DeleteFile(ChangeFileExt(Application.ExeName, '.ini'));
  Load;
end;

end.
