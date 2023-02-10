unit Main;

{$MODE Delphi}

{
  Disk Image Manager -  Main window

  Copyright (c) Damien Guard. All rights reserved.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
}

interface

uses
  DiskMap, DskImage, Utils, About, Options, SectorProperties, Settings, FileSystem,
  Classes, Graphics, SysUtils, Forms, Dialogs, Menus, ComCtrls, ExtCtrls, Controls,
  Clipbrd, StdCtrls, FileUtil, StrUtils, LazFileUtils, LConvEncoding;

type
  // Must match the imagelist, put sides last
  ItemType = (itDisk, itSpecification, itTracksAll, itTrack, itFiles, itSector,
    itAnalyse, itSides, itSide0, itSide1, itDiskCorrupt, itMessages, itStrings);

  TListColumnArray = array of TListColumn;

  { TfrmMain }

  TfrmMain = class(TForm)
    itmOpenRecent: TMenuItem;
    memo: TMemo;
    mnuMain: TMainMenu;
    itmDisk: TMenuItem;
    itmOpen: TMenuItem;
    itmNew: TMenuItem;
    N1: TMenuItem;
    itmSaveCopyAs: TMenuItem;
    N2: TMenuItem;
    itmExit: TMenuItem;
    itmView: TMenuItem;
    itmHelp: TMenuItem;
    itmAbout: TMenuItem;
    dlgOpen: TOpenDialog;
    pnlLeft: TPanel;
    splVertical: TSplitter;
    staBar: TStatusBar;
    pnlRight: TPanel;
    pnlListLabel: TPanel;
    tvwMain: TTreeView;
    lvwMain: TListView;
    imlSmall: TImageList;
    pnlTreeLabel: TPanel;
    N4: TMenuItem;
    itmClose: TMenuItem;
    itmOptions: TMenuItem;
    DiskMap: TSpinDiskMap;
    itmCloseAll: TMenuItem;
    dlgSave: TSaveDialog;
    popDiskMap: TPopupMenu;
    itmSaveMapAs: TMenuItem;
    dlgSaveMap: TSaveDialog;
    itmDarkBlankSectorsPop: TMenuItem;
    itmStatusBar: TMenuItem;
    N3: TMenuItem;
    N5: TMenuItem;
    itmDarkUnusedSectors: TMenuItem;
    itmSave: TMenuItem;
    popSector: TPopupMenu;
    itmSectorResetFDC: TMenuItem;
    itmSectorBlankData: TMenuItem;
    itmSectorUnformat: TMenuItem;
    N6: TMenuItem;
    itmSectorProperties: TMenuItem;
    itmEdit: TMenuItem;
    itmEditCopy: TMenuItem;
    itmEditSelectAll: TMenuItem;
    popListItem: TPopupMenu;
    itmCopyDetailsClipboard: TMenuItem;
    N7: TMenuItem;
    itmFind: TMenuItem;
    itmFindNext: TMenuItem;
    dlgFind: TFindDialog;
    procedure itmOpenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure itmOpenRecentClick(Sender: TObject);
    procedure lvwMainDblClickFile(Sender: TObject);
    procedure tvwMainChange(Sender: TObject; Node: TTreeNode);
    procedure itmAboutClick(Sender: TObject);
    procedure itmCloseClick(Sender: TObject);
    procedure itmExitClick(Sender: TObject);
    procedure itmOptionsClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure itmCloseAllClick(Sender: TObject);
    procedure itmSaveCopyAsClick(Sender: TObject);
    procedure itmSaveMapAsClick(Sender: TObject);
    procedure itmDarkBlankSectorsPopClick(Sender: TObject);
    procedure popDiskMapPopup(Sender: TObject);
    procedure itmNewClick(Sender: TObject);
    procedure itmDarkUnusedSectorsClick(Sender: TObject);
    procedure itmStatusBarClick(Sender: TObject);
    procedure itmSaveClick(Sender: TObject);
    procedure itmSectorResetFDCClick(Sender: TObject);
    procedure itmSectorBlankDataClick(Sender: TObject);
    procedure itmSectorUnformatClick(Sender: TObject);
    procedure itmSectorPropertiesClick(Sender: TObject);
    procedure itmEditCopyClick(Sender: TObject);
    procedure itmEditSelectAllClick(Sender: TObject);
    procedure itmFindClick(Sender: TObject);
    procedure dlgFindFind(Sender: TObject);
    procedure itmFindNextClick(Sender: TObject);
    procedure tvwMainDblClick(Sender: TObject);
  private
    NextNewFile: integer;
    function AddTree(Parent: TTreeNode; Text: string; ImageIdx: integer; NodeObject: TObject): TTreeNode;
    function AddListInfo(Key: string; Value: string): TListItem;
    function AddListTrack(Track: TDSKTrack): TListItem;
    function AddListSector(Sector: TDSKSector): TListItem;
    function AddListSides(Side: TDSKSide): TListItem;
    procedure SetListSimple;
    function GetSelectedSector(Sender: TObject): TDSKSector;
    function GetTitle(Data: TTreeNode): string;
    function GetCurrentImage: TDSKImage;
    function IsDiskNode(Node: TTreeNode): boolean;
    function AddColumn(Caption: string): TListColumn;
    function AddColumns(Captions: array of string): TListColumnArray;
    function FindTreeNodeFromData(Node: TTreeNode; Data: TObject): TTreeNode;
    procedure OnApplicationDropFiles(Sender: TObject; const FileNames: array of string);
    procedure UpdateRecentFilesMenu;
  public
    Settings: TSettings;

    procedure AddWorkspaceImage(Image: TDSKImage);
    function CloseAll(AllowCancel: boolean): boolean;
    function ConfirmChange(Action: string; Upon: string): boolean;

    procedure SaveImage(Image: TDSKImage);
    procedure SaveImageAs(Image: TDSKImage; Copy: boolean);

    procedure AnalyseMap(Side: TDSKSide);
    procedure RefreshList;
    procedure RefreshStrings(Disk: TDSKDisk);
    procedure RefreshListFiles(FileSystem: TDSKFileSystem);
    procedure RefreshListImage(Image: TDSKImage);
    procedure RefreshListMessages(Messages: TStringList);
    procedure RefreshListTrack(Side: TDSKSide);
    procedure RefreshListSector(Track: TDSKTrack);
    procedure RefreshListSectorData(Sector: TDSKSector);
    procedure RefreshListSpecification(Specification: TDSKSpecification);
    procedure UpdateMenus;

    function LoadImage(FileName: TFileName): boolean;
    procedure CloseImage(Image: TDSKImage);
    function GetNextNewFile: integer;
  end;

