unit MediathekViewExample;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Grids, Vcl.ValEdit, System.Generics.Collections,
  LaMitaMediathekView, IdHTTP, IdSSLOpenSSL, System.JSON, Vcl.Samples.Spin;

type
  TfrmMediathekViewExample = class(TForm)
    pnlTop: TPanel;
    edtSearchTerm: TEdit;
    lblSearchTerm: TLabel;
    pnlResults: TPanel;
    lvResults: TListView;
    splResults: TSplitter;
    pnlDetails: TPanel;
    memDetails: TMemo;
    lblResults: TLabel;
    lblDetails: TLabel;
    mediathekView: TLaMitaMediathekView;
    SpinEdit1: TSpinEdit;
    Label1: TLabel;
    pbProgress: TProgressBar;
    lblProgress: TLabel;
    btnSearch: TButton;
    btnCancel: TButton;
    cbPortal: TComboBox;
    Label2: TLabel;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure cbPortalChange(Sender: TObject);
    procedure lvResultsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure edtSearchTermKeyPress(Sender: TObject; var Key: Char);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mediathekViewSearchFinished(Sender: TObject; const SearchTerm:
        string; Results: TObjectList<LaMitaMediathekView.TMediathekViewItem>);

    procedure OnSearchProgress(Sender: TObject; Progress: Integer; const Status: string);
    procedure OnSearchError(Sender: TObject; const ErrorMessage: string);
    procedure SpinEdit1Change(Sender: TObject);

  private
    FCurrentResults: TObjectList<TMediathekViewItem>;
    procedure UpdateProgress(Progress: Integer; const Status: string);
    procedure DisplayResults(Results: TObjectList<TMediathekViewItem>);
    procedure DisplayItemDetails(Item: TMediathekViewItem);
    function FormatDuration(const Duration: string): string;
    function FormatDateTime(DateTime: TDateTime): string;

  public
    { Public declarations }
  end;

var
  frmMediathekViewExample: TfrmMediathekViewExample;

implementation

{$R *.dfm}

procedure TfrmMediathekViewExample.FormCreate(Sender: TObject);
begin
  FCurrentResults := TObjectList<TMediathekViewItem>.Create(False);

  // Komponente konfigurieren
  mediathekView.OnSearchProgress := OnSearchProgress;
  mediathekView.OnSearchError := OnSearchError;
  mediathekView.Timeout := 30000;
  mediathekView.MaxResults := 200;

  // UI initialisieren
  lvResults.ViewStyle := vsReport;

  lvResults.Columns.Clear;
  with lvResults.Columns.Add do begin Caption := 'Titel'; Width := 200; end;
  with lvResults.Columns.Add do begin Caption := 'Beschreibung'; Width := 250; end;
  with lvResults.Columns.Add do begin Caption := 'Sender'; Width := 80; end;
  with lvResults.Columns.Add do begin Caption := 'Thema'; Width := 120; end;
  with lvResults.Columns.Add do begin Caption := 'Datum'; Width := 90; end;
  with lvResults.Columns.Add do begin Caption := 'Zeit'; Width := 60; end;
  with lvResults.Columns.Add do begin Caption := 'Größe'; Width := 60; end;
  with lvResults.Columns.Add do begin Caption := 'Video-URL'; Width := 200; end;
  with lvResults.Columns.Add do begin Caption := 'Website-URL'; Width := 200; end;

  btnCancel.Enabled := False;
end;

procedure TfrmMediathekViewExample.FormDestroy(Sender: TObject);
begin
  FCurrentResults.Free;
end;

