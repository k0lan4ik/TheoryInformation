unit CipherVigenere;

interface


uses Main;

function EncryptVigenere(text: String; key: String; lang: TLang): String;
function DecipherVigenere(text: String; key: String; lang: TLang): String;
//function EncryptVigenere(text:String; key: String; lang:TLang):String;
//function DecipherVigenere(text:String; key: String; lang:TLang):String;

implementation

uses SysUtils;

const
  AlphaEn = 'abcdefghijklmnopqrstuvwxyz';
  AlphaEnU = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  AlphaRu = 'àáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ';
  AlphaRuU = 'ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß';



function VigenereProcess(text, key: string; lang: TLang; encrypt: Integer): string;
var
  I, J, index, count:Integer;
  Alpha,AlphaU: String;
  RKey: array of Byte;
begin
  Alpha := '';
  AlphaU := '';
  if lang = langEn then
  begin
    Alpha := AlphaEn;
    AlphaU := AlphaEnU;
  end
  else if lang = langRu then
  begin
    Alpha := AlphaRu;
    AlphaU := AlphaRuU;
  end;



  SetLength(RKey, 4);
  Count := 0;
  for I := Low(key) to High(key) do
  begin
    index := Pos(key[i],Alpha);
    if index = 0 then
    begin
      index := Pos(key[i],AlphaU);
    end;
    if index > 0 then
    begin
      if Count = Length(Rkey) then
        SetLength(Rkey, Count shl 1);
      RKey[Count] := index-1;
      Inc(Count);
    end;
  end;
  SetLength(Rkey, Count);

  Result := text;
  if count > 0 then
  begin
    count := 0;
    for I := Low(Result) to High(Result) do
    begin
      index := Pos(Result[i],Alpha);
      if index > 0 then
      begin
        Result[i] := Alpha[(Length(Alpha)-1 + (index) + encrypt * (Rkey[count])) mod Length(Alpha) + 1];
        count := (count + 1) mod Length(Rkey);
        if count = 0 then
        for J := Low(Rkey) to High(Rkey) do
          Rkey[J] := (Rkey[J] + 1) mod Length(Alpha);
      end
      else
      begin
        index := Pos(Result[i],AlphaU);
        if index > 0 then
        begin
          Result[i] := AlphaU[(Length(AlphaU)-1 + (index) + encrypt * (Rkey[count])) mod Length(AlphaU) + 1];
          count := (count + 1) mod Length(Rkey);
          if count = 0 then
          for J := Low(Rkey) to High(Rkey) do
            Rkey[J] := (Rkey[J] + 1) mod Length(Alpha);
        end;
      end;

    end;

  end;

end;

  function EncryptVigenere(text: string; key: string; lang: TLang): string;
  begin
    Result := VigenereProcess(text, key, lang, 1);
  end;

  function DecipherVigenere(text: string; key: string; lang: TLang): string;
  begin
    Result := VigenereProcess(text, key, lang, -1);
  end;


end.
