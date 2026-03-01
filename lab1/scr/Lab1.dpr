program Lab1;

uses
  Vcl.Forms,
  Main in 'Main.pas' {fMain},
  CipherGrile in 'CipherGrile.pas',
  CipherVigenere in 'CipherVigenere.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
