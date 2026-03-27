unit GrilleSetup;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.StdCtrls, CipherGrile,
  Vcl.ExtCtrls;

type
  TfGrilleSetup = class(TForm)
    sgGrille: TStringGrid;
    btnOk: TButton;
    btnCancel: TButton;
    pEdit: TPanel;
    procedure FormShow(Sender: TObject);
    procedure sgGrilleMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure btnOkClick(Sender: TObject);
  private
    { Private declarations }
  public
    GridSize: Integer;
    UserHoles: TCipMatrix;
  end;

var
  fGrilleSetup: TfGrilleSetup;

implementation

{$R *.dfm}

procedure TfGrilleSetup.FormShow(Sender: TObject);
var
  c, r, GridW, GridH: Integer;
begin
  sgGrille.ColCount := GridSize;
  sgGrille.RowCount := GridSize;

  for r := 0 to sgGrille.RowCount - 1 do
    for c := 0 to sgGrille.ColCount - 1 do
      sgGrille.Cells[c, r] := '';

  if GridSize mod 2 = 1 then
    sgGrille.Cells[GridSize div 2, GridSize div 2] := 'X';

  GridW := (GridSize * sgGrille.DefaultColWidth) + GridSize;
  GridH := (GridSize * sgGrille.DefaultRowHeight) + GridSize;


  sgGrille.Width := GridW + 4;
  sgGrille.Height := GridH + 4;
  sgGrille.Left := 15;
  ClientWidth := sgGrille.Width + 15; // 15 пикс отступ слева + 15 справа
  ClientHeight := sgGrille.Height + 60; // Высота сетки + место под кнопки внизу

  // Защита: если сетка очень маленькая (например, 2x2), форма не должна быть слишком узкой,
  // иначе не поместятся кнопки "Сохранить" и "Отмена"
  if ClientWidth < 200 then
    ClientWidth := 200;

end;


// НОВАЯ ЛОГИКА КЛИКА МЫШКОЙ
procedure TfGrilleSetup.sgGrilleMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ACol, ARow: Integer;
  X1, Y1, X2, Y2, X3, Y3: Integer;
begin
  // Встроенная функция StringGrid, которая переводит координаты мышки (X,Y) в номер ячейки (Колонка, Строка)
  sgGrille.MouseToCell(X, Y, ACol, ARow);

  // Если кликнули мимо ячеек (например, по границе), ничего не делаем
  if (ACol < 0) or (ARow < 0) then Exit;

  // Блокируем изменение центральной ячейки
  if (GridSize mod 2 = 1) and (ACol = GridSize div 2) and (ARow = GridSize div 2) then
  begin
    ShowMessage('Центральная ячейка используется только при первом повороте, она должна быть вырезана всегда.');
    Exit;
  end;

  if sgGrille.Cells[ACol, ARow] = 'X' then
  begin
    sgGrille.Cells[ACol, ARow] := '';
    Exit;
  end;

  X1 := GridSize - 1 - ARow;
  Y1 := ACol;
  X2 := GridSize - 1 - ACol;
  Y2 := GridSize - 1 - ARow;
  X3 := ARow;
  Y3 := GridSize - 1 - ACol;

  if (sgGrille.Cells[X1, Y1] = 'X') or
     (sgGrille.Cells[X2, Y2] = 'X') or
     (sgGrille.Cells[X3, Y3] = 'X') then
  begin
    ShowMessage('Эта позиция перекрывается с уже выбранным отверстием при повороте!');
    Exit;
  end;

  sgGrille.Cells[ACol, ARow] := 'X';
end;


procedure TfGrilleSetup.btnOkClick(Sender: TObject);
var
  c, r, ExpectedHoles, UserCount: Integer;
begin
  ExpectedHoles := (GridSize * GridSize) div 4;
  UserCount := 0;

  for r := 0 to sgGrille.RowCount - 1 do
    for c := 0 to sgGrille.ColCount - 1 do
      if (sgGrille.Cells[c, r] = 'X') then
      begin
        if (GridSize mod 2 = 1) and (c = GridSize div 2) and (r = GridSize div 2) then
          Continue;
        Inc(UserCount);
      end;

  if UserCount <> ExpectedHoles then
  begin
    ShowMessage(Format('Ошибка: Для матрицы %dx%d нужно вырезать %d отверстий (не считая центра). Вырезано: %d',
      [GridSize, GridSize, ExpectedHoles, UserCount]));
    ModalResult := mrNone;
    Exit;
  end;

  SetLength(UserHoles, 0);
  for r := 0 to sgGrille.RowCount - 1 do
    for c := 0 to sgGrille.ColCount - 1 do
      if (sgGrille.Cells[c, r] = 'X') then
      begin
        if (GridSize mod 2 = 1) and (c = GridSize div 2) and (r = GridSize div 2) then
          Continue;
        SetLength(UserHoles, Length(UserHoles) + 1);
        UserHoles[High(UserHoles)].X := c;
        UserHoles[High(UserHoles)].Y := r;
      end;

  if GridSize mod 2 = 1 then
  begin
    SetLength(UserHoles, Length(UserHoles) + 1);
    UserHoles[High(UserHoles)].X := GridSize div 2;
    UserHoles[High(UserHoles)].Y := GridSize div 2;
  end;
end;

end.