const
  TAB = #9;
  CR = #13;
  LF = #10;
  CRLF = CR + LF;

var
  frmMain: TfrmMain;

function GetListViewAsText(ForListView: TListView): string;

implementation

{$R *.lfm}

uses New;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Idx: integer;
  FileName: string;
begin
  Settings := TSettings.Create(self);
  Settings.Load;

  NextNewFile := 0;
  Caption := Application.Title;
  itmAbout.Caption := 'About ' + Application.Title;
  itmDarkUnusedSectors.Checked := DiskMap.DarkBlankSectors;

  tvwMain.BeginUpdate;
  for Idx := 1 to ParamCount do
  begin
    FileName := ParamStr(Idx);
    if (ExtractFileExt(FileName) = '.dsk') and (FileExistsUTF8(FileName)) then
      LoadImage(FileName);
  end;
  tvwMain.EndUpdate;

  Application.AddOnDropFilesHandler(OnApplicationDropFiles);
  UpdateRecentFilesMenu;
end;

procedure TfrmMain.itmOpenRecentClick(Sender: TObject);
var
  FileName: string;
begin
  if Sender is TMenuItem then
  begin
    FileName := (Sender as TMenuItem).Caption;
    if FileExists(FileName) then
    begin
      LoadImage(FileName);
      Settings.AddRecentFile(FileName);
      UpdateRecentFilesMenu;
      Settings.Save();
    end
    else
    if MessageDlg('File does not exist', SysUtils.Format('Can not find file %s. Remove from recent list?', [FileName]),
      mtConfirmation, mbYesNo, 0) = mrYes then
      Settings.RecentFiles.Delete(Settings.RecentFiles.IndexOf(FileName));
  end;
end;

procedure TfrmMain.lvwMainDblClickFile(Sender: TObject);
var
  DiskFile: TDSKFile;
  FoundNode: TTreeNode;
begin
  // Jump to the first sector for this file
  DiskFile := TDSKFile((lvwMain.Selected).Data);
  FoundNode := FindTreeNodeFromData(tvwMain.Selected.Parent, DiskFile.FirstSector);
  if FoundNode <> nil then
    tvwMain.Selected := FoundNode;
end;

function TfrmMain.FindTreeNodeFromData(Node: TTreeNode; Data: TObject): TTreeNode;
var
  ChildNode, FoundInChildNode: TTreeNode;
begin
  Result := nil;
  if Node.HasChildren then
  begin
    ChildNode := Node.GetFirstChild;
    repeat
      if ChildNode.Data = Data then
      begin
        Result := ChildNode;
        exit;
      end;
      FoundInChildNode := FindTreeNodeFromData(ChildNode, Data);
      if FoundInChildNode <> nil then
      begin
        Result := FoundInChildNode;
        exit;
      end;
      ChildNode := Node.GetNextChild(ChildNode);
    until ChildNode = nil;
  end;
end;

procedure TfrmMain.UpdateRecentFilesMenu;
var
  MenuItem: TMenuItem;
  RecentFile: string;
begin
  itmOpenRecent.Clear;
  for RecentFile in Settings.RecentFiles do
  begin
    MenuItem := TMenuItem.Create(itmOpenRecent);
    MenuItem.OnClick := itmOpenRecentClick;
    MenuItem.Caption := RecentFile;
    itmOpenRecent.Add(MenuItem);
  end;
end;

procedure TfrmMain.itmOpenClick(Sender: TObject);
var
  Idx: integer;
  FileName: string;
begin
  if dlgOpen.Execute then
    for Idx := 0 to dlgOpen.Files.Count - 1 do
    begin
      FileName := dlgOpen.Files[Idx];
      LoadImage(FileName);
      Settings.AddRecentFile(FileName);
      UpdateRecentFilesMenu;
      Settings.Save();
    end;
end;

function TfrmMain.LoadImage(FileName: TFileName): boolean;
var
  NewImage: TDSKImage;
begin
  NewImage := TDSKImage.Create;
  if NewImage.LoadFile(FileName) then
  begin
    AddWorkspaceImage(NewImage);
    Result := True;
  end
  else
  begin
    NewImage.Free;
    Result := False;
  end;
end;

procedure TfrmMain.AddWorkspaceImage(Image: TDSKImage);
var
  SIdx, TIdx, EIdx: integer;
  ImageNode, SideNode, TrackNode, TracksNode, SpecsNode, SectorNode, MapNode: TTreeNode;
