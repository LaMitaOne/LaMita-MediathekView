program Project11;

uses
  Vcl.Forms,
  MediathekViewExample in 'MediathekViewExample.pas' {frmMediathekViewExample},
  LaMitaMediathekView in 'LaMitaMediathekView.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMediathekViewExample, frmMediathekViewExample);
  Application.Run;
end.
