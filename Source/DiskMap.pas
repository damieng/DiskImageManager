unit DiskMap;

{
  Disk Image Manager -  Copyright 2002-2023 Envy Technologies Ltd.

  Disk map graphical component
}

interface

uses
  DskImage, Utils,
  Forms, SysUtils, Classes, Controls, Graphics, GraphUtil, Types;

type
  TSpinDiskMap = class(TGraphicControl)
  private
    FBevelWidth: integer;
    FBorderStyle: TSpinBorderStyle;
    FDarkBlankSectors: boolean;
    FGridColor: TColor;
    FSide: TDSKSide;
    FTrackMark: integer;
    function GetMaxSectors: integer;
    procedure SetBorderStyle(NewBorderStyle: TSpinBorderStyle);
    procedure SetDarkBlankSectors(NewDarkBlankSectors: boolean);
    procedure SetGridColor(NewGridColor: TColor);
    procedure SetSide(NewSide: TDSKSide);
    procedure SetTrackMark(NewTrackMark: integer);
    procedure RenderBitmap(BufMap: TBitmap; Rect: TRect);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function SaveMap(FileName: TFileName; SaveWidth: integer; SaveHeight: integer): boolean;
  published
    property Align;
    property BorderStyle: TSpinBorderStyle read FBorderStyle write SetBorderStyle;
    property Color;
    property DarkBlankSectors: boolean read FDarkBlankSectors write SetDarkBlankSectors;
    property Font;
    property GridColor: TColor read FGridColor write SetGridColor;
    property ParentFont;
    property PopupMenu;
    property Side: TDSKSide read FSide write SetSide;
    property TrackMark: integer read FTrackMark write SetTrackMark;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('DIM', [TSpinDiskMap]);
end;

constructor TSpinDiskMap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  Color := clAppWorkspace;
  FTrackMark := 5;
  FGridColor := clSilver;
  FBevelWidth := 2;
  FBorderStyle := bsLowered;
  ShowHint := True;
end;

destructor TSpinDiskMap.Destroy;
begin
  inherited Destroy;
end;

procedure TSpinDiskMap.Paint;
var
  BufMap: TBitmap;
  Rect: TRect;
begin
  BufMap := TBitmap.Create;
  BufMap.Height := Height;
  BufMap.Width := Width;
  Rect := ClientRect;

  RenderBitmap(BufMap, Rect);

  BufMap.Canvas.Pen.Style := psSolid;
  Canvas.CopyMode := cmSrcCopy;
  Canvas.Draw(0, 0, BufMap);
  DrawBorder(Canvas, Rect, FBorderStyle);
  BufMap.Free;
end;

procedure TSpinDiskMap.RenderBitmap(BufMap: TBitmap; Rect: TRect);
var
  Tracks, TrackIdx, TrackSize: integer;
  Sectors, SectorIdx, SectorSize: integer;
  GRect: TRect;
  X, Y: integer;
  TextH, TextW: integer;
  TextA: string;
  ErrDE, ErrCM: boolean;