begin
  SideNode := nil;
  tvwMain.Items.BeginUpdate;

  if Image.Corrupt then
    ImageNode := AddTree(nil, ExtractFileName(Image.FileName), Ord(itDiskCorrupt), Image)
  else
    ImageNode := AddTree(nil, ExtractFileName(Image.FileName), Ord(itDisk), Image);

  tvwMain.Selected := ImageNode;

  if Image.Disk.Sides > 0 then
  begin
    // Optional specification
    Image.Disk.Specification.Read;
    if Image.Disk.Specification.Format <> dsFormatInvalid then
    begin
      SpecsNode := AddTree(ImageNode, 'Specification', Ord(itSpecification), Image.Disk.Specification);
      if Settings.OpenView = 'Specification' then
        tvwMain.Selected := SpecsNode;
    end;

    // Add the sides
    for SIdx := 0 to Image.Disk.Sides - 1 do
    begin
      SideNode := AddTree(ImageNode, Format('Side %d', [SIdx + 1]), Ord(itSide0) + SIdx, Image.Disk.Side[SIdx]);
      if (SIdx = 0) and (Settings.OpenView = 'Track list') then
        tvwMain.Selected := SideNode;

      MapNode := AddTree(SideNode, 'Map', Ord(itAnalyse), Image.Disk.Side[SIdx]);
      if (SIdx = 0) and (Settings.OpenView = 'Map') then
        tvwMain.Selected := MapNode;

      // Add the tracks
      TracksNode := AddTree(SideNode, 'Tracks', Ord(itTracksAll), Image.Disk.Side[SIdx]);
      with Image.Disk.Side[SIdx] do
        for TIdx := 0 to Tracks - 1 do
        begin
          TrackNode := AddTree(TracksNode, Format('Track %d', [TIdx]), Ord(itTrack), Track[TIdx]);
          if (SIdx = 0) and (TIdx = 0) and (Settings.OpenView = 'First track') then
            tvwMain.Selected := TrackNode;

          // Add the sectors
          with Image.Disk.Side[SIdx].Track[TIdx] do
            for EIdx := 0 to Sectors - 1 do
            begin
              SectorNode := AddTree(TrackNode, SysUtils.Format('Sector %d', [EIdx]), Ord(itSector), Sector[EIdx]);
              if (SIdx = 0) and (TIdx = 0) and (EIdx = 0) and (Settings.OpenView = 'First sector') then
                tvwMain.Selected := SectorNode;
            end;
        end;
    end;

    AddTree(ImageNode, 'Files', Ord(itFiles), TDSKFileSystem.Create(Image.Disk));
    AddTree(ImageNode, 'Strings', Ord(itStrings), Image.Disk);

    if Image.Messages.Count > 0 then
      AddTree(ImageNode, 'Messages', Ord(itMessages), Image.Messages);
  end;
  tvwMain.Items.EndUpdate;

  ImageNode.Expanded := True;
  if (Image.Disk.Sides = 1) and (SideNode <> nil) then
    SideNode.Expanded := True;
end;

function TfrmMain.AddTree(Parent: TTreeNode; Text: string; ImageIdx: integer; NodeObject: TObject): TTreeNode;
var
  NewTreeNode: TTreeNode;
begin
  NewTreeNode := tvwMain.Items.AddChild(Parent, Text);
  with NewTreeNode do
  begin
    ImageIndex := ImageIdx;
    SelectedIndex := ImageIdx;
    Data := NodeObject;
  end;
  Result := NewTreeNode;
end;

procedure TfrmMain.tvwMainChange(Sender: TObject; Node: TTreeNode);
begin
  UpdateMenus;
end;

procedure TfrmMain.UpdateMenus;
var
  AllowImageFile: boolean;
  ObjectData: TObject;
begin
  AllowImageFile := False;
  tvwMain.PopupMenu := nil;

  // Decide what class operating on
  if (tvwMain.Selected <> nil) and (tvwMain.Selected.Data <> nil) then
  begin
    AllowImageFile := True;
    ObjectData := TObject(tvwMain.Selected.Data);
    if (ObjectData.ClassType = TDSKSector) or (ObjectData.ClassType = TDSKTrack) then
      tvwMain.PopupMenu := popSector;
    if ItemType(tvwMain.Selected.ImageIndex) = itAnalyse then
      tvwMain.PopupMenu := popDiskMap;
  end;

  // Set main menu options
  itmClose.Enabled := AllowImageFile;
  itmSave.Enabled := AllowImageFile;
  itmSaveCopyAs.Enabled := AllowImageFile;

  // Hide disk map if no longer selected
  if (lvwMain.Selected = nil) and (DiskMap.Visible) then
  begin
    DiskMap.Visible := False;
    memo.Visible := False;
    lvwMain.Visible := True;
  end;

  RefreshList;
end;

function TfrmMain.GetTitle(Data: TTreeNode): string;
var
  CurNode: TTreeNode;
begin
  Result := '';
  CurNode := Data;
  while CurNode <> nil do
  begin
    if (CurNode.ImageIndex <> 2) or (CurNode = tvwMain.Selected) then
      Result := CurNode.Text + ' > ' + Result;
    CurNode := CurNode.Parent;
  end;
  Result := Copy(Result, 0, Length(Result) - 3);
end;

procedure TfrmMain.RefreshList;
var
  OldViewStyle: TViewStyle;
