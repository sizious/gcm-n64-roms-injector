unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, XPMan, ComCtrls, AppEvnts;

type
  TfrmMain = class(TForm)
    GroupBox1: TGroupBox;
    eGCM: TEdit;
    bGCM: TBitBtn;
    GroupBox2: TGroupBox;
    eROM: TEdit;
    bROM: TBitBtn;
    GroupBox3: TGroupBox;
    eGameTitle: TEdit;
    Bevel1: TBevel;
    bInj: TBitBtn;
    BitBtn4: TBitBtn;
    XPManifest1: TXPManifest;
    odGCM: TOpenDialog;
    odROM: TOpenDialog;
    cbPatch: TCheckBox;
    pb: TProgressBar;
    Bevel2: TBevel;
    sdGCM: TSaveDialog;
    ApplicationEvents1: TApplicationEvents;
    sb: TStatusBar;
    BitBtn1: TBitBtn;
    procedure bGCMClick(Sender: TObject);
    procedure bROMClick(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure bInjClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
    procedure BitBtn1Click(Sender: TObject);
  private
    function GetFileSize(const FileName: TFileName): DWord;
    procedure StringToArray(const S: string; var A: array of Char);
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  SHFileOp, about;
  
{$R *.dfm}

const
  MAX_SIZE  = 33554432;
  ROM_ADDR  = $1C39FC0;
  DB_SIZE   = 2048;
  NAME_ADDR = $20;
  TITLE_SIZE = 992;
  
procedure TfrmMain.bGCMClick(Sender: TObject);
begin
  with odGCM do
    if Execute then eGCM.Text := FileName;
end;

procedure TfrmMain.bROMClick(Sender: TObject);
begin
  with odROM do
    if Execute then
    begin
      eROM.Text := FileName;
      eGameTitle.Text := ExtractFileName(ChangeFileExt(FileName, ''));
    end;
end;

procedure TfrmMain.BitBtn4Click(Sender: TObject);
begin
  Close;
end;

function TfrmMain.GetFileSize(const FileName : TFileName) : DWord;
var
  F : File;

begin
  Result := 0;
  if not FileExists(FileName) then Exit;

  AssignFile(F, FileName);
  ReSet(F, 1);
  Result := FileSize(F);
  CloseFile(F);
end;

procedure TfrmMain.StringToArray(const S : string ; var A : array of Char);
var
  i : Integer;

begin
  ZeroMemory(@A, SizeOf(A));
  
  for i := 1 to Length(S) do
    A[i - 1] := S[i];
end;

procedure TfrmMain.bInjClick(Sender: TObject);
var
  fsROM, fsEmu : TFileStream;
  strEmulator : string;
  datasBlock : array[0..DB_SIZE - 1] of Byte;
  gameTitle : array[0..TITLE_SIZE - 1] of Char;
  
begin
  // émulateur
  if not FileExists(eGCM.Text) then
  begin
    MessageBoxA(Handle, 'Please enter the full path to the emulator.', 'Warning', MB_ICONWARNING);
    Exit;
  end;

  // rom
  if not FileExists(eROM.Text) then
  begin
    MessageBoxA(Handle, 'Please enter the full path to the ROM.', 'Warning', MB_ICONWARNING);
    Exit;
  end;

  // vérifier la taille
  if GetFileSize(eROM.Text) > MAX_SIZE then
  begin
    MessageBoxA(Handle, 'Error, your ROM is too big.', 'Warning', MB_ICONWARNING);
    Exit;
  end;
  
  // on commence
  bInj.Enabled := False;
  
  if cbPatch.Checked then
    strEmulator := eGCM.Text
  else
      with sdGCM do
      begin
        FileName := eGameTitle.Text;
        if Execute then
          begin
            strEmulator := FileName;
            sb.SimpleText := 'Copying source emulator... Please wait.';
            if not SHCopyFiles(eGCM.Text, strEmulator, [], 'Copy') then
            begin
              sb.SimpleText := '';
              bInj.Enabled := True;
              Exit;
            end;
          end
        else
        begin
          sb.SimpleText := '';
          bInj.Enabled := True;
          Exit;
        end;
      end;

  fsROM := TFileStream.Create(eROM.Text, fmOpenRead);
  try

    fsEmu := TFileStream.Create(strEmulator, fmOpenWrite);
    try

      // écrire la rom dans le GCM
      sb.SimpleText := 'Writing ROM...';
      
      fsEmu.Seek(ROM_ADDR, soFromBeginning);

      pb.Max := fsROM.Size;
      pb.Step := DB_SIZE;

      while fsROM.Position < fsROM.Size do
      begin
        Application.ProcessMessages;
        fsROM.Read(datasBlock, DB_SIZE);
        fsEmu.Write(datasBlock, DB_SIZE);
        pb.StepIt;
      end;

      // écrire le nom du jeu dans l'header du GCM
      StringToArray(eGameTitle.Text, gameTitle);
      fsEmu.Seek(NAME_ADDR, soFromBeginning);
      fsEmu.Write(gameTitle, TITLE_SIZE);

    finally
      fsEmu.Free;
    end;

  finally
    fsROM.Free;
  end;

  sb.SimpleText := 'Done !';
  MessageBoxA(Handle, 'Well done ! You can now use your new image.', 'Well done !', MB_ICONINFORMATION);
  pb.Position := 0;
  bInj.Enabled := True;
  sb.SimpleText := '';
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Application.Title := Caption;
end;

procedure TfrmMain.ApplicationEvents1Exception(Sender: TObject;
  E: Exception);
begin
  bInj.Enabled := True;
  sb.SimpleText := '';
end;

procedure TfrmMain.BitBtn1Click(Sender: TObject);
begin
  AboutBox.ShowModal;
end;

end.
