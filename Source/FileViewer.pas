unit FileViewer;

{$MODE Delphi}

{
  Disk Image Manager - File content viewer window

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls,
  DskImage, FileSystem, SinclairBasic;

type
  TfrmFileViewer = class(TForm)
    memoContent: TMemo;
    procedure FormCreate(Sender: TObject);
  private
    FDiskName: string;
    FFileName: string;
    procedure UpdateCaption;
  public
    procedure LoadBasicFile(DiskImage: TDSKDisk; DiskFile: TCPMFile; const DiskName: string);
    property DiskName: string read FDiskName write FDiskName;
    property FileName: string read FFileName write FFileName;
  end;

procedure ShowBasicViewer(DiskImage: TDSKDisk; DiskFile: TCPMFile; const DiskName: string);

implementation

{$R *.lfm}

procedure ShowBasicViewer(DiskImage: TDSKDisk; DiskFile: TCPMFile; const DiskName: string);
var
  Viewer: TfrmFileViewer;
begin
  Viewer := TfrmFileViewer.Create(Application);
  Viewer.LoadBasicFile(DiskImage, DiskFile, DiskName);
  Viewer.Show;
end;

procedure TfrmFileViewer.FormCreate(Sender: TObject);
begin
  FDiskName := '';
  FFileName := '';
end;

procedure TfrmFileViewer.UpdateCaption;
begin
  if (FDiskName <> '') and (FFileName <> '') then
    Caption := Format('%s - %s', [FFileName, FDiskName])
  else if FFileName <> '' then
    Caption := FFileName
  else
    Caption := 'File Viewer';
end;

procedure TfrmFileViewer.LoadBasicFile(DiskImage: TDSKDisk; DiskFile: TCPMFile; const DiskName: string);
var
  Parser: TSinclairBasicParser;
  BasicText: string;
begin
  FDiskName := DiskName;
  FFileName := DiskFile.FileName;
  UpdateCaption;

  Parser := TSinclairBasicParser.Create(sbMode128K);
  try
    BasicText := Parser.DecodeFile(DiskImage, DiskFile);
    if BasicText = '' then
      BasicText := '(Unable to decode BASIC program)';
    memoContent.Text := BasicText;
  finally
    Parser.Free;
  end;
end;

end.