begin
  with lvwMain do
  begin
    PopupMenu := popListItem;
    OldViewStyle := ViewStyle;
    Items.BeginUpdate;
    ViewStyle := vsList;
    Items.Clear;
    Columns.BeginUpdate;
    Columns.Clear;

    ParentFont := True;
    ShowColumnHeaders := True;

    if tvwMain.Selected <> nil then
      with tvwMain.Selected do
      begin
        pnlListLabel.Caption := ' ' + AnsiReplaceStr(GetTitle(tvwMain.Selected), '&', '&&');
        lvwMain.Visible := (ItemType(ImageIndex) <> itAnalyse) and (Caption <> 'Strings');
        DiskMap.Visible := ItemType(ImageIndex) = itAnalyse;
        memo.Visible := Caption = 'Strings';
        OnDblClick := nil;
        if Data <> nil then
        begin
          case ItemType(ImageIndex) of
            itDisk: RefreshListImage(Data);
            itDiskCorrupt: RefreshListImage(Data);
            itSpecification: RefreshListSpecification(Data);
            itTracksAll: RefreshListTrack(Data);
            itTrack: RefreshListSector(Data);
            itAnalyse: AnalyseMap(Data);
            itFiles: RefreshListFiles(Data);
            itStrings: RefreshStrings(Data);
            itMessages: RefreshListMessages(Data);
            else
              if TObject(Data).ClassType = TDSKSide then
                RefreshListTrack(TDSKSide(Data));
              if TObject(Data).ClassType = TDSKSector then
                RefreshListSectorData(TDSKSector(Data));
          end;
        end;
      end
    else
      pnlListLabel.Caption := '';
    ViewStyle := OldViewStyle;
    Columns.EndUpdate;
    Items.EndUpdate;
  end;
end;

procedure TfrmMain.RefreshListMessages(Messages: TStringList);
var
  Message: string;
begin
  SetListSimple;
  if Messages <> nil then
    for Message in Messages do
      AddListInfo('', Message);
end;

procedure TfrmMain.RefreshListImage(Image: TDSKImage);
var
  SIdx: integer;
  Protection: string;
begin
  SetListSimple;
  if Image <> nil then
    with Image do
    begin
      AddListInfo('Creator', Creator);
      if Corrupt then
        AddListInfo('Image Format', DSKImageFormats[FileFormat] + ' (Corrupt)')
      else
        AddListInfo('Image Format', DSKImageFormats[FileFormat]);
      AddListInfo('Sides', StrInt(Disk.Sides));
      if Disk.Sides > 0 then
      begin
        if Disk.Sides > 1 then
        begin
          for SIdx := 0 to Disk.Sides - 1 do
            AddListInfo(SysUtils.Format('Tracks on side %d', [SIdx]),
              StrInt(Disk.Side[SIdx].Tracks));
        end;
        AddListInfo('Tracks total', StrInt(Disk.TrackTotal));
        AddListInfo('Formatted capacity', SysUtils.Format('%d KB', [Disk.FormattedCapacity div BytesPerKB]));
        if Disk.IsTrackSizeUniform then
          AddListInfo('Track size', SysUtils.Format('%d bytes', [Disk.Side[0].Track[0].Size]))
        else
          AddListInfo('Largest track size', SysUtils.Format('%d bytes', [Disk.Side[0].GetLargestTrackSize()]));
        if Disk.IsUniform(False) then
          AddListInfo('Uniform layout', 'Yes')
        else
        if Disk.IsUniform(True) then
          AddListInfo('Uniform layout', 'Yes (except empty tracks)')
        else
          AddListInfo('Uniform layout', 'No');
        AddListInfo('Format analysis', Disk.DetectFormat);
        Protection := Disk.DetectCopyProtection();
        if Protection <> '' then
          AddListInfo('Copy protection', Protection);
        if Disk.BootableOn <> '' then
          AddListInfo('Boot sector', Disk.BootableOn);
        if disk.HasFDCErrors then
          AddListInfo('FDC errors', 'Yes')
        else
          AddListInfo('FDC errors', 'No');
        if IsChanged then
          AddListInfo('Is changed', 'Yes')
        else
        begin
          AddListInfo('Is changed', 'No');
          AddListInfo('File size',StrFileSize(FileSize));
        end;
      end;
    end;
end;

procedure TfrmMain.SetListSimple;
begin
  lvwMain.ShowColumnHeaders := False;
  with lvwMain.Columns do
  begin
    Clear;
    with Add do
    begin
      Caption := 'Key';
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'Value';
      AutoSize := True;
    end;
  end;
end;

procedure TfrmMain.RefreshListSpecification(Specification: TDSKSpecification);
begin
  SetListSimple;
  Specification.Read;
  AddListInfo('Format', DSKSpecFormats[Specification.Format]);
  if Specification.Format <> dsFormatInvalid then
  begin
    AddListInfo('Source', Specification.Source);
    AddListInfo('Sided', DSKSpecSides[Specification.Side]);
    AddListInfo('Track mode', DSKSpecTracks[Specification.Track]);
    AddListInfo('Tracks/side', StrInt(Specification.TracksPerSide));
    AddListInfo('Sectors/track', StrInt(Specification.SectorsPerTrack));
    AddListInfo('Directory blocks', StrInt(Specification.DirectoryBlocks));
    AddListInfo('Reserved tracks', StrInt(Specification.ReservedTracks));
    AddListInfo('Gap (format)', StrInt(Specification.GapFormat));
    AddListInfo('Gap (read/write)', StrInt(Specification.GapReadWrite));
    AddListInfo('Sector size', StrInt(Specification.SectorSize));
    AddListInfo('Block shift', StrInt(Specification.BlockShift));
    AddListInfo('Block size', StrInt(Specification.GetBlockSize));
    AddListInfo('Block count', StrInt(Specification.GetBlockCount));
    AddListInfo('Records per track', StrInt(Specification.GetRecordsPerTrack));
    AddListInfo('Usable capacity', StrFileSize(Specification.GetUsableCapacity));
  end;
