object frmMediathekViewExample: TfrmMediathekViewExample
  Left = 0
  Top = 0
  Caption = 'MediathekView Web Search'
  ClientHeight = 600
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 129
    Align = alTop
    BevelOuter = bvNone
    Color = clBlack
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 904
    object lblSearchTerm: TLabel
      Left = 16
      Top = 16
      Width = 54
      Height = 13
      Caption = 'Search for:'
      Color = clSilver
      ParentColor = False
    end
    object Label1: TLabel
      Left = 196
      Top = 65
      Width = 59
      Height = 13
      Caption = 'Max results:'
      Color = clSilver
      ParentColor = False
    end
    object lblProgress: TLabel
      Left = 16
      Top = 94
      Width = 43
      Height = 13
      Caption = 'Status...'
      Color = clSilver
      ParentColor = False
    end
    object Label2: TLabel
      Left = 15
      Top = 65
      Width = 44
      Height = 13
      Caption = 'Search in'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16775408
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentColor = False
      ParentFont = False
    end
    object edtSearchTerm: TEdit
      Left = 16
      Top = 35
      Width = 300
      Height = 21
      Color = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnKeyPress = edtSearchTermKeyPress
    end
    object SpinEdit1: TSpinEdit
      Left = 261
      Top = 62
      Width = 56
      Height = 22
      Color = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      MaxValue = 9999
      MinValue = 1
      ParentFont = False
      TabOrder = 1
      Value = 200
      OnChange = SpinEdit1Change
    end
    object pbProgress: TProgressBar
      Left = 624
      Top = 90
      Width = 265
      Height = 17
      TabOrder = 2
    end
    object btnSearch: TButton
      Left = 329
      Top = 33
      Width = 75
      Height = 25
      Caption = 'Search'
      TabOrder = 3
      OnClick = btnSearchClick
    end
    object btnCancel: TButton
      Left = 410
      Top = 33
      Width = 75
      Height = 25
      Caption = 'Chancel'
      TabOrder = 4
      OnClick = btnCancelClick
    end
    object cbPortal: TComboBox
      Left = 67
      Top = 62
      Width = 118
      Height = 21
      TabOrder = 5
      Text = 'Mediathekwebview'
      OnChange = cbPortalChange
      Items.Strings = (
        'Mediathekwebview'
        'Archive.org Video'
        'Archive.org Audio'
        'Jamendo Audio')
    end
  end
  object pnlResults: TPanel
    Left = 0
    Top = 129
    Width = 900
    Height = 471
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 904
    ExplicitHeight = 478
    object lblResults: TLabel
      Left = 16
      Top = 8
      Width = 52
      Height = 13
      Caption = 'Ergebnisse'
    end
    object splResults: TSplitter
      Left = 400
      Top = 0
      Width = 4
      Height = 471
      ExplicitTop = 27
      ExplicitHeight = 437
    end
    object lvResults: TListView
      Left = 0
      Top = 0
      Width = 400
      Height = 471
      Align = alLeft
      Checkboxes = True
      Color = clBlack
      Columns = <>
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      GridLines = True
      HotTrack = True
      ReadOnly = True
      RowSelect = True
      ParentFont = False
      TabOrder = 0
      ViewStyle = vsReport
      OnSelectItem = lvResultsSelectItem
      ExplicitHeight = 478
    end
    object pnlDetails: TPanel
      Left = 404
      Top = 0
      Width = 496
      Height = 471
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitWidth = 500
      ExplicitHeight = 478
      object lblDetails: TLabel
        Left = 8
        Top = 8
        Width = 32
        Height = 13
        Caption = 'Details'
      end
      object memDetails: TMemo
        Left = 0
        Top = 0
        Width = 496
        Height = 471
        Align = alClient
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        ExplicitWidth = 500
        ExplicitHeight = 478
      end
    end
  end
  object mediathekView: TLaMitaMediathekView
    BaseURL = 'https://mediathekviewweb.de/api/query'
    OnSearchFinished = mediathekViewSearchFinished
    OnSearchProgress = OnSearchProgress
    OnSearchError = OnSearchError
    Left = 48
    Top = 200
  end
end
