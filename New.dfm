object frmNew: TfrmNew
  Left = 960
  Top = 818
  BorderStyle = bsDialog
  Caption = 'New'
  ClientHeight = 294
  ClientWidth = 513
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnlInfo: TPanel
    Left = 299
    Top = 0
    Width = 214
    Height = 264
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 6
    TabOrder = 0
    object lvwWarnings: TListView
      Left = 6
      Top = 136
      Width = 202
      Height = 122
      Align = alBottom
      Columns = <
        item
          Caption = 'Value'
          Width = -2
          WidthType = (
            -2)
        end>
      Font.Charset = ANSI_CHARSET
      Font.Color = clMaroon
      Font.Height = -9
      Font.Name = 'Tahoma'
      Font.Style = []
      ReadOnly = True
      RowSelect = True
      ParentFont = False
      ShowColumnHeaders = False
      TabOrder = 0
      ViewStyle = vsReport
    end
    object pnlSummary: TPanel
      Left = 6
      Top = 6
      Width = 202
      Height = 19
      Align = alTop
      BevelOuter = bvNone
      Caption = 'Summary'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object lvwSummary: TListView
      Left = 6
      Top = 25
      Width = 202
      Height = 64
      Align = alTop
      Columns = <
        item
          Caption = 'Key'
          Width = -2
          WidthType = (
            -2)
        end
        item
          Alignment = taRightJustify
          Caption = 'Value'
          Width = -2
          WidthType = (
            -2)
        end>
      Items.ItemData = {
        01F40000000400000000000000FFFFFFFFFFFFFFFF01000000000000000D4400
        690073006B002000630061007000610063006900740079000330004B00420000
        000000FFFFFFFFFFFFFFFF01000000000000000A460072006500650020007300
        70006100630065000330004B00420000000000FFFFFFFFFFFFFFFF0100000000
        000000114400690072006500630074006F0072007900200065006E0074007200
        69006500730001300000000000FFFFFFFFFFFFFFFF0100000000000000164200
        6F006F0074002F006400690073006B0020007300700065006300200063006100
        7000610062006C00650003590065007300FFFFFFFFFFFFFFFF}
      ReadOnly = True
      RowSelect = True
      ShowColumnHeaders = False
      TabOrder = 2
      ViewStyle = vsReport
    end
    object pnlWarnings: TPanel
      Left = 6
      Top = 117
      Width = 202
      Height = 19
      Align = alBottom
      BevelOuter = bvNone
      Caption = 'Warnings'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
  end
  object pnlTabs: TPanel
    Left = 0
    Top = 0
    Width = 299
    Height = 264
    Align = alLeft
    BevelOuter = bvNone
    BorderWidth = 5
    TabOrder = 1
    object pagTabs: TPageControl
      Left = 5
      Top = 5
      Width = 289
      Height = 254
      ActivePage = tabFormat
      Align = alClient
      Constraints.MinHeight = 254
      Constraints.MinWidth = 281
      TabOrder = 0
      object tabFormat: TTabSheet
        Caption = 'Basic'
        DesignSize = (
          281
          226)
        object lblFormatDesc: TLabel
          Left = 8
          Top = 8
          Width = 257
          Height = 33
          AutoSize = False
          Caption = 
            'Select from a pre-defined disk format from the list or load defi' +
            'nition from a file.'
          WordWrap = True
        end
        object lvwFormats: TListView
          Left = 8
          Top = 40
          Width = 264
          Height = 153
          Anchors = [akLeft, akTop, akRight, akBottom]
          Columns = <
            item
              Caption = 'Name'
              Width = -2
              WidthType = (
                -2)
            end
            item
              Alignment = taRightJustify
              Caption = 'Size KB'
              Width = -2
              WidthType = (
                -2)
            end
            item
              Alignment = taRightJustify
              Caption = 'Free KB'
              Width = -2
              WidthType = (
                -2)
            end>
          ColumnClick = False
          HideSelection = False
          Items.ItemData = {
            01A60200000900000000000000FFFFFFFFFFFFFFFF02000000000000001B4100
            6D007300740072006100640020005000430057002F0053007000650063007400
            720075006D0020002B0033002000430046003200033100380030000331003700
            330001000000FFFFFFFFFFFFFFFF02000000000000001141006D007300740072
            0061006400200050004300570020004300460032004400440003370032003000
            0337003100310002000000FFFFFFFFFFFFFFFF02000000000000001241006D00
            7300740072006100640020004300500043002000530079007300740065006D00
            033100380030000331003700330003000000FFFFFFFFFFFFFFFF020000000000
            00001041006D0073007400720061006400200043005000430020004400610074
            006100033100380030000331003700380007000000FFFFFFFFFFFFFFFF020000
            00000000000F41006D0073007400720061006400200043005000430020004900
            42004D00033100360030000331003500340005000000FFFFFFFFFFFFFFFF0200
            00000000000011530075007000650072004D006100740020003100390032002F
            005800430046003200033200300030000331003900320004000000FFFFFFFFFF
            FFFFFF0200000000000000134800690046006F0072006D002000320030003300
            2F00490061006E00200048006900670068000332003100300003320030003300
            06000000FFFFFFFFFFFFFFFF02000000000000001155006C0074007200610020
            003200300038002F00490061006E0020004D0061007800033200310030000332
            003000380008000000FFFFFFFFFFFFFFFF02000000000000000D4D0047005400
            2000530061006D00200043006F00750070006500033800300030000338003000
            3000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFFFF}
          ReadOnly = True
          RowSelect = True
          TabOrder = 0
          ViewStyle = vsReport
          OnChange = lvwFormatsChange
        end
        object chkAdjust: TCheckBox
          Left = 8
          Top = 200
          Width = 161
          Height = 17
          Caption = 'Allow advanced adjustment'
          TabOrder = 1
          OnClick = chkAdjustClick
        end
      end
      object tabDetails: TTabSheet
        Caption = 'Advanced'
        ImageIndex = 1
        object lblSides: TLabel
          Left = 8
          Top = 11
          Width = 67
          Height = 13
          Caption = 'Side structure'
        end
        object lblTracks: TLabel
          Left = 8
          Top = 35
          Width = 72
          Height = 13
          Caption = 'Tracks per side'
        end
        object lblSectors: TLabel
          Left = 144
          Top = 35
          Width = 64
          Height = 13
          Caption = 'Sectors/track'
          FocusControl = edtSectors
        end
        object lblSecSize: TLabel
          Left = 8
          Top = 67
          Width = 52
          Height = 13
          Caption = 'Sector size'
          FocusControl = edtSecSize
        end
        object lblGapRW: TLabel
          Left = 8
          Top = 139
          Width = 72
          Height = 13
          Caption = 'Gap read/write'
          FocusControl = edtGapRW
        end
        object lblGapFormat: TLabel
          Left = 144
          Top = 139
          Width = 54
          Height = 13
          Caption = 'Gap format'
          FocusControl = edtGapFormat
        end
        object lblResTracks: TLabel
          Left = 144
          Top = 91
          Width = 72
          Height = 13
          Caption = 'Reserve tracks'
          FocusControl = edtResTracks
        end
        object lblDirBlocks: TLabel
          Left = 8
          Top = 171
          Width = 76
          Height = 13
          Caption = 'Directory blocks'
          FocusControl = edtDirBlocks
        end
        object lblFiller: TLabel
          Left = 8
          Top = 203
          Width = 47
          Height = 13
          Caption = 'Filler byte'
          FocusControl = udFiller
        end
        object lblFillHex: TLabel
          Left = 147
          Top = 203
          Width = 22
          Height = 13
          AutoSize = False
        end
        object lblFirstSector: TLabel
          Left = 144
          Top = 67
          Width = 68
          Height = 13
          Caption = 'First sector ID'
          FocusControl = edtFirstSector
        end
        object lblInterleave: TLabel
          Left = 8
          Top = 91
          Width = 50
          Height = 13
          Caption = 'Interleave'
          FocusControl = edtInterleave
        end
        object lblSkewTrack: TLabel
          Left = 8
          Top = 115
          Width = 57
          Height = 13
          Caption = 'Skew tracks'
          FocusControl = edtSkewTrack
        end
        object lblBlockSize: TLabel
          Left = 144
          Top = 171
          Width = 45
          Height = 13
          Caption = 'Block size'
          FocusControl = edtBlockSize
        end
        object lblSkewSide: TLabel
          Left = 144
          Top = 115
          Width = 52
          Height = 13
          Caption = 'Skew sides'
          FocusControl = edtSkewSide
        end
        object cboSides: TComboBox
          Left = 88
          Top = 8
          Width = 137
          Height = 21
          Style = csDropDownList
          ItemHeight = 0
          TabOrder = 0
          OnChange = cboSidesChange
        end
        object edtTracks: TEdit
          Left = 88
          Top = 32
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 1
          Text = '1'
          OnChange = edtTracksChange
        end
        object edtSectors: TEdit
          Left = 224
          Top = 32
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 2
          Text = '1'
          OnChange = edtSectorsChange
        end
        object edtSecSize: TEdit
          Left = 88
          Top = 64
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 3
          Text = '1'
          OnChange = edtSecSizeChange
        end
        object udSecSize: TUpDown
          Left = 121
          Top = 64
          Width = 16
          Height = 21
          Associate = edtSecSize
          Max = 6912
          Increment = 256
          Position = 1
          TabOrder = 4
          Thousands = False
        end
        object edtGapRW: TEdit
          Left = 88
          Top = 136
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 7
          Text = '1'
          OnChange = edtGapRWChange
        end
        object udGapRW: TUpDown
          Left = 121
          Top = 136
          Width = 15
          Height = 21
          Associate = edtGapRW
          Max = 255
          Position = 1
          TabOrder = 8
        end
        object edtGapFormat: TEdit
          Left = 224
          Top = 136
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 9
          Text = '1'
          OnChange = edtGapFormatChange
        end
        object udGapFormat: TUpDown
          Left = 257
          Top = 136
          Width = 15
          Height = 21
          Associate = edtGapFormat
          Max = 255
          Position = 1
          TabOrder = 10
        end
        object edtResTracks: TEdit
          Left = 224
          Top = 88
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 11
          Text = '1'
          OnChange = edtResTracksChange
        end
        object udResTracks: TUpDown
          Left = 257
          Top = 88
          Width = 15
          Height = 21
          Associate = edtResTracks
          Max = 255
          Position = 1
          TabOrder = 12
        end
        object edtDirBlocks: TEdit
          Left = 88
          Top = 168
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 13
          Text = '1'
          OnChange = edtDirBlocksChange
        end
        object udDirBlocks: TUpDown
          Left = 121
          Top = 168
          Width = 15
          Height = 21
          Associate = edtDirBlocks
          Max = 255
          Position = 1
          TabOrder = 14
        end
        object edtFiller: TEdit
          Left = 88
          Top = 200
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 15
          Text = '1'
          OnChange = edtFillerChange
        end
        object udFiller: TUpDown
          Left = 121
          Top = 200
          Width = 15
          Height = 21
          Associate = edtFiller
          Max = 255
          Position = 1
          TabOrder = 16
        end
        object udTracks: TUpDown
          Left = 121
          Top = 32
          Width = 15
          Height = 21
          Associate = edtTracks
          Min = 1
          Max = 255
          Position = 1
          TabOrder = 17
        end
        object udSectors: TUpDown
          Left = 257
          Top = 32
          Width = 15
          Height = 21
          Associate = edtSectors
          Min = 1
          Max = 255
          Position = 1
          TabOrder = 18
        end
        object edtFirstSector: TEdit
          Left = 224
          Top = 64
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 5
          Text = '1'
          OnChange = edtFirstSectorChange
        end
        object udFirstSector: TUpDown
          Left = 257
          Top = 64
          Width = 15
          Height = 21
          Associate = edtFirstSector
          Max = 255
          Position = 1
          TabOrder = 6
        end
        object edtInterleave: TEdit
          Left = 88
          Top = 88
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 19
          Text = '1'
          OnChange = edtInterleaveChange
        end
        object udInterleave: TUpDown
          Left = 121
          Top = 88
          Width = 15
          Height = 21
          Associate = edtInterleave
          Min = -127
          Max = 127
          Position = 1
          TabOrder = 20
        end
        object edtSkewTrack: TEdit
          Left = 88
          Top = 112
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 21
          Text = '1'
          OnChange = edtSkewTrackChange
        end
        object udSkewTrack: TUpDown
          Left = 121
          Top = 112
          Width = 15
          Height = 21
          Associate = edtSkewTrack
          Min = -127
          Max = 127
          Position = 1
          TabOrder = 22
        end
        object edtBlockSize: TEdit
          Left = 224
          Top = 168
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 23
          Text = '0'
          OnChange = edtBlockSizeChange
        end
        object udBlockSize: TUpDown
          Left = 257
          Top = 168
          Width = 16
          Height = 21
          Associate = edtBlockSize
          Max = 16384
          Increment = 128
          TabOrder = 24
          Thousands = False
        end
        object edtSkewSide: TEdit
          Left = 224
          Top = 112
          Width = 33
          Height = 21
          BiDiMode = bdLeftToRight
          ParentBiDiMode = False
          TabOrder = 25
          Text = '1'
          OnChange = edtSkewSideChange
        end
        object udSkewSide: TUpDown
          Left = 257
          Top = 112
          Width = 15
          Height = 21
          Associate = edtSkewSide
          Min = -127
          Max = 127
          Position = 1
          TabOrder = 26
        end
      end
      object tabDiskSpec: TTabSheet
        Caption = 'Specification'
        ImageIndex = 2
        object lblSpecDesc: TLabel
          Left = 8
          Top = 8
          Width = 257
          Height = 41
          AutoSize = False
          Caption = 
            'For the PCW/+3 to correctly identify disk formats a specificatio' +
            'n block should to be written to the start of the disk or it will' +
            ' assume the standard 180K format.'
          WordWrap = True
        end
        object chkWriteDiskSpec: TCheckBox
          Left = 8
          Top = 59
          Width = 161
          Height = 17
          Caption = 'Write disk specification block'
          TabOrder = 0
          OnClick = chkWriteDiskSpecClick
        end
      end
      object tabBoot: TTabSheet
        Caption = 'Boot'
        ImageIndex = 3
        OnShow = tabBootShow
        object lblBootDesc: TLabel
          Left = 8
          Top = 8
          Width = 257
          Height = 57
          AutoSize = False
          Caption = 
            'You may choose a binary file to use as a boot sector. For the PC' +
            'W/+3 this normally follows the disk specification which also con' +
            'tains the boot checksum, for the Amstrad CPC the first sector ID' +
            ' must be 65.'
          WordWrap = True
        end
        object lblBootBinary: TLabel
          Left = 8
          Top = 75
          Width = 19
          Height = 13
          Caption = 'File '
        end
        object lblBootType: TLabel
          Left = 8
          Top = 103
          Width = 24
          Height = 13
          Caption = 'Type'
        end
        object lblBinFile: TLabel
          Left = 48
          Top = 75
          Width = 161
          Height = 13
          AutoSize = False
          EllipsisPosition = epPathEllipsis
        end
        object lblBinOffset: TLabel
          Left = 67
          Top = 131
          Width = 30
          Height = 13
          AutoSize = False
        end
        object lblBootDetails: TLabel
          Left = 8
          Top = 135
          Width = 32
          Height = 13
          Caption = 'Details'
        end
        object cboBootMachine: TComboBox
          Left = 48
          Top = 100
          Width = 161
          Height = 21
          Style = csDropDownList
          ItemHeight = 0
          TabOrder = 0
          OnChange = cboBootMachineChange
          Items.Strings = (
            'Spectrum +3'
            'Amstrad PCW 8256'
            'Amstrad PCW 9512'
            'Amstrad CPC 664/6128')
        end
        object lvwBootDetails: TListView
          Left = 48
          Top = 133
          Width = 225
          Height = 76
          Columns = <
            item
              Caption = 'Key'
              Width = -2
              WidthType = (
                -2)
            end
            item
              Alignment = taRightJustify
              Caption = 'Value'
              Width = -2
              WidthType = (
                -2)
            end>
          ReadOnly = True
          RowSelect = True
          ShowColumnHeaders = False
          TabOrder = 1
          ViewStyle = vsReport
        end
        object btnBootClear: TBitBtn
          Left = 250
          Top = 72
          Width = 24
          Height = 22
          TabOrder = 2
          OnClick = btnBootClearClick
          Glyph.Data = {
            F6000000424DF600000000000000760000002800000010000000100000000100
            0400000000008000000000000000000000001000000000000000000000000000
            8000008000000080800080000000800080008080000080808000C0C0C0000000
            FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
            8888888888888888888888808888888888088800088888888888880000888888
            8088888000888888088888880008888008888888800088008888888888000008
            8888888888800088888888888800000888888888800088008888888000088880
            0888880000888888008888000888888888088888888888888888}
        end
        object btnBootBin: TBitBtn
          Left = 225
          Top = 72
          Width = 24
          Height = 22
          TabOrder = 3
          OnClick = btnBootBinClick
          Glyph.Data = {
            F6000000424DF600000000000000760000002800000010000000100000000100
            0400000000008000000000000000000000001000000000000000000000000000
            8000008000000080800080000000800080008080000080808000C0C0C0000000
            FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
            88888888888888888888000000000008888800333333333088880B0333333333
            08880FB03333333330880BFB0333333333080FBFB000000000000BFBFBFBFB08
            88880FBFBFBFBF0888880BFB0000000888888000888888880008888888888888
            8008888888880888080888888888800088888888888888888888}
        end
      end
    end
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 264
    Width = 513
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      513
      30)
    object btnFormat: TButton
      Left = 352
      Top = 2
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Format'
      Default = True
      TabOrder = 0
      OnClick = btnFormatClick
    end
    object btnCancel: TButton
      Left = 433
      Top = 2
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Close'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
  object dlgOpenBoot: TOpenDialog
    Options = [ofReadOnly, ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 8
    Top = 264
  end
end
