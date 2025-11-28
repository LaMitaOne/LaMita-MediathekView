{------------------------------------------------------------------------------}
{                                                                              }
{  MediathekSearch v0.3                                                            }
{  by Lara Miriam Tamy Reschke                                                 }
{                                                                              }
{  larate@gmx.net                                                              }
{  https://lamita.jimdosite.com                                                }
{                                                                              }
{------------------------------------------------------------------------------}
{
 ----latest Changes
  v 0.3
    -added search in jamendo.com with apikey
  v 0.2
    -added search in archive.org
  v 0.1
    -first release 

}

unit LaMitaMediathekView;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections, 
  System.Threading, System.DateUtils, System.NetEncoding, IdHTTP, IdSSLOpenSSL,
  IdGlobal, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdURI, Dialogs,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Forms, System.Net.HttpClient;

type
  TSearchSource = (ssMediathekView, ssArchiveOrgVideo, ssArchiveOrgAudio, ssJamendo);

type
  TMediathekViewItem = class
  private
    FTitle: string;
    FDescription: string;
    FDuration: string;
    FDate: TDateTime;
    FTime: string;
    FChannel: string;
    FTopic: string;
    FVideoURL: string;
    FWebsiteURL: string;
    FThumbnailURL: string;
    FSize: string;
  public
    property Title: string read FTitle write FTitle;
    property Description: string read FDescription write FDescription;
    property Duration: string read FDuration write FDuration;
    property Date: TDateTime read FDate write FDate;
    property Time: string read FTime write FTime;
    property Channel: string read FChannel write FChannel;
    property Topic: string read FTopic write FTopic;
    property VideoURL: string read FVideoURL write FVideoURL;
    property WebsiteURL: string read FWebsiteURL write FWebsiteURL;
    property ThumbnailURL: string read FThumbnailURL write FThumbnailURL;
    property Size: string read FSize write FSize;
  end;

  TMediathekViewSearchEvent = procedure(Sender: TObject; const SearchTerm: string; 
    Results: TObjectList<TMediathekViewItem>) of object;
  TMediathekViewProgressEvent = procedure(Sender: TObject; Progress: Integer; 
    const Status: string) of object;
  TMediathekViewErrorEvent = procedure(Sender: TObject; const ErrorMessage: string) of object;

  TLaMitaMediathekView = class(TComponent)
  private
    FHTTPClient: TIdHTTP;
    FSSLHandler: TIdSSLIOHandlerSocketOpenSSL;
    FSearchTerm: string;
    FResults: TObjectList<TMediathekViewItem>;
    FOnSearchFinished: TMediathekViewSearchEvent;
    FOnSearchProgress: TMediathekViewProgressEvent;
    FOnSearchError: TMediathekViewErrorEvent;
    FIsSearching: Boolean;
    FBaseURL: string;
    FJamendoClientID: string;
    FTimeout: Integer;
    FMaxResults: Integer;
    FSearchInProgress: Boolean;
    FCurrentTask: ITask;
    FSearchSource: TSearchSource;

    function ParseSearchResults(const JSONData: string): TObjectList<TMediathekViewItem>;
    function ExtractVideoURL(const ItemData: TJSONObject): string;
    function ExtractWebsiteURL(const ItemData: TJSONObject): string;
    function ParseDateTime(const DateTimeStr: string): TDateTime;
    function PerformSearch(const SearchTerm: string): string;
    
  protected
    procedure DoSearchProgress(Progress: Integer; const Status: string);
    procedure DoSearchFinished(const SearchTerm: string; Results: TObjectList<TMediathekViewItem>);
    procedure DoSearchError(const ErrorMessage: string);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function Search(const SearchTerm: string): Boolean;
    function SearchAsync(const SearchTerm: string): ITask;
    procedure CancelSearch;
    
    property Results: TObjectList<TMediathekViewItem> read FResults;
    property IsSearching: Boolean read FIsSearching;
    property JamendoClientID: string read FJamendoClientID write FJamendoClientID;  // Neu: Für deinen Key
  published
    property BaseURL: string read FBaseURL write FBaseURL;
    property Timeout: Integer read FTimeout write FTimeout default 30000;
    property MaxResults: Integer read FMaxResults write FMaxResults default 100;
    property SearchSource: TSearchSource read FSearchSource write FSearchSource default ssMediathekView;
    
    property OnSearchFinished: TMediathekViewSearchEvent read FOnSearchFinished write FOnSearchFinished;
    property OnSearchProgress: TMediathekViewProgressEvent read FOnSearchProgress write FOnSearchProgress;
    property OnSearchError: TMediathekViewErrorEvent read FOnSearchError write FOnSearchError;
  end;

procedure Register;

implementation

uses
  System.JSON.Types, System.JSON.Readers, System.JSON.Writers,
  Registry, Winapi.Windows;

{
  Beispiel: Funktionierende MediathekViewWeb-API-Abfrage mit Indy
  
  // Tipps bei Problemen:
  // 1. HTTP/1.1 explizit setzen:
  //    HTTP.ProtocolVersion := pv1_1;
  // 2. Accept-Header setzen:
  //    HTTP.Request.Accept := 'application/json';
  // 3. User-Agent auf Browser-String setzen:
  //    HTTP.Request.UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
  // 4. Teste das JSON mit curl/Postman:
        {
  procedure TestMediathekViewWeb;
  var
    HTTP: TIdHTTP;
    SSL: TIdSSLIOHandlerSocketOpenSSL;
    Root, QueryObj: TJSONObject;
    Queries: TJSONArray;
    JSONBody: string;
    RequestStream, ResponseStream: TStringStream;
  begin
    HTTP := TIdHTTP.Create(nil);
    SSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    try
      SSL.SSLOptions.SSLVersions := [sslvTLSv1_2];
      HTTP.IOHandler := SSL;
      HTTP.HandleRedirects := True;
      // HTTP/1.1 explizit setzen
      HTTP.ProtocolVersion := pv1_1;
      // User-Agent auf Browser-String setzen
      HTTP.Request.UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
      HTTP.Request.ContentType := 'application/json';
      // Accept-Header setzen
      HTTP.Request.Accept := 'application/json';

      // JSON-Body für die Suche bauen
      Root := TJSONObject.Create;
      try
        Queries := TJSONArray.Create;
        QueryObj := TJSONObject.Create;
        QueryObj.AddPair('field', 'title');
        QueryObj.AddPair('query', 'heute'); // <-- Hier Suchbegriff anpassen!
        QueryObj.AddPair('type', 'contains');
        Queries.AddElement(QueryObj);
        Root.AddPair('queries', Queries);
        Root.AddPair('sortBy', 'timestamp');
        Root.AddPair('sortOrder', 'desc');
        Root.AddPair('future', TJSONBool.Create(False));
        Root.AddPair('offset', TJSONNumber.Create(0));
        Root.AddPair('size', TJSONNumber.Create(5));
        JSONBody := Root.ToJSON;
      finally
        Root.Free;
      end;

      // Streams für Request und Response vorbereiten
      RequestStream := TStringStream.Create(JSONBody, TEncoding.UTF8);
      ResponseStream := TStringStream.Create('', TEncoding.UTF8);
      try
        RequestStream.Position := 0; // Wichtig!
        HTTP.Post('https://mediathekviewweb.de/api/query', RequestStream, ResponseStream);
        ShowMessage(ResponseStream.DataString); // Ergebnis anzeigen
      finally
        RequestStream.Free;
        ResponseStream.Free;
      end;
    finally
      HTTP.Free;
      SSL.Free;
    end;
  end;
}

procedure Register;
begin
  RegisterComponents('LaMita', [TLaMitaMediathekView]);
end;

{ TLaMitaMediathekView }

constructor TLaMitaMediathekView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FSSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(Self);
  FSSLHandler.SSLOptions.SSLVersions := [sslvTLSv1_2];
  
  FHTTPClient := TIdHTTP.Create(Self);
  FHTTPClient.IOHandler := FSSLHandler;
  FHTTPClient.HandleRedirects := True;
  FHTTPClient.Request.UserAgent := 'LaMitaMediathekView/1.0';
  FHTTPClient.Request.ContentType := 'text/plain';
  
  FResults := TObjectList<TMediathekViewItem>.Create(True);
  FSearchSource := ssMediathekView;
  FBaseURL := 'https://mediathekviewweb.de/api/query';
  FTimeout := 30000;
  FMaxResults := 20;
  FIsSearching := False;
  FSearchInProgress := False;
end;

destructor TLaMitaMediathekView.Destroy;
begin
  CancelSearch;
  FResults.Free;
  inherited Destroy;
end;



function TLaMitaMediathekView.Search(const SearchTerm: string): Boolean;
var
  ResponseData: string;
  Item: TMediathekViewItem;
  ParsedResults: TObjectList<TMediathekViewItem>;
begin
  Result := False;
  
  if FSearchInProgress then
  begin
    DoSearchError('Eine Suche läuft bereits');
    Exit;
  end;
  
  FSearchTerm := SearchTerm;
  FIsSearching := True;
  FSearchInProgress := True;

  try
    DoSearchProgress(10, 'Starte Suche...');
    
    ResponseData := PerformSearch(SearchTerm);
    
    if ResponseData <> '' then
    begin
      DoSearchProgress(90, 'Verarbeite Ergebnisse...');
      Item := ParsedResults[0];
      ParsedResults := ParseSearchResults(ResponseData);
      FResults.Clear;
      while ParsedResults.Count > 0 do
      begin
        Item := ParsedResults[0];
        FResults.Add(ParsedResults.Extract(Item));
      end;
      ParsedResults.Free;
      
      DoSearchProgress(100, 'Suche abgeschlossen');
      DoSearchFinished(FSearchTerm, FResults);
      Result := True;
    end;
    
  except
    on E: Exception do
    begin
      DoSearchError('Fehler bei der Suche: ' + E.Message);
    end;
  end;
  
  FIsSearching := False;
  FSearchInProgress := False;
end;

function TLaMitaMediathekView.SearchAsync(const SearchTerm: string): ITask;
begin
  if FSearchInProgress then
  begin
    DoSearchError('Eine Suche läuft bereits');
    Exit(nil);
  end;
  
  FCurrentTask := TTask.Create(
    procedure
    begin
      Search(SearchTerm);
    end
  );
  
  Result := FCurrentTask;
  Result.Start;
end;

procedure TLaMitaMediathekView.CancelSearch;
begin
  if FSearchInProgress then
  begin
    if Assigned(FCurrentTask) and (FCurrentTask.Status <> TTaskStatus.Completed) then
    begin
      FCurrentTask.Cancel;
    end;
    
    FIsSearching := False;
    FSearchInProgress := False;
    DoSearchProgress(0, 'Suche abgebrochen');
  end;
end;

function TLaMitaMediathekView.PerformSearch(const SearchTerm: string): string;
var
  RequestURL: string;
  Root, QueryObj: TJSONObject;
  Queries, FieldsArr: TJSONArray;
  JSONBody: string;
  RequestStream, ResponseStream: TStringStream;
  HTTP: THttpClient;
  Response: IHTTPResponse;
  ArchiveQuery: string;
begin
  Result := '';
  try
    DoSearchProgress(20, 'Erstelle Anfrage...');
    if FSearchSource = ssMediathekView then
    begin
      // Bestehende MediathekViewWeb-Logik (unverändert)
      RequestURL := FBaseURL;
      Root := TJSONObject.Create;
      try
        Queries := TJSONArray.Create;
        QueryObj := TJSONObject.Create;
        FieldsArr := TJSONArray.Create;
        FieldsArr.Add('title');
        QueryObj.AddPair('fields', FieldsArr);
        QueryObj.AddPair('query', SearchTerm);
        Queries.AddElement(QueryObj);
        Root.AddPair('queries', Queries);
        Root.AddPair('sortBy', 'timestamp');
        Root.AddPair('sortOrder', 'desc');
        Root.AddPair('future', TJSONBool.Create(False));
        Root.AddPair('offset', TJSONNumber.Create(0));
        Root.AddPair('size', TJSONNumber.Create(FMaxResults));
        JSONBody := Root.ToJSON;
      finally
        Root.Free;
      end;
      RequestStream := TStringStream.Create(JSONBody, TEncoding.UTF8);
      ResponseStream := TStringStream.Create('', TEncoding.UTF8);
      try
        RequestStream.Position := 0;
        FHTTPClient.Request.ContentType := 'text/plain';
        FHTTPClient.Request.UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
        FHTTPClient.Request.Accept := 'application/json';
      //  FHTTPClient.Request.AcceptEncoding := 'gzip, deflate';
        FHTTPClient.ProtocolVersion := pv1_1;
        FHTTPClient.ConnectTimeout := FTimeout;
        FHTTPClient.ReadTimeout := FTimeout;
        DoSearchProgress(40, 'Sende Anfrage...');
        FHTTPClient.Post(RequestURL, RequestStream, ResponseStream);
        DoSearchProgress(70, 'Antwort empfangen...');
       // ResponseStream.SaveToFile('D:\response.txt');
        Result := ResponseStream.DataString;
      finally
        RequestStream.Free;
        ResponseStream.Free;
      end;
    end
    else if FSearchSource = ssArchiveOrgVideo then
    begin
      // Archive.org API (korrekte Lucene-Syntax: q mit AND mediatype:(movies))
      if Trim(SearchTerm) <> '' then
        ArchiveQuery := TNetEncoding.URL.Encode(SearchTerm + ' AND mediatype:(movies)')
      else
        ArchiveQuery := 'mediatype:(movies)';  // Fallback für leeren Suchbegriff
      RequestURL := 'https://archive.org/advancedsearch.php?q=' + ArchiveQuery +
                    '&fl[]=identifier&fl[]=title&fl[]=description&output=json&rows=' +
                    IntToStr(FMaxResults);
      DoSearchProgress(30, 'URL: ' + RequestURL);  // Debugging: Zeigt die genaue URL
      HTTP := THttpClient.Create;
      try
        HTTP.UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
        HTTP.Accept := 'application/json';
       // HTTP.AcceptEncoding := 'gzip, deflate';
        DoSearchProgress(40, 'Sende Anfrage...');
        Response := HTTP.Get(RequestURL);
        DoSearchProgress(70, 'Antwort empfangen...');
        if Response.StatusCode = 200 then
        begin
          Result := Response.ContentAsString;
          DoSearchProgress(80, 'Antwort-Vorschau: ' + Copy(Result, 1, 200));  // Debugging
        end
        else
          DoSearchError('HTTP-Fehler: ' + IntToStr(Response.StatusCode) + ' - ' + Response.StatusText + ' - Response: ' + Copy(Response.ContentAsString, 1, 500));
      finally
        HTTP.Free;
      end;
    end
    else if FSearchSource = ssArchiveOrgAudio then
    begin
      // Archive.org API (korrekte Lucene-Syntax: q mit AND mediatype:(audio))
      if Trim(SearchTerm) <> '' then
        ArchiveQuery := TNetEncoding.URL.Encode(SearchTerm + ' AND mediatype:(audio)')
      else
        ArchiveQuery := 'mediatype:(audio)';  // Fallback für leeren Suchbegriff
      RequestURL := 'https://archive.org/advancedsearch.php?q=' + ArchiveQuery +
                    '&fl[]=identifier&fl[]=title&fl[]=description&output=json&rows=' +
                    IntToStr(FMaxResults);
      DoSearchProgress(30, 'URL: ' + RequestURL);  // Debugging: Zeigt die genaue URL
      HTTP := THttpClient.Create;
      try
        HTTP.UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
        HTTP.Accept := 'application/json';
        //HTTP.AcceptEncoding := 'gzip, deflate';
        DoSearchProgress(40, 'Sende Anfrage...');
        Response := HTTP.Get(RequestURL);
        DoSearchProgress(70, 'Antwort empfangen...');
        if Response.StatusCode = 200 then
        begin
          Result := Response.ContentAsString;
          DoSearchProgress(80, 'Antwort-Vorschau: ' + Copy(Result, 1, 200));  // Debugging
        end
        else
          DoSearchError('HTTP-Fehler: ' + IntToStr(Response.StatusCode) + ' - ' + Response.StatusText + ' - Response: ' + Copy(Response.ContentAsString, 1, 500));
      finally
        HTTP.Free;
      end;
    end
else if FSearchSource = ssJamendo then
begin
  if Trim(FJamendoClientID) = '' then
  begin
    DoSearchError('Jamendo Client-ID fehlt! Registriere dich unter https://developer.jamendo.com');
    Exit;
  end;
  ArchiveQuery := TNetEncoding.URL.Encode(SearchTerm);  // Dein Suchbegriff
  RequestURL := 'https://api.jamendo.com/v3.0/tracks/?client_id=' + FJamendoClientID +
                '&format=json&search=' + ArchiveQuery + '&limit=' + IntToStr(FMaxResults);
  DoSearchProgress(30, 'URL: ' + RequestURL);  // Debug wie bei Archive
  HTTP := THttpClient.Create;
  try
    HTTP.UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
    HTTP.Accept := 'application/json';
    //HTTP.AcceptEncoding := 'gzip, deflate';
    DoSearchProgress(40, 'Sende Anfrage an Jamendo...');
    Response := HTTP.Get(RequestURL);
    DoSearchProgress(70, 'Antwort empfangen...');
    if Response.StatusCode = 200 then
    begin
      Result := Response.ContentAsString;
      DoSearchProgress(80, 'Antwort-Vorschau: ' + Copy(Result, 1, 200));  // Debug
    end
    else
      DoSearchError('HTTP-Fehler: ' + IntToStr(Response.StatusCode) + ' - ' + Response.StatusText);
  finally
    HTTP.Free;
  end;
end;
  except
    on E: Exception do
      DoSearchError('Netzwerkfehler: ' + E.Message);
  end;
end;


function TLaMitaMediathekView.ParseSearchResults(const JSONData: string): TObjectList<TMediathekViewItem>;
var
  JSONRoot, JSONResult, JSONItem, JSONMeta: TJSONObject;
  JSONArray, JSONFiles: TJSONArray;
  Item: TMediathekViewItem;
  i, j: Integer;
  S, Identifier: string;
  MetaURL: string;
  StreamURL: string;
begin
  Result := TObjectList<TMediathekViewItem>.Create(True);
  try
    JSONRoot := TJSONObject.ParseJSONValue(JSONData) as TJSONObject;
    if not Assigned(JSONRoot) then
    begin
      DoSearchError('Ungültiges JSON-Format');
      Exit;
    end;
    try
      if FSearchSource = ssMediathekView then
      begin
        // Bestehende MediathekViewWeb-Logik (unverändert)
        if JSONRoot.TryGetValue('result', JSONResult) then
        begin
          if JSONResult.TryGetValue('results', JSONArray) then
          begin
            for i := 0 to JSONArray.Count - 1 do
            begin
              JSONItem := JSONArray.Items[i] as TJSONObject;
              if not Assigned(JSONItem) then Continue;
              Item := TMediathekViewItem.Create;
              if JSONItem.TryGetValue('title', S) then Item.FTitle := S;
              if JSONItem.TryGetValue('description', S) then Item.FDescription := S;
              if Assigned(JSONItem.Values['duration']) and not (JSONItem.Values['duration'] is TJSONNull) then
                Item.FDuration := IntToStr(JSONItem.GetValue<Integer>('duration'))
              else
                Item.FDuration := '';
              if Assigned(JSONItem.Values['timestamp']) and not (JSONItem.Values['timestamp'] is TJSONNull) then
                Item.FDate := UnixToDateTime(JSONItem.GetValue<Int64>('timestamp'))
              else
                Item.FDate := 0;
              if JSONItem.TryGetValue('channel', S) then Item.FChannel := S;
              if JSONItem.TryGetValue('topic', S) then Item.FTopic := S;
              if JSONItem.TryGetValue('url_video', S) then Item.FVideoURL := S;
              if JSONItem.TryGetValue('url_website', S) then Item.FWebsiteURL := S;
              if Assigned(JSONItem.Values['size']) and not (JSONItem.Values['size'] is TJSONNull) then
                Item.FSize := IntToStr(JSONItem.GetValue<Int64>('size'))
              else
                Item.FSize := '';
              Item.FThumbnailURL := ''; // Keine Thumbnails für MediathekView
              Result.Add(Item);
            end;
          end;
        end;
      end
else if FSearchSource = ssJamendo then
begin
  if JSONRoot.TryGetValue('results', JSONArray) then  // Jamendo's Array ist 'results'
  begin
    for i := 0 to JSONArray.Count - 1 do
    begin
      JSONItem := JSONArray.Items[i] as TJSONObject;
      if not Assigned(JSONItem) then Continue;
      Item := TMediathekViewItem.Create;
      if JSONItem.TryGetValue('name', S) then Item.FTitle := S else Item.FTitle := '';
      if JSONItem.TryGetValue('description', S) then Item.FDescription := S else Item.FDescription := '';
      if JSONItem.TryGetValue('duration', S) then Item.FDuration := FormatFloat('0.0', StrToFloatDef(S, 0)/1000) + 's'  // In ms, zu Sekunden
      else Item.FDuration := '';
      if JSONItem.TryGetValue('artist_name', S) then Item.FChannel := S else Item.FChannel := 'Jamendo';  // Artist als Channel
      if JSONItem.TryGetValue('musicinfo', S) then Item.FTopic := S else Item.FTopic := '';  // Genre/Tags
      Item.FDate := 0;  // Kein Datum standard, optional: release_date
      if JSONItem.TryGetValue('audiodownload', S) then Item.FVideoURL := S  // Download-URL
      else if JSONItem.TryGetValue('audio', S) then Item.FVideoURL := S  // Fallback auf Stream
      else Item.FVideoURL := ''; // Stream-URL
      if JSONItem.TryGetValue('shareurl', S) then Item.FWebsiteURL := S else Item.FWebsiteURL := '';  // Track-Page
      if JSONItem.TryGetValue('image', S) then Item.FThumbnailURL := S else Item.FThumbnailURL := '';  // Cover
      Item.FSize := '';  // Nicht standard
      Result.Add(Item);
    end;
  end
  else
    DoSearchError('Kein "results"-Array in Jamendo-Response');
end
      else if (FSearchSource = ssArchiveOrgVideo) or (FSearchSource = ssArchiveOrgAudio) then
      begin
        // Archive.org-Logik (mit Thumbnail-Extraktion)
        if JSONRoot.TryGetValue('response', JSONResult) then
        begin
          if JSONResult.TryGetValue('docs', JSONArray) then
          begin
            for i := 0 to JSONArray.Count - 1 do
            begin
              JSONItem := JSONArray.Items[i] as TJSONObject;
              if not Assigned(JSONItem) then Continue;
              // Prüfe, ob identifier existiert
              if not JSONItem.TryGetValue('identifier', Identifier) then
              begin
                DoSearchProgress(90, 'Überspringe Eintrag ohne identifier: ' + JSONItem.ToJSON);
                Continue;
              end;
              Item := TMediathekViewItem.Create;
              if JSONItem.TryGetValue('title', S) then Item.FTitle := S else Item.FTitle := '';
              if JSONItem.TryGetValue('description', S) then Item.FDescription := S else Item.FDescription := '';
              Item.FDuration := '';
              Item.FChannel := 'Archive.org';
              Item.FTopic := '';
              Item.FDate := 0;
              // Metadata-API für Stream-URL und Thumbnail
              MetaURL := 'https://archive.org/metadata/' + Identifier;
              try
                JSONMeta := TJSONObject.ParseJSONValue(FHTTPClient.Get(MetaURL)) as TJSONObject;
                try
                  if JSONMeta.TryGetValue('files', JSONFiles) then
                  begin
                    // Stream-URL (für Video oder Audio)
                    for j := 0 to JSONFiles.Count - 1 do
                    begin
                      JSONItem := JSONFiles.Items[j] as TJSONObject;
                      if FSearchSource = ssArchiveOrgVideo then
                      begin
                        if JSONItem.TryGetValue('format', S) and ((S = 'MPEG4') or (S = 'h.264') or (S = 'h.264 IA')) then
                        begin
                          if JSONItem.TryGetValue('name', S) then
                          begin
                            StreamURL := 'https://archive.org/download/' + Identifier + '/' + S;
                            Item.FVideoURL := StreamURL;
                            Break;
                          end;
                        end;
                      end
                      else if FSearchSource = ssArchiveOrgAudio then
                      begin
                        if JSONItem.TryGetValue('format', S) and ((S = 'MP3') or (S = 'VBR MP3') or (S = 'Ogg Vorbis')) then
                        begin
                          if JSONItem.TryGetValue('name', S) then
                          begin
                            StreamURL := 'https://archive.org/download/' + Identifier + '/' + S;
                            Item.FVideoURL := StreamURL; // Audio-URL in VideoURL (für Kompatibilität)
                            Break;
                          end;
                        end;
                      end;
                    end;
                    // Thumbnail/Cover-Extraktion
                    for j := 0 to JSONFiles.Count - 1 do
                    begin
                      JSONItem := JSONFiles.Items[j] as TJSONObject;
                      if JSONItem.TryGetValue('format', S) and (S = 'Image JPEG') then
                      begin
                        if JSONItem.TryGetValue('name', S) then
                        begin
                          if (Pos('thumb', LowerCase(S)) > 0) or (Pos('cover', LowerCase(S)) > 0) or (Pos('001', S) > 0) then
                          begin
                            Item.FThumbnailURL := 'https://archive.org/download/' + Identifier + '/' + S;
                            //DoSearchProgress(92, 'Thumbnail gefunden für ' + Identifier + ': ' + Item.FThumbnailURL);
                            Break;
                          end;
                        end;
                      end;
                    end;
                    // Fallback-Thumbnail, falls keins gefunden
                    if Item.FThumbnailURL = '' then
                    begin
                      Item.FThumbnailURL := 'https://archive.org/services/img/' + Identifier;
                      //DoSearchProgress(92, 'Fallback-Thumbnail für ' + Identifier + ': ' + Item.FThumbnailURL);
                    end;
                  end;
                  Item.FWebsiteURL := 'https://archive.org/details/' + Identifier;
                  if JSONMeta.TryGetValue('size', S) then Item.FSize := S else Item.FSize := '';
                finally
                  JSONMeta.Free;
                end;
              except
                on E: Exception do
                  DoSearchError('Fehler bei Metadata für ' + Identifier + ': ' + E.Message);
              end;
              Result.Add(Item);
            end;
          end;
        end;
      end;
    finally
      JSONRoot.Free;
    end;
  except
    on E: Exception do
      DoSearchError('Fehler beim Parsen der JSON-Daten: ' + E.Message);
  end;
end;


function TLaMitaMediathekView.ExtractVideoURL(const ItemData: TJSONObject): string;
var
  JSONUrls: TJSONArray;
  JSONUrl: TJSONObject;
  i: Integer;
begin
  Result := '';
  
  if ItemData.TryGetValue('urls', JSONUrls) then
  begin
    for i := 0 to JSONUrls.Count - 1 do
    begin
      JSONUrl := JSONUrls.Items[i] as TJSONObject;
      if Assigned(JSONUrl) and JSONUrl.TryGetValue('url', Result) then
      begin
        if Result.StartsWith('http') then
          Break;
      end;
    end;
  end;
end;

function TLaMitaMediathekView.ExtractWebsiteURL(const ItemData: TJSONObject): string;
var
  JSONUrls: TJSONArray;
  JSONUrl: TJSONObject;
  i: Integer;
  UrlType: string;
begin
  Result := '';
  
  if ItemData.TryGetValue('urls', JSONUrls) then
  begin
    for i := 0 to JSONUrls.Count - 1 do
    begin
      JSONUrl := JSONUrls.Items[i] as TJSONObject;
      if Assigned(JSONUrl) then
      begin
        if JSONUrl.TryGetValue('type', UrlType) and (UrlType = 'image') then
        begin
          if JSONUrl.TryGetValue('url', Result) then
            Break;
        end;
      end;
    end;
  end;
end;

function TLaMitaMediathekView.ParseDateTime(const DateTimeStr: string): TDateTime;
begin
  try
    Result := ISO8601ToDate(DateTimeStr);
  except
    try
      Result := StrToDateTime(DateTimeStr);
    except
      Result := 0;
    end;
  end;
end;

procedure TLaMitaMediathekView.DoSearchProgress(Progress: Integer; const Status: string);
begin
  if Assigned(FOnSearchProgress) then
    FOnSearchProgress(Self, Progress, Status);
end;

procedure TLaMitaMediathekView.DoSearchFinished(const SearchTerm: string; 
  Results: TObjectList<TMediathekViewItem>);
begin
  if Assigned(FOnSearchFinished) then
    FOnSearchFinished(Self, SearchTerm, Results);
end;

procedure TLaMitaMediathekView.DoSearchError(const ErrorMessage: string);
begin
  if Assigned(FOnSearchError) then
    FOnSearchError(Self, ErrorMessage);
end;

end. 