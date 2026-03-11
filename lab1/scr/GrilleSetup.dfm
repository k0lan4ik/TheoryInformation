object fGrilleSetup: TfGrilleSetup
  Left = 0
  Top = 0
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1072' '#1088#1077#1096#1105#1090#1082#1080
  ClientHeight = 257
  ClientWidth = 216
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnShow = FormShow
  TextHeight = 15
  object sgGrille: TStringGrid
    Left = 0
    Top = 50
    Width = 552
    Height = 344
    DefaultColWidth = 40
    DefaultRowHeight = 40
    FixedCols = 0
    FixedRows = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect]
    TabOrder = 0
    OnMouseDown = sgGrilleMouseDown
  end
  object pEdit: TPanel
    Left = 0
    Top = 0
    Width = 216
    Height = 50
    Align = alTop
    TabOrder = 1
    DesignSize = (
      216
      50)
    object btnOk: TButton
      Left = 130
      Top = 10
      Width = 74
      Height = 34
      Anchors = [akTop, akRight, akBottom]
      Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
      ModalResult = 1
      TabOrder = 0
      OnClick = btnOkClick
      ExplicitLeft = 526
      ExplicitHeight = 25
    end
    object btnCancel: TButton
      Left = 8
      Top = 10
      Width = 75
      Height = 34
      Anchors = [akLeft, akTop, akBottom]
      Caption = #1054#1090#1084#1077#1085#1072
      ModalResult = 2
      TabOrder = 1
      ExplicitHeight = 25
    end
  end
end
