unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ExtDlgs, Vcl.Samples.Spin, System.Math;

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
    cbOpti: TCheckBox;
    lGrille: TLabel;
    btnSetupGrille: TButton; // <-- НОВАЯ КНОПКА ДЛЯ ВЫЗОВА ФОРМЫ
    procedure bgStartClick(Sender: TObject);
    procedure bgOpenClick(Sender: TObject);
    procedure bgSaveClick(Sender: TObject);
    procedure bvOpenClick(Sender: TObject);
    procedure bvSaveClick(Sender: TObject);
    procedure bvStartClick(Sender: TObject);
    procedure cbOptiClick(Sender: TObject);
    procedure mgInChange(Sender: TObject);
    procedure btnSetupGrilleClick(Sender: TObject); // <-- ОБРАБОТЧИК НОВОЙ КНОПКИ
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

uses CipherGrile, CipherVigenere, GrilleSetup; // <-- ДОБАВИЛИ GRILLESETUP

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

procedure TfMain.btnSetupGrilleClick(Sender: TObject);
begin
  // Передаем размер матрицы в новую форму
  fGrilleSetup.GridSize := segMatrix.Value;

  // Открываем форму как модальное окно
  if fGrilleSetup.ShowModal = mrOk then
  begin
    // Передаем выбранные ячейки в шифратор
    SetUserMatrix(segMatrix.Value, fGrilleSetup.UserHoles);
    ShowMessage('Трафарет успешно задан!');
  end;
end;

procedure TfMain.bgStartClick(Sender: TObject);
var
  lang: TLang;
begin
  // Если матрица НЕ была задана визуально, используем стандартную генерацию
  if (fGrilleSetup = nil) or (Length(fGrilleSetup.UserHoles) = 0) then
    FillMatrix(StrToInt(segMatrix.Text))
  else
    // Если была задана, обновляем её на случай, если пользователь поменял размер в SpinEdit, но не переоткрыл окно
    SetUserMatrix(segMatrix.Value, fGrilleSetup.UserHoles);

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
  lang := TLang(cvSelectLang.ItemIndex);
  if cvSelectMode.ItemIndex = 1 then
    mvOut.Text := DecipherVigenere(mvIn.Text, evKey.Text, lang)
  else
    mvOut.Text := EncryptVigenere(mvIn.Text, evKey.Text, lang);
end;

procedure TfMain.cbOptiClick(Sender: TObject);
begin
  segMatrix.Enabled := not cbOpti.Checked;
  mgInChange(mgIn);
end;

procedure TfMain.mgInChange(Sender: TObject);
begin
  if cbOpti.Checked then
    segMatrix.Text := IntToStr(Max(1, Ceil(Sqrt(Length(GetFreeText(mgIn.Text, TLang(cgSelectLang.ItemIndex)))))));
end;

end.