procedure TfrmMediathekViewExample.btnSearchClick(Sender: TObject);
begin
  if Trim(edtSearchTerm.Text) = '' then
  begin
    ShowMessage('Bitte geben Sie einen Suchbegriff ein.');
    edtSearchTerm.SetFocus;
    Exit;
  end;
  
  if mediathekView.IsSearching then
  begin
    ShowMessage('Eine Suche läuft bereits.');
    Exit;
  end;
  
  // UI für Suche vorbereiten
  btnSearch.Enabled := False;
  btnCancel.Enabled := True;

  lvResults.Items.Clear;
  memDetails.Clear;
  
   case  cbPortal.ItemIndex of
      0: begin           //mediathekview
          MediathekView.SearchSource := ssMediathekView;
      end;
      1 : begin
        MediathekView.SearchSource := ssArchiveOrgVideo;
      end;
      2 : begin
        MediathekView.SearchSource := ssArchiveOrgAudio;
      end;
      3 : begin
        MediathekView.JamendoClientID := 'YOUR CLIENT ID';
        MediathekView.SearchSource := ssJamendo;
      end;
   end;
   mediathekView.Search(edtSearchTerm.Text);
end;

procedure TfrmMediathekViewExample.btnCancelClick(Sender: TObject);
begin
  mediathekView.CancelSearch;
end;

procedure TfrmMediathekViewExample.cbPortalChange(Sender: TObject);
begin
  if cbportal.ItemIndex = 0 then Spinedit1.MaxValue := 99999 else SpinEdit1.maxvalue := 100;
end;

procedure TfrmMediathekViewExample.lvResultsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  MediathekItem: TMediathekViewItem;
begin
  if Selected and Assigned(Item) and (Item.Data <> nil) then
  begin
    MediathekItem := TMediathekViewItem(Item.Data);
    DisplayItemDetails(MediathekItem);
  end
  else
  begin
    memDetails.Clear;
  end;
end;




procedure TfrmMediathekViewExample.edtSearchTermKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then // Enter-Taste
  begin
    Key := #0;
    btnSearchClick(Sender);
  end;
end;

procedure TfrmMediathekViewExample.OnSearchProgress(Sender: TObject; Progress: Integer; const Status: string);
begin
  UpdateProgress(Progress, Status);
end;

procedure TfrmMediathekViewExample.OnSearchError(Sender: TObject; const ErrorMessage: string);
begin
  // UI zurücksetzen
  btnSearch.Enabled := True;
  btnCancel.Enabled := False;

  
  // Fehler anzeigen
  ShowMessage('Fehler bei der Suche: ' + ErrorMessage);
end;

procedure TfrmMediathekViewExample.UpdateProgress(Progress: Integer; const Status: string);
begin
  pbProgress.Position := Progress;
  lblProgress.Caption := Status;
  Application.ProcessMessages;
end;

procedure TfrmMediathekViewExample.DisplayResults(Results: TObjectList<TMediathekViewItem>);
var
  i: Integer;
  Item: TListItem;
  MediathekItem, CopyItem: TMediathekViewItem;
begin
  lvResults.Items.Clear;
  memDetails.Clear;

  // Aktuelle Ergebnisse speichern (DEEP COPY!)
  FCurrentResults.Clear;
  for i := 0 to Results.Count - 1 do
  begin
    MediathekItem := Results[i];
    CopyItem := TMediathekViewItem.Create;
    CopyItem.Title := MediathekItem.Title;
    CopyItem.Description := MediathekItem.Description;
    CopyItem.Duration := MediathekItem.Duration;
    CopyItem.Date := MediathekItem.Date;
    CopyItem.Time := MediathekItem.Time;
    CopyItem.Channel := MediathekItem.Channel;
    CopyItem.Topic := MediathekItem.Topic;
    CopyItem.VideoURL := MediathekItem.VideoURL;
    CopyItem.WebsiteURL := MediathekItem.WebsiteURL;
    CopyItem.Size := MediathekItem.Size;
    FCurrentResults.Add(CopyItem);
  end;

  // ListView mit Ergebnissen füllen
