unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ExtDlgs, Vcl.Samples.Spin;



type
  TfMain = class(TForm)
    pcMain: TPageControl;
    tsGrile: TTabSheet;
    tsVigener: TTabSheet;
    pgEdits: TPanel;
    pgControl: TPanel;
    cgSelectLang: TComboBox;
    lgLang: TLabel;
    mgOut: TMemo;
    bgStart: TButton;
    lgMatrix: TLabel;
    cgSelectMode: TComboBox;
    lCipher: TLabel;
    bgOpen: TButton;
    bgSave: TButton;
    stfDialog: TSaveTextFileDialog;
    otfDialog: TOpenTextFileDialog;
    pvControl: TPanel;
    lvLang: TLabel;
    lvKey: TLabel;
    lvMode: TLabel;
    cvSelectLang: TComboBox;
    bvStart: TButton;
    evKey: TEdit;
    cvSelectMode: TComboBox;
    bvOpen: TButton;
    bvSave: TButton;
    pvEdits: TPanel;
    mvIn: TMemo;
    mvOut: TMemo;
    mgIn: TMemo;
    segMatrix: TSpinEdit;
    procedure bgStartClick(Sender: TObject);
    procedure bgOpenClick(Sender: TObject);
    procedure bgSaveClick(Sender: TObject);
    procedure bvOpenClick(Sender: TObject);
    procedure bvSaveClick(Sender: TObject);
    procedure bvStartClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
  TLang = (langNone = -1, langEn = 0, langRu = 1);

var
  fMain: TfMain;

implementation

{$R *.dfm}

uses CipherGrile, CipherVigenere;



procedure TfMain.bgOpenClick(Sender: TObject);
begin
  if otfDialog.Execute then
  begin
    mgIn.Lines.LoadFromFile(otfDialog.FileName);
  end;
end;

procedure TfMain.bgSaveClick(Sender: TObject);
begin
  if stfDialog.Execute then
  begin
    mgIn.Lines.SaveToFile(stfDialog.FileName);
  end;
end;

procedure TfMain.bgStartClick(Sender: TObject);
var
  lang: TLang;
begin
  FillMatrix(StrToInt(segMatrix.Text));
  lang := TLang(cgSelectLang.ItemIndex);
  if cgSelectMode.ItemIndex = 1 then
    mgOut.Text := DecipherGrile(mgIn.Text, lang)
  else
    mgOut.Text := EncryptGrile(mgIn.Text, lang);

end;



procedure TfMain.bvOpenClick(Sender: TObject);
begin
  if otfDialog.Execute then
  begin
    mvIn.Lines.LoadFromFile(otfDialog.FileName);
  end;
end;

procedure TfMain.bvSaveClick(Sender: TObject);
begin
  if stfDialog.Execute then
  begin
    mvIn.Lines.SaveToFile(stfDialog.FileName);
  end;
end;

procedure TfMain.bvStartClick(Sender: TObject);
var
  lang: TLang;
begin
  FillMatrix(StrToInt(segMatrix.Text));
  lang := TLang(cvSelectLang.ItemIndex);
  if cvSelectMode.ItemIndex = 1 then
    mvOut.Text := DecipherVigenere(mvIn.Text,evKey.Text, lang)
  else
    mvOut.Text := EncryptVigenere(mvIn.Text,evKey.Text, lang);

end;
end.