end;

function TfrmMain.AddListInfo(Key: string; Value: string): TListItem;
var
  NewListItem: TListItem;
begin
  NewListItem := lvwMain.Items.Add;
  with NewListItem do
  begin
    Caption := Key;
    SubItems.Add(Value);
  end;
  Result := NewListItem;
end;

procedure TfrmMain.RefreshListTrack(Side: TDSKSide);
var
  Track: TDSKTrack;
begin
  AddColumn('Logical');
  AddColumn('Physical');
  AddColumn('Track size');
  AddColumn('Sectors');
  AddColumn('Sector size');
  AddColumn('Gap');
  AddColumn('Filler');
  AddColumn('');

  for Track in Side.Track do
    AddListTrack(Track);
end;

function TfrmMain.AddListTrack(Track: TDSKTrack): TListItem;
var
  NewListItem: TListItem;
begin
  NewListItem := lvwMain.Items.Add;
  with NewListItem do
  begin
    Caption := StrInt(Track.Logical);
    Data := Track;
    Subitems.Add(StrInt(Track.Track));
    Subitems.Add(StrInt(Track.Size));
    Subitems.Add(StrInt(Track.Sectors));
    Subitems.Add(StrInt(Track.SectorSize));
    Subitems.Add(StrInt(Track.GapLength));
    Subitems.Add(StrHex(Track.Filler));
    Subitems.Add('');
  end;
  Result := NewListItem;
end;

function TfrmMain.AddListSides(Side: TDSKSide): TListItem;
var
  NewListItem: TListItem;
begin
  NewListItem := lvwMain.Items.Add;
  with NewListItem do
  begin
    Caption := StrInt(Side.Side + 1);
    SubItems.Add(StrInt(Side.Tracks));
    Data := Side;
  end;
  Result := NewListItem;
end;

procedure TfrmMain.RefreshListSector(Track: TDSKTrack);
var
  Sector: TDSKSector;
begin
  lvwMain.PopupMenu := popSector;

  AddColumns(['Sector', 'Track', 'Side', 'ID', 'FDC size', 'FDC flags', 'Data size']);
  with lvwMain.Columns.Add do
  begin
    Caption := 'Status';
    AutoSize := True;
  end;

  for Sector in Track.Sector do
    AddListSector(Sector);
end;

function TfrmMain.AddListSector(Sector: TDSKSector): TListItem;
var
  NewListItem: TListItem;
begin
  NewListItem := lvwMain.Items.Add;
  with NewListItem do
  begin
    Caption := StrInt(Sector.Sector);
    Data := Sector;
    SubItems.Add(StrInt(Sector.Track));
    SubItems.Add(StrInt(Sector.Side));
    SubItems.Add(StrInt(Sector.ID));
    SubItems.Add(StrInt(Sector.FDCSize));
    SubItems.Add(Format('%d, %d', [Sector.FDCStatus[1], Sector.FDCStatus[2]]));
    if (Sector.DataSize <> Sector.AdvertisedSize) then
      SubItems.Add(Format('%d (%d)', [Sector.DataSize, Sector.AdvertisedSize]))
    else
      SubItems.Add(StrInt(Sector.DataSize));
    SubItems.Add(DSKSectorStatus[Sector.Status]);
  end;
  Result := NewListItem;
end;

procedure TfrmMain.RefreshListSectorData(Sector: TDSKSector);
var
  Idx: integer;
  Raw: byte;
  SecData, SecHex, NextChar: string;
begin
  SecData := '';
  SecHex := '';
  lvwMain.Font := Settings.SectorFont;

  with lvwMain.Columns do
  begin
    BeginUpdate;
    Clear;
    with Add do
    begin
      Caption := 'Off';
      Alignment := taRightJustify;
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'Hex';
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'ASCII';
      AutoSize := True;
    end;
  end;

  for Idx := 0 to Sector.DataSize do
  begin
    if (Idx mod Settings.BytesPerLine = 0) and (Idx > 0) then
    begin
      with lvwMain.Items.Add do
      begin
        Caption := StrInt(Idx - Settings.BytesPerLine);
        Subitems.Add(SecHex);
        Subitems.Add(SecData);
      end;
      SecData := '';
      SecHex := '';
    end;

    if Idx < Sector.DataSize then
    begin
      Raw := Sector.Data[Idx];

      NextChar := Chr(Raw);
      if (Settings.Mapping = 'None') and (Raw > 127) then NextChar := Settings.UnknownASCII;
      if (Settings.Mapping = '437') then NextChar := CP437ToUTF8(NextChar);
      if (Settings.Mapping = '850') then NextChar := CP850ToUTF8(NextChar);
      if (Settings.Mapping = '1252') then NextChar := CP1252ToUTF8(NextChar);

      if Raw <= 31 then
        SecData := SecData + Settings.UnknownASCII
      else
        SecData := SecData + NextChar;
    end;

    SecHex := SecHex + StrHex(Raw) + ' ';
  end;