for i := 0 to FCurrentResults.Count - 1 do
begin
  MediathekItem := FCurrentResults[i];
  Item := lvResults.Items.Add;
  Item.Caption := MediathekItem.Title;
  Item.SubItems.Add(MediathekItem.Description);
  Item.SubItems.Add(MediathekItem.Channel);
  Item.SubItems.Add(MediathekItem.Topic);
  Item.SubItems.Add(FormatDateTime(MediathekItem.Date));
  Item.SubItems.Add(FormatDuration(MediathekItem.Duration));
  Item.SubItems.Add(MediathekItem.Size+'kb');
  Item.SubItems.Add(MediathekItem.VideoURL);
  Item.SubItems.Add(MediathekItem.WebsiteURL); // Bild-URL (ggf. anpassen)
  Item.Data := MediathekItem;
end;

  lblResults.Caption := Format('Ergebnisse: %d', [FCurrentResults.Count]);
end;

procedure TfrmMediathekViewExample.DisplayItemDetails(Item: TMediathekViewItem);
var
  Details: TStringList;
begin
  Details := TStringList.Create;
  try
    Details.Add('=== DETAILS ===');
    Details.Add('');
    Details.Add('Titel: ' + Item.Title);
    Details.Add('Sender: ' + Item.Channel);
    Details.Add('Thema: ' + Item.Topic);
    Details.Add('Datum: ' + FormatDateTime(Item.Date));
    Details.Add('Zeit: ' + Item.Time);
    Details.Add('Dauer: ' + FormatDuration(Item.Duration));
    Details.Add('Größe: ' + Item.Size);
    Details.Add('');
    Details.Add('=== BESCHREIBUNG ===');
    Details.Add(Item.Description);
    Details.Add('');
    Details.Add('=== LINKS ===');
    Details.Add('Video URL: ' + Item.VideoURL);
    Details.Add('Website URL: ' + Item.WebsiteURL);
    
    memDetails.Text := Details.Text;
  finally
    Details.Free;
  end;
end;

function TfrmMediathekViewExample.FormatDuration(const Duration: string): string;
begin
  if Duration = '' then
    Result := '--:--'
  else
    Result := Duration;
end;

function TfrmMediathekViewExample.FormatDateTime(DateTime: TDateTime): string;
begin
  if DateTime = 0 then
    Result := '--'
  else
    Result := DateToStr(DateTime);
end;

procedure TfrmMediathekViewExample.FormCloseQuery(Sender: TObject; var
    CanClose: Boolean);
var
  memmgr: TMemoryManager;
begin
  try
    exitproc := nil;
    ExceptProc := nil;
    ErrorProc := nil;
    SetRaiseList(nil);
    LibModuleList := nil;
    ModuleUnloadList := nil;
    // ask windows nicely to kill us. (well, as nice as we get here)
    TerminateProcess(GetCurrentProcess, 0);
    // what - still here? Surely not, Let's pop the stack
    while true do
      asm
         pop eax;
      end;
  finally
    // we don't believe you could ever get here. but if we do,
    // well, we'll just make sure that nothing will ever work again anyway.
    memmgr.GetMem := nil;
    memmgr.FreeMem := nil;
    memmgr.ReallocMem := nil;
    SetMemoryManager(memmgr);
  end;
end;

procedure TfrmMediathekViewExample.mediathekViewSearchFinished(Sender: TObject;
    const SearchTerm: string; Results:
    TObjectList<LaMitaMediathekView.TMediathekViewItem>);
begin
  // UI zurücksetzen
  btnSearch.Enabled := True;
  btnCancel.Enabled := False;


  // Ergebnisse anzeigen
  DisplayResults(Results);

  // Status anzeigen
  if Results.Count > 0 then
    ShowMessage(Format('Suche abgeschlossen. %d Ergebnisse gefunden.', [Results.Count]))
  else
    ShowMessage('Keine Ergebnisse gefunden.');
end;

procedure TfrmMediathekViewExample.SpinEdit1Change(Sender: TObject);
begin
 mediathekView.MaxResults := SpinEdit1.Value;
end;

end.