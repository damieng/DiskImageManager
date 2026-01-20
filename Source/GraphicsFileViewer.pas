unit GraphicsFileViewer;

{$MODE Delphi}

{
  Disk Image Manager - Graphics file viewer for Spectrum SCREEN$ files

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ExtCtrls, ComCtrls, StdCtrls,
  DskImage, FileSystem, SpectrumScreen;

type

  { TfrmGraphicsFileViewer }

  TfrmGraphicsFileViewer = class(TForm)
    lblZoom: TLabel;
    toolbar: TToolBar;
    imgScreen: TImage;
    tckZoom: TTrackBar;
    tmrFlash: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure tckZoomChange(Sender: TObject);
    procedure tmrFlashTimer(Sender: TObject);
  private
    FDiskName: string;
    FFileName: string;
    FScreenData: array of byte;
    FZoom: integer;
    FHasFlash: boolean;
    FFlashPhase: boolean;
    FBitmapNormal: TBitmap;
    FBitmapFlash: TBitmap;
    procedure UpdateCaption;
    procedure RenderScreen;
    procedure RenderBothPhases;
    procedure SetZoom(NewZoom: integer);
  public
    destructor Destroy; override;
    procedure LoadScreenFile(DiskImage: TDSKDisk; DiskFile: TCPMFile; const DiskName: string);
    property DiskName: string read FDiskName write FDiskName;
    property FileName: string read FFileName write FFileName;
  end;

procedure ShowScreenViewer(DiskImage: TDSKDisk; DiskFile: TCPMFile; const DiskName: string);

implementation

{$R *.lfm}

procedure ShowScreenViewer(DiskImage: TDSKDisk; DiskFile: TCPMFile; const DiskName: string);
var
  Viewer: TfrmGraphicsFileViewer;
begin
  Viewer := TfrmGraphicsFileViewer.Create(Application);
  Viewer.LoadScreenFile(DiskImage, DiskFile, DiskName);
  Viewer.Show;
  Viewer.SetZoom(2);
end;

procedure TfrmGraphicsFileViewer.FormCreate(Sender: TObject);
begin
  FDiskName := '';
  FFileName := '';
  FHasFlash := False;
  FFlashPhase := False;
  SetLength(FScreenData, 0);

  // Create bitmaps for flash animation
  FBitmapNormal := TBitmap.Create;
  FBitmapFlash := TBitmap.Create;
end;

destructor TfrmGraphicsFileViewer.Destroy;
begin
  tmrFlash.Enabled := False;
  FBitmapNormal.Free;
  FBitmapFlash.Free;
  inherited Destroy;
end;

procedure TfrmGraphicsFileViewer.UpdateCaption;
begin
  Caption := Format('%s on %s x%d', [FFileName, FDiskName, FZoom])
end;

procedure TfrmGraphicsFileViewer.SetZoom(NewZoom: integer);
begin
  if NewZoom = FZoom then Exit;

  FZoom := NewZoom;

  UpdateCaption;

  // Re-render both phases at new zoom level
  if FHasFlash then
    RenderBothPhases
  else
    RenderScreen;

  tckZoom.Position := FZoom;
end;

procedure TfrmGraphicsFileViewer.RenderBothPhases;
var
  NewWidth, NewHeight: integer;
begin
  if Length(FScreenData) = 0 then Exit;

  NewWidth := ScreenWidth * FZoom;
  NewHeight := ScreenHeight * FZoom;

  // Render normal phase
  FBitmapNormal.Width := NewWidth;
  FBitmapNormal.Height := NewHeight;
  FBitmapNormal.PixelFormat := pf24bit;
  TSpectrumScreen.RenderToBitmap(FScreenData, FBitmapNormal, FZoom, False);

  // Render flash phase (with ink/paper swapped on flash attributes)
  FBitmapFlash.Width := NewWidth;
  FBitmapFlash.Height := NewHeight;
  FBitmapFlash.PixelFormat := pf24bit;
  TSpectrumScreen.RenderToBitmap(FScreenData, FBitmapFlash, FZoom, True);

  // Show the current phase
  if FFlashPhase then
    imgScreen.Picture.Assign(FBitmapFlash)
  else
    imgScreen.Picture.Assign(FBitmapNormal);

  // Update image and form size
  imgScreen.Width := NewWidth;
  imgScreen.Height := NewHeight;
  ClientWidth := NewWidth;
  ClientHeight := NewHeight + toolbar.Height;
end;

procedure TfrmGraphicsFileViewer.RenderScreen;
var
  NewWidth, NewHeight: integer;
begin
  if Length(FScreenData) = 0 then Exit;

  NewWidth := ScreenWidth * FZoom;
  NewHeight := ScreenHeight * FZoom;

  // Create bitmap with correct size
  imgScreen.Picture.Bitmap.Width := NewWidth;
  imgScreen.Picture.Bitmap.Height := NewHeight;
  imgScreen.Picture.Bitmap.PixelFormat := pf24bit;

  // Render the screen (no flash phase for non-flashing screens)
  TSpectrumScreen.RenderToBitmap(FScreenData, imgScreen.Picture.Bitmap, FZoom, False);

  // Update image size
  imgScreen.Width := NewWidth;
  imgScreen.Height := NewHeight;

  // Update form size to fit content
  ClientWidth := NewWidth;
  ClientHeight := NewHeight + toolbar.Height;
end;

procedure TfrmGraphicsFileViewer.LoadScreenFile(DiskImage: TDSKDisk;
  DiskFile: TCPMFile; const DiskName: string);
var
  FileData: TDiskByteArray;
  DataSize: integer;
begin
  FDiskName := DiskName;
  FFileName := DiskFile.FileName;

  // Get file data without header
  FileData := DiskFile.GetData(False);
  DataSize := Length(FileData);

  // Validate screen size
  if not TSpectrumScreen.IsValidScreenSize(DataSize) then
  begin
    Caption := 'Invalid screen file';
    Exit;
  end;

  // Copy data
  SetLength(FScreenData, DataSize);
  Move(FileData[0], FScreenData[0], DataSize);

  // Check for flash attributes
  FHasFlash := TSpectrumScreen.HasFlashAttribute(FScreenData);
  FFlashPhase := False;

  // Enable timer only if flash attributes are present
  tmrFlash.Enabled := FHasFlash;

  SetZoom(2);
end;

procedure TfrmGraphicsFileViewer.tckZoomChange(Sender: TObject);
begin
  SetZoom(tckZoom.Position);
end;

procedure TfrmGraphicsFileViewer.tmrFlashTimer(Sender: TObject);
begin
  // Toggle flash phase
  FFlashPhase := not FFlashPhase;

  // Swap displayed bitmap
  if FFlashPhase then
    imgScreen.Picture.Assign(FBitmapFlash)
  else
    imgScreen.Picture.Assign(FBitmapNormal);
end;

end.
