object frmOptions: TfrmOptions
  Left = 1286
  Top = 812
  BorderStyle = bsDialog
  Caption = 'Options'
  ClientHeight = 359
  ClientWidth = 306
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object pnlButtons: TPanel
    Left = 0
    Top = 331
    Width = 306
    Height = 28
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      306
      28)
    object btnOK: TButton
      Left = 144
      Top = 0
      Width = 75
      Height = 23
      Anchors = [akTop, akRight]
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnCancel: TButton
      Left = 226
      Top = 0
      Width = 75
      Height = 23
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
    object btnReset: TButton
      Left = 5
      Top = 0
      Width = 75
      Height = 23
      Anchors = [akTop, akRight]
      Caption = 'Reset'
      TabOrder = 2
      OnClick = btnResetClick
    end
  end
  object pnlSheet: TPanel
    Left = 0
    Top = 0
    Width = 306
    Height = 331
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 5
    TabOrder = 1
    object pagOptions: TPageControl
      Left = 5
      Top = 5
      Width = 296
      Height = 321
      ActivePage = tabMain
      Align = alClient
      HotTrack = True
      TabOrder = 0
      object tabMain: TTabSheet
        Caption = 'Main'
        object lblFontMainLabel: TLabel
          Left = 8
          Top = 16
          Width = 26
          Height = 13
          Caption = 'Font:'
        end
        object lblFontMain: TLabel
          Left = 72
          Top = 16
          Width = 177
          Height = 13
          AutoSize = False
        end
        object btnFontMain: TButton
          Left = 256
          Top = 13
          Width = 25
          Height = 19
          Caption = '...'
          TabOrder = 0
          OnClick = btnFontMainClick
        end
        object chkRestoreWindow: TCheckBox
          Left = 8
          Top = 48
          Width = 201
          Height = 17
          Caption = 'Remember window position and size'
          TabOrder = 1
        end
        object chkRestoreWorkspace: TCheckBox
          Left = 8
          Top = 72
          Width = 201
          Height = 17
          Caption = 'Remember workspace'
          TabOrder = 2
        end
      end
      object tabSectors: TTabSheet
        Caption = 'Sectors'
        ImageIndex = 1
        object lblFontSectorLabel: TLabel
          Left = 8
          Top = 16
          Width = 26
          Height = 13
          Caption = 'Font:'
        end
        object lblFontSector: TLabel
          Left = 72
          Top = 16
          Width = 177
          Height = 13
          AutoSize = False
        end
        object lblBytesLabel: TLabel
          Left = 8
          Top = 48
          Width = 51
          Height = 13
          Caption = 'Bytes/line:'
        end
        object lblNonDisplayLabel: TLabel
          Left = 8
          Top = 80
          Width = 60
          Height = 13
          Caption = 'Non-display:'
        end
        object btnFontSector: TButton
          Left = 256
          Top = 13
          Width = 25
          Height = 19
          Caption = '...'
          TabOrder = 0
          OnClick = btnFontSectorClick
        end
        object edtBytes: TEdit
          Left = 72
          Top = 44
          Width = 33
          Height = 21
          Ctl3D = True
          MaxLength = 3
          ParentCtl3D = False
          TabOrder = 1
          Text = '16'
        end
        object udBytes: TUpDown
          Left = 105
          Top = 44
          Width = 15
          Height = 21
          Associate = edtBytes
          Min = 1
          Max = 255
          Position = 16
          TabOrder = 2
        end
        object edtNonDisplay: TEdit
          Left = 72
          Top = 76
          Width = 17
          Height = 21
          MaxLength = 1
          TabOrder = 3
        end
        object chkWarnSectorChange: TCheckBox
          Left = 7
          Top = 104
          Width = 273
          Height = 17
          Caption = 'Warn before changing data or FDC flags'
          TabOrder = 4
        end
      end
      object tabDiskMap: TTabSheet
        Caption = 'Disk Map'
        ImageIndex = 2
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 0
        ExplicitHeight = 0
        object DiskMap: TSpinDiskMap
          Left = 6
          Top = 136
          Width = 275
          Height = 153
          BorderStyle = bsLowered
          Color = clAppWorkSpace
          DarkBlankSectors = False
          GridColor = clSilver
          TrackMark = 5
        end
        object lblFontMapLabel: TLabel
          Left = 8
          Top = 16
          Width = 26
          Height = 13
          Caption = 'Font:'
        end
        object lblFontMap: TLabel
          Left = 72
          Top = 16
          Width = 177
          Height = 13
          AutoSize = False
        end
        object lblBackColorLabel: TLabel
          Left = 8
          Top = 40
          Width = 58
          Height = 13
          Caption = 'Back colour:'
        end
        object lblGridColorLabel: TLabel
          Left = 160
          Top = 40
          Width = 55
          Height = 13
          Caption = 'Grid colour:'
        end
        object lblTrackMarksLabel: TLabel
          Left = 8
          Top = 96
          Width = 61
          Height = 13
          Caption = 'Track marks:'
        end
        object btnFontMap: TButton
          Left = 256
          Top = 13
          Width = 25
          Height = 19
          Caption = '...'
          TabOrder = 0
          OnClick = btnFontMapClick
        end
        object udTrackMarks: TUpDown
          Left = 113
          Top = 92
          Width = 15
          Height = 21
          Associate = edtTrackMarks
          Min = 1
          Max = 255
          Position = 1
          TabOrder = 1
        end
        object edtTrackMarks: TEdit
          Left = 80
          Top = 92
          Width = 33
          Height = 21
          Ctl3D = True
          MaxLength = 3
          ParentCtl3D = False
          TabOrder = 3
          Text = '1'
          OnChange = edtTrackMarksChange
        end
        object chkDarkBlankSectors: TCheckBox
          Left = 160
          Top = 96
          Width = 121
          Height = 17
          Caption = 'Dark unused sectors'
          TabOrder = 2
          OnClick = chkDarkBlankSectorsClick
        end
        object cbxBack: TColorBox
          Left = 8
          Top = 59
          Width = 137
          Height = 22
          Style = [cbStandardColors, cbExtendedColors, cbSystemColors, cbCustomColor, cbPrettyNames]
          ItemHeight = 16
          TabOrder = 4
        end
        object cbxGrid: TColorBox
          Left = 160
          Top = 59
          Width = 121
          Height = 22
          Style = [cbStandardColors, cbExtendedColors, cbSystemColors, cbCustomColor, cbPrettyNames]
          ItemHeight = 16
          TabOrder = 5
        end
      end
      object tabSaving: TTabSheet
        Caption = 'Saving'
        ImageIndex = 3
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 0
        ExplicitHeight = 0
        object lblMapSave: TLabel
          Left = 8
          Top = 96
          Width = 64
          Height = 13
          Caption = 'Disk map files'
        end
        object lblBy: TLabel
          Left = 160
          Top = 96
          Width = 12
          Height = 13
          Caption = 'by'
        end
        object chkWarnConversionProblems: TCheckBox
          Left = 8
          Top = 16
          Width = 273
          Height = 17
          Caption = 'Warn about disk conversion problems'
          TabOrder = 0
        end
        object chkSaveRemoveEmptyTracks: TCheckBox
          Left = 8
          Top = 40
          Width = 273
          Height = 17
          Caption = 'Remove unformatted tracks from file'
          TabOrder = 1
        end
        object edtMapX: TEdit
          Left = 88
          Top = 92
          Width = 49
          Height = 21
          TabOrder = 2
          Text = '1'
        end
        object edtMapY: TEdit
          Left = 184
          Top = 92
          Width = 49
          Height = 21
          TabOrder = 3
          Text = '1'
        end
        object udMapX: TUpDown
          Left = 137
          Top = 92
          Width = 15
          Height = 21
          Associate = edtMapX
          Min = 1
          Max = 4096
          Increment = 100
          Position = 1
          TabOrder = 4
        end
        object udMapY: TUpDown
          Left = 233
          Top = 92
          Width = 15
          Height = 21
          Associate = edtMapY
          Min = 1
          Max = 4096
          Increment = 100
          Position = 1
          TabOrder = 5
        end
      end
    end
  end
  object dlgFont: TFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Left = 264
  end
end