end;

// Menu: Help > About
procedure TfrmMain.itmAboutClick(Sender: TObject);
begin
  frmAbout := TfrmAbout.Create(Self);
  frmAbout.ShowModal;
  frmAbout.Free;
end;

// Find a disk image and remove it from the tree
procedure TfrmMain.CloseImage(Image: TDSKImage);
var
  Previous, Current: TTreeNode;
begin
  Previous := nil;
  for Current in tvwMain.Items do
  begin
    if IsDiskNode(Current) then
    begin
      if Current.Data = Image then
      begin
        TDSKImage(Current.Data).Free;
        Current.Delete;
        if tvwMain.Selected = nil then
          if Previous <> nil then
            Previous.Selected := True
          else
          if tvwMain.Items.Count > 0 then
            tvwMain.Items[0].Selected := True;
        exit;
      end;
      Previous := Current;
    end;
  end;
end;

// Get the current image
function TfrmMain.GetCurrentImage: TDSKImage;
var
  Node: TTreeNode;
begin
  Result := nil;
  Node := tvwMain.Selected;
  if (Node = nil) then
    exit;

  while (TObject(Node.Data).ClassType <> TDskImage) do
    Node := Node.Parent;

  Result := TDskImage(Node.Data);
end;

procedure TfrmMain.itmCloseClick(Sender: TObject);
begin
  if (tvwMain.Selected <> nil) then
    CloseImage(GetCurrentImage);
  Settings.Save();
end;

procedure TfrmMain.itmExitClick(Sender: TObject);
begin
  Close;
end;

// Show the disk map
procedure TfrmMain.AnalyseMap(Side: TDSKSide);
begin
  lvwMain.Visible := False;
  DiskMap.Side := Side;
  DiskMap.Visible := True;
end;

// Load list with filenames
procedure TfrmMain.RefreshListFiles(FileSystem: TDSKFileSystem);
var
  DiskFile: TDSKFile;
  Attributes: string;
begin
  with lvwMain.Columns do
  begin
    with Add do
    begin
      Caption := 'File name';
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'Blocks';
      Alignment := taRightJustify;
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'Allocated';
      Alignment := taRightJustify;
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'Actual';
      Alignment := taRightJustify;
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'Attributes';
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'Header';
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'Checksum';
      AutoSize := True;
    end;
    with Add do
    begin
      Caption := 'Meta';
      AutoSize := True;
    end;
  end;

  with lvwMain do
  begin
    BeginUpdate;
    Items.Clear;
    for DiskFile in FileSystem.Directory do
      with Items.Add do
      begin
        Data := DiskFile;
        if DiskFile.User <> 0 then
          Caption := StrInt(DiskFile.User) + ':' + DiskFile.FileName
        else
          Caption := DiskFile.FileName;
        SubItems.Add(StrInt(DiskFile.Blocks.Count));
        SubItems.Add(StrFileSize(DiskFile.SizeOnDisk));
        SubItems.Add(StrFileSize(DiskFile.Size));
        Attributes := '';
        if (DiskFile.ReadOnly) then Attributes := Attributes + 'R';
        if (DiskFile.System) then Attributes := Attributes + 'S';
        if (DiskFile.Archived) then Attributes := Attributes + 'A';
        SubItems.Add(Attributes);
        SubItems.Add(DiskFile.HeaderType);
        SubItems.Add(StrYesNo(DiskFile.Checksum));
        SubItems.Add(DiskFile.Meta);
      end;
    EndUpdate;
    OnDblClick := lvwMainDblClickFile;
  end;
end;

procedure TfrmMain.RefreshStrings(Disk: TDSKDisk);
var
  Idx: integer;
  Strings: TStringList;
begin
  Strings := Disk.GetAllStrings(4, 4);
  memo.Clear;
  lvwMain.Hide;
  for Idx := 0 to Strings.Count - 1 do
    memo.Lines.Append(Strings[Idx]);
  memo.Show;
end;

// Menu: View > Options
procedure TfrmMain.itmOptionsClick(Sender: TObject);
begin
  TfrmOptions.Create(self, Settings).Show;
  RefreshList;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Settings.Save;
  if CloseAll(True) then
    Action := caFree
  else
    Action := caNone;
end;

procedure TfrmMain.itmCloseAllClick(Sender: TObject);
begin
  CloseAll(True);
end;

function TfrmMain.IsDiskNode(Node: TTreeNode): boolean;
begin
  Result := (node.ImageIndex = Ord(itDisk)) or (node.ImageIndex = Ord(itDiskCorrupt));
end;

function TfrmMain.CloseAll(AllowCancel: boolean): boolean;
var
  Image: TDSKImage;
  Buttons: TMsgDlgButtons;
begin
  Result := True;
  if AllowCancel then
    Buttons := [mbYes, mbNo, mbCancel]
  else
    Buttons := [mbYes, mbNo];

  tvwMain.BeginUpdate;
  while tvwMain.Items.GetFirstNode <> nil do
  begin
    if IsDiskNode(tvwMain.Items.GetFirstNode) then
    begin
      Image := TDSKImage(tvwMain.Items.GetFirstNode.Data);
      if Image.IsChanged and not Image.Corrupt then
        case MessageDlg(Format('Save unsaved image "%s" ?', [Image.FileName]), mtWarning, Buttons, 0) of
          mrYes: SaveImage(Image);
          mrCancel:
          begin
            Result := False;
            exit;
          end;
        end;
      Image.Free;
      tvwMain.Items.GetFirstNode.Delete;
    end;
  end;
  tvwMain.EndUpdate;
  RefreshList;
  UpdateMenus;
