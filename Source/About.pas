unit About;

{$MODE Delphi}

{
  Disk Image Manager -  About window

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  LCLIntf, Forms, ExtCtrls, StdCtrls, Graphics;

type
  TfrmAbout = class(TForm)
    btnOK: TButton;
    imgAppIcon: TImage;
    lblTitle: TLabel;
    bvLine: TBevel;
    lblVersion: TLabel;
    timFade: TTimer;
    lblWeb: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure lblWebClick(Sender: TObject);
    procedure timFadeTimer(Sender: TObject);
  end;

var
  frmAbout: TfrmAbout;

implementation

uses
  Main;

{$R *.lfm}

procedure TfrmAbout.FormCreate(Sender: TObject);
begin
  Caption := 'About ' + Application.Title;
  lblTitle.Caption := Application.Title;
  lblVersion.Caption := 'Compiled: ' + {$I %DATE%} + ' ' + {$I %TIME%};
end;

procedure TfrmAbout.timFadeTimer(Sender: TObject);
begin
  if (timFade.Tag > 0) then
    if (frmAbout.AlphaBlendValue < 250) then
      frmAbout.AlphaBlendValue := frmAbout.AlphaBlendValue + timFade.Tag
    else
    begin
      timFade.Enabled := False;
      frmAbout.AlphaBlendValue := 255;
    end
  else
  if (frmAbout.AlphaBlendValue > 5) then
    frmAbout.AlphaBlendValue := frmAbout.AlphaBlendValue + timFade.Tag
  else
  begin
    timFade.Enabled := False;
    frmAbout.AlphaBlendValue := 0;
    Close;
  end;
end;

procedure TfrmAbout.FormShow(Sender: TObject);
begin
  frmAbout.Font := frmMain.Font;
  frmAbout.AlphaBlendValue := 0;
  lblVersion.Font.Color := clBtnShadow;
  timFade.Tag := 4;
  timFade.Enabled := True;
end;

procedure TfrmAbout.lblWebClick(Sender: TObject);
begin
  OpenDocument(PChar(TLabel(Sender).Caption));
end;

procedure TfrmAbout.btnOKClick(Sender: TObject);
begin
  timFade.Tag := -4;
  timFade.Enabled := True;
end;

end.