unit CipherGrile;

interface

uses Main;

type
  // Вынесли тип сюда, чтобы его видела новая форма настройки
  TCipMatrix = array of record
    X: Byte;
    Y: Byte;
  end;

procedure FillMatrix(gSize: Integer);
procedure SetUserMatrix(gSize: Integer; const UserHoles: TCipMatrix); // Новая процедура
function EncryptGrile(text: String; Lang: TLang): String;
function DecipherGrile(text: String; Lang: TLang): String;
function GetFreeText(const text: string; Lang: TLang): string;

implementation

uses System.SysUtils;

type
  TSymbMatrix = array of array of Char;

var
  CipMatrix: TCipMatrix;
  GrileSize: Integer;

  function GetFreeText(const text: string; Lang: TLang): string;
  const
    ALPH_RU = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя';
    ALPH_EN = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  var
    i: Integer;
  begin
    Result := '';

    if Lang = langNone then
      Result := text
    else
      for i := 1 to Length(text) do
      begin
        case Lang of
          langEn:
            if Pos(text[i], ALPH_EN) > 0 then
              Result := Result + text[i];

          langRu:
            if Pos(text[i], ALPH_RU) > 0 then
              Result := Result + text[i];
        end;
      end;
  end;

  procedure FillMatrix(gSize: Integer);
  var
    I, J, K, N: Integer;
    Temp: Byte;
  begin
    GrileSize := gSize;
    SetLength(CipMatrix, (Sqr(gSize) - 1) div 4 + 1);

    I:=0;
    for J := 0 to (gSize - 1) shr 1 do
    begin
      for K := J to gSize - 2 - J do
      begin
        CipMatrix[I].X := K;
        CipMatrix[I].Y := J;
        for N := 1 to I mod 4 do
        begin
          Temp := CipMatrix[I].Y;
          CipMatrix[I].Y := CipMatrix[I].X;
          CipMatrix[I].X := gSize - Temp - 1;
        end;
        inc(I);
      end;
    end;

    if gSize mod 2 = 1 then
    begin
      CipMatrix[High(CipMatrix)].X := (gSize - 1) shr 1;
      CipMatrix[High(CipMatrix)].Y := (gSize - 1) shr 1;
    end;
  end;

  // НОВАЯ ПРОЦЕДУРА: принимает матрицу от пользователя
  procedure SetUserMatrix(gSize: Integer; const UserHoles: TCipMatrix);
  var
    I: Integer;
  begin
    GrileSize := gSize;
    SetLength(CipMatrix, Length(UserHoles));
    for I := Low(UserHoles) to High(UserHoles) do
    begin
      CipMatrix[I].X := UserHoles[I].X;
      CipMatrix[I].Y := UserHoles[I].Y;
    end;
  end;

  function EncryptGrile(text: String; Lang: TLang): String;
  var
    SymbMatrix: TSymbMatrix;
    CopyCipMatrix: TCipMatrix;
    I, J, K, CurSumb, OutSumb, Temp: Integer;
  begin
    text := GetFreeText(text, Lang);
    CopyCipMatrix := Copy(CipMatrix, Low(CipMatrix), Length(CipMatrix));
    Result := '';
    SetLength(SymbMatrix, GrileSize, GrileSize);
    CurSumb := 1;
    OutSumb := 1;
    for I := 1 to (Length(text) + Sqr(GrileSize) - 1) div (Sqr(GrileSize)) do
    begin
      for J := 1 to 4 do
      begin
        for K := Low(CopyCipMatrix) to High(CopyCipMatrix) do
          if (K < High(CopyCipMatrix)) or ((GrileSize mod 2 = 0) or (J = 1))  then
          begin
            if CurSumb <= Length(text) then
            begin
              SymbMatrix[CopyCipMatrix[K].Y][CopyCipMatrix[K].X] := text[CurSumb];
              Inc(CurSumb);
            end
            else
              SymbMatrix[CopyCipMatrix[K].Y][CopyCipMatrix[K].X] := text[Random(Length(text)) + 1];
          end;
          for K := Low(CopyCipMatrix) to High(CopyCipMatrix) do
          begin
            Temp := CopyCipMatrix[K].Y;
            CopyCipMatrix[K].Y := CopyCipMatrix[K].X;
            CopyCipMatrix[K].X := GrileSize - Temp - 1;
          end;
      end;
      SetLength(Result, OutSumb + Sqr(GrileSize));
      for J :=  Low(SymbMatrix) to High(SymbMatrix) do
        for K := Low(SymbMatrix) to High(SymbMatrix) do
          begin
            Result[OutSumb] :=  SymbMatrix[J][K];
            Inc(OutSumb);
          end;
    end;
  end;

  function DecipherGrile(text: String; Lang: TLang): String;
  var
    SymbMatrix: TSymbMatrix;
    CopyCipMatrix: TCipMatrix;
    I, J, K, CurSumb, OutSumb, Temp: Integer;
  begin
    text := GetFreeText(text, Lang);
    CopyCipMatrix := Copy(CipMatrix, Low(CipMatrix), Length(CipMatrix));
    SetLength(SymbMatrix, GrileSize, GrileSize);
    CurSumb := 1;
    OutSumb := 1;
    for I := 1 to (Length(text) + Sqr(GrileSize) - 1) div Sqr(GrileSize) do
    begin
      SetLength(Result, OutSumb + Sqr(GrileSize));
      for J :=  Low(SymbMatrix) to High(SymbMatrix) do
        for K := Low(SymbMatrix) to High(SymbMatrix) do
          begin
            if CurSumb <= Length(text) then
            begin
              SymbMatrix[J][K] := text[CurSumb];
              Inc(CurSumb);
            end
           else
             SymbMatrix[J][K] := ' ';
          end;

      for J := 1 to 4 do
      begin
        for K := Low(CopyCipMatrix) to High(CopyCipMatrix) do
          if (K < High(CopyCipMatrix)) or ((GrileSize mod 2 = 0) or (J = 1))  then
          begin
              Result[OutSumb] := SymbMatrix[CopyCipMatrix[K].Y][CopyCipMatrix[K].X];
              Inc(OutSumb);
          end;
        for K := Low(CopyCipMatrix) to High(CopyCipMatrix) do
        begin
          Temp := CopyCipMatrix[K].Y;
          CopyCipMatrix[K].Y := CopyCipMatrix[K].X;
          CopyCipMatrix[K].X := GrileSize - Temp - 1;
        end;
      end;
    end;
  end;

end.