end;

procedure TfrmMain.itmSaveCopyAsClick(Sender: TObject);
begin
  if tvwMain.Selected <> nil then
    SaveImageAs(GetCurrentImage, True);
end;

procedure TfrmMain.SaveImageAs(Image: TDSKImage; Copy: boolean);
begin
  dlgSave.FileName := Image.FileName;
  case Image.FileFormat of
    diStandardDSK: dlgSave.FilterIndex := 1;
    diExtendedDSK: dlgSave.FilterIndex := 2;
  end;

  if dlgSave.Execute then
    case dlgSave.FilterIndex of
      1:
      begin
        if (not Image.Disk.IsTrackSizeUniform) and Settings.WarnConversionProblems then
          if MessageDlg('This image has variable track sizes that "Standard DSK format" does not support. ' +
            'Save anyway using largest track size?', mtWarning, [mbYes, mbNo], 0) = mrOk then
            Image.SaveFile(dlgSave.FileName, diStandardDSK, True, False)
          else
            exit
        else
          Image.SaveFile(dlgSave.FileName, diStandardDSK, Copy, False);
      end;
      2: Image.SaveFile(dlgSave.FileName, diExtendedDSK, Copy, Settings.RemoveEmptyTracks);
    end;
end;

procedure TfrmMain.itmSaveMapAsClick(Sender: TObject);
var
  DefaultFileName: string;
begin
  DefaultFileName := DiskMap.Side.ParentDisk.ParentImage.FileName;
  if DiskMap.Side.Side > 0 then
    DefaultFileName := DefaultFileName + ' Side ' + StrInt(DiskMap.Side.Side);
  dlgSaveMap.FileName := ExtractFileNameOnly(DefaultFileName);
  if dlgSaveMap.Execute then
    DiskMap.SaveMap(dlgSaveMap.FileName, Settings.SaveDiskMapWidth,
      Settings.SaveDiskMapHeight);
end;

procedure TfrmMain.itmDarkBlankSectorsPopClick(Sender: TObject);
begin
  DiskMap.DarkBlankSectors := not itmDarkBlankSectorsPop.Checked;
  itmDarkBlankSectorsPop.Checked := DiskMap.DarkBlankSectors;
end;

procedure TfrmMain.popDiskMapPopup(Sender: TObject);
begin
  itmDarkBlankSectorsPop.Checked := DiskMap.DarkBlankSectors;
end;

procedure TfrmMain.itmNewClick(Sender: TObject);
begin
  TfrmNew.Create(Self).Show;
end;

function TfrmMain.GetNextNewFile: integer;
begin
  NextNewFile := NextNewFile + 1;
  Result := NextNewFile;
end;

procedure TfrmMain.itmDarkUnusedSectorsClick(Sender: TObject);
begin
  DiskMap.DarkBlankSectors := not itmDarkUnusedSectors.Checked;
  itmDarkUnusedSectors.Checked := DiskMap.DarkBlankSectors;
end;

procedure TfrmMain.itmStatusBarClick(Sender: TObject);
begin
  staBar.Visible := not itmStatusBar.Checked;
  itmStatusBar.Checked := staBar.Visible;
end;

procedure TfrmMain.itmSaveClick(Sender: TObject);
var
  selectedImage: TDSKImage;
  Node: TTreeNode;
begin
  Node := tvwMain.Selected;
  if Node <> nil then
  begin
    selectedImage := GetCurrentImage;
    SaveImage(selectedImage);
    while (TObject(Node.Data).ClassType <> TDskImage) do
      Node := Node.Parent;
    Node.Text := ExtractFileName(selectedImage.FileName);
  end;
end;

procedure TfrmMain.SaveImage(Image: TDSKImage);
begin
  if Image.FileFormat = diNotYetSaved then
    SaveImageAs(Image, False)
  else
    Image.SaveFile(Image.FileName, Image.FileFormat, False, (Settings.RemoveEmptyTracks and (Image.FileFormat = diExtendedDSK)));
  RefreshList();

end;

procedure TfrmMain.itmSectorResetFDCClick(Sender: TObject);
var
  Track: TDSKTrack;
  Sector: TDSKSector;
begin
  if tvwMain.Selected <> nil then
  begin
    if TObject(tvwMain.Selected.Data).ClassType = TDSKTrack then
      if ConfirmChange('reset FDC flags for', 'track') then
      begin
        Track := TDSKTrack(tvwMain.Selected.Data);
        for Sector in Track.Sector do
          Sector.ResetFDC;
      end;
    if (TObject(tvwMain.Selected.Data).ClassType = TDSKSector) then
      if ConfirmChange('reset FDC flags for', 'sector') then
        TDSKSector(tvwMain.Selected.Data).ResetFDC;
    UpdateMenus;
  end;
end;

function TfrmMain.GetSelectedSector(Sender: TObject): TDSKSector;
begin
  Result := nil;
  if (Sender = lvwMain) and (lvwMain.Selected <> nil) then
    Result := TDSKSector(lvwMain.Selected.Data);
end;

procedure TfrmMain.itmSectorBlankDataClick(Sender: TObject);
var
  Sector: TDSKSector;
begin
  Sector := GetSelectedSector(popSector.PopupComponent);
  if (Sector <> nil) and (ConfirmChange('format', 'sector')) then
  begin
    Sector.DataSize := Sector.ParentTrack.SectorSize;
    Sector.FillSector(Sector.ParentTrack.Filler);
    UpdateMenus;
  end;
