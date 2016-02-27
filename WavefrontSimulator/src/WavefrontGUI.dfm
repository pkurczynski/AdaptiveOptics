object WavefrontGUIForm: TWavefrontGUIForm
  Left = 16
  Top = 77
  Width = 978
  Height = 629
  Caption = 
    'Wavefront Simulator                                             ' +
    '                                                                ' +
    '                                                                ' +
    '                                                      version 3'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox6: TGroupBox
    Left = 8
    Top = 0
    Width = 369
    Height = 289
    Caption = 'Wavefront.  Optical Pupil (Red)'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object WavefrontPaintBox: TPaintBox
      Left = 8
      Top = 24
      Width = 353
      Height = 257
      Color = cl3DLight
      ParentColor = False
      OnMouseDown = Button1MouseDown
      OnMouseMove = Form1MouseMove
    end
  end
  object Memo1: TMemo
    Left = 760
    Top = 88
    Width = 201
    Height = 489
    Lines.Strings = (
      '')
    TabOrder = 1
  end
  object GroupBox4: TGroupBox
    Left = 384
    Top = 0
    Width = 369
    Height = 289
    Caption = 'Membrane Surface'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    object MembranePaintBox: TPaintBox
      Left = 8
      Top = 24
      Width = 353
      Height = 257
      Color = cl3DLight
      ParentColor = False
      OnMouseDown = Button1MouseDown
      OnMouseMove = Form1MouseMove
      OnPaint = MembranePaintBoxPaint
    end
  end
  object GroupBox7: TGroupBox
    Left = 8
    Top = 288
    Width = 369
    Height = 289
    Caption = 'Electrode Voltage (Real)'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    object RealElectrodePaintBox: TPaintBox
      Left = 8
      Top = 24
      Width = 353
      Height = 257
      Color = cl3DLight
      ParentColor = False
      OnMouseDown = Button1MouseDown
      OnMouseMove = Form1MouseMove
      OnPaint = RealElectrodePaintBoxPaint
    end
  end
  object GroupBox8: TGroupBox
    Left = 384
    Top = 288
    Width = 369
    Height = 289
    Caption = 'Electrode Voltage (Imaginary)'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    object ImagElectrodePaintBox: TPaintBox
      Left = 8
      Top = 24
      Width = 353
      Height = 257
      Color = cl3DLight
      ParentColor = False
      OnMouseDown = Button1MouseDown
      OnMouseMove = Form1MouseMove
      OnPaint = RealElectrodePaintBoxPaint
    end
  end
  object GroupBox2: TGroupBox
    Left = 768
    Top = 8
    Width = 193
    Height = 73
    Caption = 'Viewer '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    object Label2: TLabel
      Left = 30
      Top = 40
      Width = 5
      Height = 20
      Caption = '°'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label1: TLabel
      Left = 118
      Top = 40
      Width = 5
      Height = 20
      Caption = '°'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object StaticText7: TStaticText
      Left = 104
      Top = 24
      Width = 70
      Height = 20
      Caption = 'StaticText7'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object StaticText8: TStaticText
      Left = 40
      Top = 48
      Width = 35
      Height = 20
      Caption = 'Sttxt8'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object StaticText9: TStaticText
      Left = 136
      Top = 48
      Width = 35
      Height = 20
      Caption = 'Sttxt9'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object StaticText1: TStaticText
      Left = 14
      Top = 40
      Width = 14
      Height = 27
      Caption = 'q'
      Font.Charset = SYMBOL_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Symbol'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
    object StaticText2: TStaticText
      Left = 102
      Top = 42
      Width = 15
      Height = 27
      Caption = 'f'
      Font.Charset = SYMBOL_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Symbol'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
    end
    object StaticText3: TStaticText
      Left = 38
      Top = 24
      Width = 36
      Height = 20
      Caption = 'r, mm'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
    end
  end
  object MainMenu1: TMainMenu
    Left = 144
    Top = 32
    object File1: TMenuItem
      Caption = 'File'
      object New1: TMenuItem
        Action = FileNew
        Caption = 'New'
      end
      object Open1: TMenuItem
        Action = FileOpen
      end
      object Solve1: TMenuItem
        Action = FileSave
        Caption = 'Save All'
      end
      object Exit1: TMenuItem
        Action = FileExit
        Caption = 'Exit'
      end
    end
    object Edit1: TMenuItem
      Caption = '&Edit'
      object Wavefront1: TMenuItem
        Action = EditWavefront
      end
      object Aberrations1: TMenuItem
        Action = EditAberrations
      end
      object Membrane1: TMenuItem
        Action = EditMembrane
      end
      object BiasLens1: TMenuItem
        Action = EditBiasLens
      end
    end
    object Wavefront2: TMenuItem
      Caption = 'Wavefront'
      object ZOffset1: TMenuItem
        Action = WavefrontZOffset
      end
      object Bias1: TMenuItem
        Action = WavefrontBias
      end
      object UnBias1: TMenuItem
        Action = WavefrontUnBias
      end
    end
    object Optics1: TMenuItem
      Caption = 'Run'
      object Simulation: TMenuItem
        Action = RunElectrodeSolver
        Caption = 'Electrode Solver'
      end
      object MembraneSolver1: TMenuItem
        Action = RunMembraneSolver
      end
    end
  end
  object ActionList1: TActionList
    Left = 208
    Top = 32
    object FileNew: TAction
      Category = 'File'
      Caption = 'FileNew'
      OnExecute = FileNewExecute
    end
    object FileSave: TAction
      Category = 'File'
      Caption = 'FileSave'
      OnExecute = FileSaveExecute
    end
    object FileExit: TAction
      Category = 'File'
      Caption = 'FileExit'
      OnExecute = FileExitExecute
    end
    object RunElectrodeSolver: TAction
      Category = 'Run'
      Caption = 'RunElectrodeSolver'
      OnExecute = RunElectrodeSolverExecute
    end
    object RunMembraneSolver: TAction
      Category = 'Run'
      Caption = 'Membrane Solver'
      OnExecute = RunMembraneSolverExecute
    end
    object EditWavefront: TAction
      Category = 'Edit'
      Caption = '&Wavefront'
      OnExecute = EditWavefrontExecute
    end
    object EditMembrane: TAction
      Category = 'Edit'
      Caption = '&Membrane'
      OnExecute = EditMembraneExecute
    end
    object EditBiasLens: TAction
      Category = 'Edit'
      Caption = '&Bias Lens'
      OnExecute = EditBiasLensExecute
    end
    object EditAberrations: TAction
      Category = 'Edit'
      Caption = '&Aberrations'
      OnExecute = EditAberrationsExecute
    end
    object WavefrontBias: TAction
      Category = 'Wavefront'
      Caption = 'Bias'
      OnExecute = WavefrontBiasExecute
    end
    object WavefrontUnBias: TAction
      Category = 'Wavefront'
      Caption = 'Un-Bias'
      OnExecute = WavefrontUnBiasExecute
    end
    object FileOpen: TAction
      Category = 'File'
      Caption = 'Open'
      OnExecute = FileOpenExecute
    end
    object WavefrontZOffset: TAction
      Category = 'Wavefront'
      Caption = 'Z Offset '
      OnExecute = WavefrontZOffsetExecute
    end
  end
  object ZCoeffFileOpenDialog: TOpenDialog
    Filter = 'Paradox 7-8 database files|*.DB'
    Left = 184
    Top = 128
  end
end
