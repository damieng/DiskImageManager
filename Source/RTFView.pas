unit RTFView;

{$MODE Delphi}

{
  Disk Image Manager - Minimal RichEdit viewer wrapper

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  Windows, Classes;

type
  TRTFViewer = class
  private
    class var FLibHandle: HMODULE;
    class procedure LoadRichEditLib;
  private
    FHandle: HWND;
  public
    constructor Create(AParentHandle: HWND);
    destructor Destroy; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: integer);
    procedure LoadRTF(const RTFContent: AnsiString);
    property Handle: HWND read FHandle;
  end;

implementation

type
  TSetTextEx = record
    flags: DWORD;
    codepage: UINT;
  end;

const
  EM_SETTEXTEX = WM_USER + 97;
  ST_DEFAULT = 0;
  CP_ACP = 0;

class procedure TRTFViewer.LoadRichEditLib;
begin
  if FLibHandle = 0 then
    FLibHandle := LoadLibrary('riched20.dll');
end;

constructor TRTFViewer.Create(AParentHandle: HWND);
begin
  inherited Create;
  LoadRichEditLib;
  FHandle := CreateWindowExW(
    WS_EX_CLIENTEDGE,
    'RICHEDIT20W',
    nil,
    WS_CHILD or WS_VISIBLE or WS_VSCROLL
      or ES_MULTILINE or ES_READONLY,
    0, 0, 100, 100,
    AParentHandle,
    0,
    HInstance,
    nil
  );
end;

destructor TRTFViewer.Destroy;
begin
  if FHandle <> 0 then
    DestroyWindow(FHandle);
  inherited;
end;

procedure TRTFViewer.SetBounds(ALeft, ATop, AWidth, AHeight: integer);
begin
  if FHandle <> 0 then
    MoveWindow(FHandle, ALeft, ATop, AWidth, AHeight, True);
end;

procedure TRTFViewer.LoadRTF(const RTFContent: AnsiString);
var
  STE: TSetTextEx;
begin
  if FHandle = 0 then
    Exit;

  // Temporarily remove ES_READONLY so we can set text
  SetWindowLongW(FHandle, GWL_STYLE,
    GetWindowLongW(FHandle, GWL_STYLE) and not ES_READONLY);

  STE.flags := ST_DEFAULT;
  STE.codepage := CP_ACP;
  Windows.SendMessageA(FHandle, EM_SETTEXTEX,
    WPARAM(@STE), LPARAM(PAnsiChar(RTFContent)));

  // Restore ES_READONLY
  SetWindowLongW(FHandle, GWL_STYLE,
    GetWindowLongW(FHandle, GWL_STYLE) or ES_READONLY);
end;

end.