begin
  if Side <> nil then
  begin
    Tracks := Side.Tracks;
    Sectors := GetMaxSectors;
  end
  else
  begin
    Tracks := 40;
    Sectors := 9;
  end;

  with BufMap.Canvas do
  begin
    // Setup the canvas
    Brush.Color := Self.Color;
    FillRect(Rect);

    // Setup for drawing
    Font := Self.Font;
    Pen.Color := clWhite;
    TextH := TextHeight('X');
    TextW := TextWidth('M');
    InflateRect(Rect, -TextW, -TextH);

    // Calculate usable track/sector sizes and new area
    GRect := Rect;
    with GRect do
    begin
      Left := Left + (TextW * 2);
      Bottom := Bottom - TextH;
      Top := TextH div 2;
      Right := Right - TextW;

      if Sectors > 0 then
        SectorSize := (Bottom - Top) div Sectors
      else
        SectorSize := 0;

      if Tracks > 0 then
        TrackSize := (Right - Left) div Tracks
      else
        TrackSize := 0;

      Top := GRect.Bottom - (Sectors * SectorSize);
      Right := GRect.Left + (Tracks * TrackSize);
    end;

    Pen.Color := GridColor;
    // Draw the main grid
    for TrackIdx := 0 to Tracks do
    begin
      X := GRect.Left + (TrackIdx * TrackSize);

      // Track markers
      MoveTo(X, GRect.Bottom);
      LineTo(X, GRect.Top);
      if TrackIdx mod TrackMark = 0 then
      begin
        LineTo(X, GRect.Bottom + TextH);
        TextA := StrInt(TrackIdx);
        TextOut(X + (TrackSize div 2) - (TextW div 2), GRect.Bottom + TextH, TextA);
      end
      else
        LineTo(X, GRect.Bottom + (TextH div 2));

      for SectorIdx := 0 to Sectors do
      begin
        Y := GRect.Bottom - (SectorSize * SectorIdx);

        // Sector markers
        MoveTo(GRect.Left - TextW, Y);
        LineTo(GRect.Right, Y);
        if (TrackIdx = 0) and (SectorIdx < Sectors) then
        begin
          TextA := StrInt(SectorIdx);
          TextOut(GRect.Left - TextWidth(TextA) - TextW, Y - (SectorSize div 2) - (TextHeight(Text) div 2), TextA);
        end;
      end;
    end;

    // Populate the grid
    if Side <> nil then
    begin
      Pen.Style := psClear;
      for TrackIdx := 0 to Side.Tracks - 1 do
      begin
        X := GRect.Left + (TrackIdx * TrackSize);
        for SectorIdx := 0 to Side.Track[TrackIdx].Sectors - 1 do
        begin
          Brush.Color := clWhite;
          with Side.Track[TrackIdx].Sector[SectorIdx] do
          begin
            ErrDE := (((FDCStatus[1] and 32) = 32) or ((FDCStatus[2] and 32) = 32));
            ErrCM := ((FDCStatus[2] and 64) = 64);
            if ErrDE then
              Brush.Color := clRed;
            if ErrCM then
              Brush.Color := $00000BBFF;
            if ErrDE and ErrCM then
              Brush.Color := clYellow;
            if (Status <> ssFormattedInUse) and DarkBlankSectors then
              Brush.Color := GetShadowColor(Brush.Color);
          end;
          Y := GRect.Bottom - (SectorIdx * SectorSize);
          Rectangle(X + 1, Y - (SectorSize) + 1, X + (TrackSize) + 1, Y + 1);
        end;
      end;
    end;
  end;
end;

// Set the side to analyse
procedure TSpinDiskMap.SetSide(NewSide: TDSKSide);
begin
  if NewSide <> FSide then
  begin
    FSide := NewSide;
    Invalidate;
  end;
end;

// DarkBlankSectors property changes
procedure TSpinDiskMap.SetDarkBlankSectors(NewDarkBlankSectors: boolean);
begin
  if NewDarkBlankSectors <> FDarkBlankSectors then
  begin
    FDarkBlankSectors := NewDarkBlankSectors;
    Invalidate;
  end;
end;

// TrackMark property change
procedure TSpinDiskMap.SetTrackMark(NewTrackMark: integer);
begin
  if NewTrackMark <> FTrackMark then
  begin
    FTrackMark := NewTrackMark;
    Invalidate;
  end;
end;

// Detect maximum sector number
function TSpinDiskMap.GetMaxSectors: integer;
var
  TrackIdx: integer;
begin
  Result := 0;
  for TrackIdx := 0 to Side.Tracks - 1 do
    if Side.Track[TrackIdx].Sectors > Result then
      Result := Side.Track[TrackIdx].Sectors;
end;

// GridColor property change
procedure TSpinDiskMap.SetGridColor(NewGridColor: TColor);
begin
  if NewGridColor <> FGridColor then
  begin
    FGridColor := NewGridColor;
    Invalidate;
  end;
end;

procedure TSpinDiskMap.SetBorderStyle(NewBorderStyle: TSpinBorderStyle);
begin
  if NewBorderStyle <> FBorderStyle then
  begin
    FBorderStyle := NewBorderStyle;
    Invalidate;
  end;
end;

function TSpinDiskMap.SaveMap(FileName: TFileName; SaveWidth: integer; SaveHeight: integer): boolean;
var
  SaveImage: TBitmap;
begin
  SaveImage := TBitmap.Create;
  SaveImage.Width := SaveWidth;
  SaveImage.Height := SaveHeight;

  RenderBitmap(SaveImage, Rect(0, 0, SaveWidth - 1, SaveHeight - 1));
  SaveImage.SaveToFile(FileName);
  SaveImage.Free;
  Result := True;
end;

end.
