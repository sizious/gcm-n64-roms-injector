program n64inj;

uses
  Forms,
  main in 'main.pas' {frmMain},
  SHFileOp in 'shfileop.pas',
  about in 'about.pas' {AboutBox};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.Run;
end.
