unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListBox, FMX.Layouts, FMX.Edit,
  FMX.ComboEdit, System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent, FMX.Memo, Json,
  FMX.ScrollBox, FMX.Memo.Types, System.Threading, FMX.Objects, System.Generics.Collections;

type
  TForm1 = class(TForm)
    ToolBar1: TToolBar;
    Label1: TLabel;
    Label2: TLabel;
    btnGetWeather: TButton;
    ScrollBox1: TScrollBox;
    Image1: TImage;
    Memo1: TMemo;
    Edit1: TEdit;
    NetHTTPClient1: TNetHTTPClient;
    procedure FormCreate(Sender: TObject);
    procedure btnGetWeatherClick(Sender: TObject);
  private
    { Private declarations }
    FOWMRequest: string;
    FIconName: string;
    FTask1, FTask2: ITask;
    FOWMUrl: string;
    FOWMApiKey: string;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.btnGetWeatherClick(Sender: TObject);
var
    JSON, JSONMain, JSONCountry: TJSONObject;
    JSONDetail: TJSONArray;
    City: string;
    Degrees, Kelvins: Double;
    Resp: TMemoryStream;
    Response: TStringStream;
begin
    JSON := nil;
    JSONMain := nil;
    JSONDetail := nil;
    JSONCountry := nil;
    Resp := nil;
    Response := nil;
    Memo1.Lines.Clear;
    City := Edit1.Text;
    FOWMRequest := FOWMUrl + City + '&appid=' + FOWMApiKey;
    FTask1 := TTask.Run(
    procedure
    begin
      try
        Response := TStringStream.Create;
        NetHttpClient1.Get(FOWMRequest, Response);
        TThread.Synchronize(nil,
        procedure
        begin
          JSON := TJSONObject.ParseJSONValue(Response.DataString) as TJSONObject;
          JSONMain := TJSONObject(JSON.Get('main').JsonValue);
          JSONDetail := TJSONArray(JSON.Get('weather').JsonValue);
          JSONCountry := TJSONObject(JSON.Get('sys').JsonValue);
          Kelvins := Double.Parse(JSONMain.GetValue('temp').Value);
          Degrees := Kelvins - 273.15;
          Memo1.Lines.Add('Temp: ' + FloatToStrF(Degrees,ffGeneral,3,3) + ' ��');
          Memo1.Lines.Add('Country: ' + JSONCountry.GetValue('country').Value);
          Memo1.Lines.Add('City: ' + JSON.GetValue('name').Value);
          Memo1.Lines.Add('Clouds: ' + (TJSONPair(TJSONObject(JSONDetail.Items[0])
            .Get('description')).JsonValue.Value));
          Memo1.Lines.Add('Humidity: ' + JSONMain.GetValue('humidity').Value +' %');
          Memo1.Lines.Add('Atmospheric pressure: ' + JSONMain.GetValue('pressure').
            Value+' hPa');
          FIconName := TJSONPair(TJSONObject(JSONDetail.Items[0]).Get('icon')).
            JsonValue.Value;
        end)
      finally
          Response.Free;
      end;
    end);
    if FTask1.Status = TTaskStatus.Created then
      FTask1.Start;
    FTask2 := TTask.Run(
    procedure
    begin
        TTask.WaitForAny(FTask1);
      try
        Resp := TMemoryStream.Create;
        NetHttpClient1.Get('http://openweathermap.org/img/wn/' +
          FIconName + '@2x.png', Resp);
        TThread.Synchronize(nil,
        procedure
        begin
          Image1.Bitmap.LoadFromStream(Resp);
        end);
      finally
        Resp.Free;
        JSON.Free;
        JSONMain.Free;
        JSONDetail.Free;
        JSONCountry.Free;
      end;
    end);
    if FTask2.Status = TTaskStatus.Created then
      FTask2.Start;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FormatSettings.DecimalSeparator := '.';
  FOWMUrl := 'https://api.openweathermap.org/data/2.5/weather?q=';
  FOWMApiKey := 'ffe6d300f48841172ae985a4d1f3c576';
end;

end.
