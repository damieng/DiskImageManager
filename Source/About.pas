unit About;

{
  Disk Image Manager -  Copyright 2002-2009 Envy Technologies Ltd.

  About window
}

interface

uses
  Windows, Controls, Forms, ExtCtrls, StdCtrls, Graphics, Classes, SysUtils, ShellApi;

type
  TfrmAbout = class(TForm)
    btnOK: TButton;
    imgAppIcon: TImage;
    lblTitle: TLabel;
    bvLine: TBevel;
    lblVersion: TLabel;
    timFade: TTimer;
    lblWeb: TLabel;
    lblEmail: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure lblWebClick(Sender: TObject);
    procedure timFadeTimer(Sender: TObject);
  end;

var
  frmAbout: TfrmAbout;

function GetAppVersion: String;

implementation

uses
  Main;

{$R *.dfm}

function GetAppVersion: String;
var
  Size, Size2: DWord;
  Pt, Pt2: Pointer;
begin
  Size := GetFileVersionInfoSize(PChar(ParamStr(0)),Size2);
  if (Size > 0) then
  begin
  	GetMem(Pt,Size);
    try
    	GetFileVersionInfo(PChar(ParamStr(0)),0,Size,Pt);
      VerQueryValue(Pt,'\',Pt2,Size2);
      with TVSFixedFileInfo(Pt2^) do
      begin
      	Result := Format('%d.%d.%d.%d', [HiWord(dwFileVersionMS),LoWord(dwFileVersionMS),
                 	HiWord(dwFileVersionLS),LoWord(dwFileVersionLS)]);
      end;
    finally
    	FreeMem(Pt);
    end;
  end;
end;

procedure TfrmAbout.FormCreate(Sender: TObject);
begin
  Caption := 'About ' + Application.Title;
  lblTitle.Caption := Application.Title;
  lblVersion.Caption := 'Version: ' + GetAppVersion;
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
	ShellExecute(Application.Handle,'open',PChar(TLabel(Sender).Hint),nil,nil,0);
end;

procedure TfrmAbout.btnOKClick(Sender: TObject);
begin
  timFade.Tag := -4;
  timFade.Enabled := True;
end;

end.