end;

procedure TfrmMain.itmSectorUnformatClick(Sender: TObject);
begin
  if tvwMain.Selected = nil then exit;

  if TObject(tvwMain.Selected.Data).ClassType = TDSKTrack then
    if ConfirmChange('unformat', 'track') then
    begin
      TDSKTrack(tvwMain.Selected.Data).Unformat;
      tvwMain.Selected.DeleteChildren;
    end;
  if TObject(tvwMain.Selected.Data).ClassType = TDSKSector then
    if ConfirmChange('unformat', 'sector') then
      TDSKSector(tvwMain.Selected.Data).Unformat;
  UpdateMenus;
end;

procedure TfrmMain.itmSectorPropertiesClick(Sender: TObject);
var
  Track: TDSKTrack;
  Sector: TDSKSector;
begin
  if tvwMain.Selected = nil then exit;

  if TObject(tvwMain.Selected.Data).ClassType = TDSKTrack then
  begin
    Track := TDSKTrack(tvwMain.Selected.Data);
    for Sector in Track.Sector do
      TfrmSector.Create(Self, Sector);
  end;
  if TObject(tvwMain.Selected.Data).ClassType = TDSKSector then
    TfrmSector.Create(Self, TDSKSector(tvwMain.Selected.Data));
  UpdateMenus;
end;

function TfrmMain.ConfirmChange(Action: string; Upon: string): boolean;
begin
  if not Settings.WarnSectorChange then
  begin
    Result := True;
    exit;
  end;
  Result := MessageDlg('You are about to ' + Action + ' this ' + Upon + ' ' + CR + CR +
    'Do you know what you are doing?', mtWarning, [mbYes, mbNo], 0) = mrYes;
end;

function GetListViewAsText(ForListView: TListView): string;
var
  CIdx: integer;
  Item: TListItem;
  SubItem: string;
  SelectAll: boolean;
begin
  Result := '';
  // Headings
  for CIdx := 0 to ForListView.Columns.Count - 1 do
    Result := Result + ForListView.Columns[CIdx].Caption + TAB;
  Result := Result + CRLF;

  // Details
  SelectAll := ForListView.Selected = nil;
  for Item in ForListView.Items do
    if Item.Selected or SelectAll then
    begin
      Result := Result + Item.Caption + TAB;
      for SubItem in Item.SubItems do
        Result := Result + SubItem + TAB;
      Result := Result + CRLF;
    end;
end;

procedure TfrmMain.itmEditCopyClick(Sender: TObject);
begin
  Clipboard.AsText := GetListViewAsText(lvwMain);
end;

procedure TfrmMain.itmEditSelectAllClick(Sender: TObject);
begin
  lvwMain.SelectAll;
end;

procedure TfrmMain.itmFindClick(Sender: TObject);
begin
  dlgFind.Execute;
end;

procedure TfrmMain.dlgFindFind(Sender: TObject);
var
  StartSector, FoundSector: TDSKSector;
  Node: TTreeNode;
  Obj: TObject;
begin
  if tvwMain.Selected.Data = nil then exit;

  // Find out where to start searching
  Obj := TObject(tvwMain.Selected.Data);
  StartSector := nil;
  if Obj.ClassType = TDSKImage then
    StartSector := TDSKImage(Obj).Disk.Side[0].Track[0].Sector[0];
  if Obj.ClassType = TDSKDisk then
    StartSector := TDSKDisk(Obj).Side[0].Track[0].Sector[0];
  if Obj.ClassType = TDSKSide then
    StartSector := TDSKSide(Obj).Track[0].Sector[0];
  if Obj.ClassType = TDSKTrack then
    StartSector := TDSKTrack(Obj).Sector[0];
  if Obj.ClassType = TDSKSector then
    StartSector := TDSKSector(Obj);

  if StartSector = nil then
    exit;

  FoundSector := StartSector.ParentTrack.ParentSide.ParentDisk.ParentImage.FindText(
    StartSector, dlgFind.FindText, frMatchCase in dlgFind.Options);

  if FoundSector <> nil then
  begin
    for Node in tvwMain.Items do
      if Node.Data = FoundSector then
        tvwMain.Selected := Node;
  end;
end;

procedure TfrmMain.itmFindNextClick(Sender: TObject);
begin
  dlgFindFind(Sender);
end;

procedure TfrmMain.tvwMainDblClick(Sender: TObject);
begin
  itmSectorPropertiesClick(Sender);
end;

function TfrmMain.AddColumn(Caption: string): TListColumn;
begin
  Result := lvwMain.Columns.Add;
  Result.Caption := Caption;
  Result.Alignment := taRightJustify;
  Result.AutoSize := True;
end;

function TfrmMain.AddColumns(Captions: array of string): TListColumnArray;
var
  CIdx: integer;
begin
  Result := TListColumnArray.Create;
  SetLength(Result, Length(Captions));
  for CIdx := 0 to Length(Captions) - 1 do
    Result[CIdx] := AddColumn(Captions[CIdx]);
end;

procedure TfrmMain.OnApplicationDropFiles(Sender: TObject; const FileNames: array of string);
var
  FileName: string;
begin
  tvwMain.BeginUpdate;
  for FileName in FileNames do
  begin
    LoadImage(FileName);
    Settings.AddRecentFile(FileName);
  end;
  tvwMain.EndUpdate;
  UpdateRecentFilesMenu;
end;

end.
