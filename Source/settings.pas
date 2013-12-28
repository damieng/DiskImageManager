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
  Classes, SysUtils, Registry, Graphics, Forms, FileUtil;

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

    // SamDisk
    SamDiskEnabled: boolean;
    SamDiskLocation: string;

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

const
    RegKey = 'Software\DamienG\DiskImageManager';

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

    itmRead.Visible := SamDiskEnabled;
    itmWrite.Visible := SamDiskEnabled;
  end;
end;

// Load system settings
procedure TSettings.Load;
var
  Reg: TRegIniFile;
  Count, Idx: integer;
  FileName: TFileName;
  S: string;
begin
  Reg := TRegIniFile.Create(RegKey);

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
    Count := Reg.ReadInteger(S, '', 0);
    for Idx := 1 to Count do
    begin
      FileName := Reg.ReadString(S, StrInt(Idx), '');
      if FileExistsUTF8(FileName) then
        frmMain.LoadImage(FileName);
    end;
  end;

  S := 'Saving';
  WarnConversionProblems := Reg.ReadBool(S, 'WarnConversionProblems', True);
  RemoveEmptyTracks := Reg.ReadBool(S, 'RemoveEmptyTracks', False);
  SaveDiskMapWidth := Reg.ReadInteger(S, 'MapWidth', 640);
  SaveDiskMapHeight := Reg.ReadInteger(S, 'MapHeight', 480);

  S := 'SamDisk';
  SamDiskEnabled := Reg.ReadBool(S, 'Enabled', False);
  SamDiskLocation := Reg.ReadString(S, 'Location', '');

  Reg.Free;

  Apply;
end;


procedure TSettings.Save;
var
  Reg: TRegIniFile;
  Idx, Count: integer;
  S: string;
begin
  Reg := TRegIniFile.Create(RegKey);

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
  Reg.WriteInteger(S, '', Count - 1);

  S := 'Saving';
  Reg.WriteBool(S, 'WarnConversionProblems', WarnConversionProblems);
  Reg.WriteBool(S, 'RemoveEmptyTracks', RemoveEmptyTracks);
  Reg.WriteInteger(S, 'MapWidth', SaveDiskMapWidth);
  Reg.WriteInteger(S, 'MapHeight', SaveDiskMapHeight);

  S := 'SamDisk';
  Reg.WriteBool(S, 'Enabled', SamDiskEnabled);
  Reg.WriteString(S, 'Location', SamDiskLocation);

  Reg.Free;
end;

procedure TSettings.Reset;
var
  Reg: TRegIniFile;
begin
  Reg := TRegIniFile.Create(RegKey);
  Reg.EraseSection('DiskMap');
  Reg.EraseSection('SectorView');
  Reg.EraseSection('Window');
  Reg.EraseSection('Workspace');
  Reg.Free;

  Load;
end;

end.
