unit FoFDFilterMinimalTest;

interface

uses
  WinApi.Messages,
  WinApi.Windows,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Comp.DataSet,
  FireDAC.DApt,
  FireDAC.DApt.Intf,
  FireDAC.DatS,
  FireDAC.Moni.Base,
  FireDAC.Moni.FlatFile,
  FireDAC.Phys,
  FireDAC.Phys.Intf,
  FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef,
  FireDAC.Stan.Async,
  FireDAC.Stan.Def,
  FireDAC.Stan.Error,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Pool,
  FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait,
  System.Classes,
  System.SysUtils,
  System.Threading,
  System.Variants,
  Vcl.Forms;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FDQuery1FilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure FDQuery1CalcFields(DataSet: TDataSet);
  private
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure DebugOut(const Msg : string);         overload;
var str : string;
begin
  str := Format('[%d] %s', [GetCurrentThreadId, msg]);

  OutputDebugString(PChar(str));
end;

procedure DebugOut(const Value : Integer); overload;
begin
  DebugOut(IntToStr(Value));
end;

procedure TForm1.FDQuery1CalcFields(DataSet: TDataSet);
var test : integer;
    Field1 : TField;
    Field2 : TField;
begin
  Field1 := DataSet.FieldByName('TestCalc1');
  Field2 := DataSet.FieldByName('Id');

  Field1.AsInteger := 42; // The internal calc field must be assigned a value in order to trigger the error
  test := Field2.AsInteger; // !!! The error accurs here (notice, we are NOT accessing the internal calc field)
end;

procedure TForm1.FDQuery1FilterRecord(DataSet: TDataSet; var Accept: Boolean);
begin
  // nop
end;


procedure TForm1.FormCreate(Sender: TObject);
var Loop : Integer;
    Params : TStrings;
    Connection1 : TFDConnection;
    Query1 : TFDQuery;
begin
  FDManager.Active := True;

  Params := TStringList.Create;
  Params.Add('Server=localhost');
  Params.Add('Database=???');
  Params.Add('OSAuthent=Yes');

  FDManager.AddConnectionDef('MyConnectionDef', 'MSSQL', Params, true);

  Connection1 := TFDConnection.Create(nil);
  Connection1.ConnectionDefName := 'MyConnectionDef';
  Connection1.Connected := TRUE;

  // Query 1
  Query1 := TFDQuery.Create(self);
  Query1.Connection := Connection1;

  Query1.OnCalcFields := FDQuery1CalcFields; // This has to be set in order to trigger the error
  Query1.OnFilterRecord := FDQuery1FilterRecord; // This has to be set in order to trigger the error
  Query1.SQL.Text := 'SELECT * FROM dbo.TestTable2';

  // Create all Fields for the database table
  Query1.FieldDefs.Update;
  for Loop := 0 to Query1.FieldDefs.Count-1 do begin
    Query1.FieldDefs[Loop].CreateField(Query1).DataSet := Query1;
  end;

  // Create a internal calc field
  with TIntegerField.Create(Query1) do begin
    FieldName := 'TestCalc1';
    FieldKind := fkInternalCalc; // It has to be an fkInternalCalc-Field in order to trigger the error
    Size := 0;
    DataSet := Query1;
  end;

  Query1.Open;
  DebugOut('===== Query 1 Opened =====');

  Query1.FetchAll;
  DebugOut('===== Query 1 fetched all =====');

  Query1.Filtered := true; // This has to be set to true in order to trigger the error
  DebugOut('=====  Query 1 Now filtered =====');

  TTask.Run(procedure
    var Connection2 : TFDConnection;
        Query2 : TFDQuery;
        Loop : Integer;
    begin
      Connection2 := TFDConnection.Create(nil);
      Connection2.ConnectionDefName := 'MyConnectionDef';
      Connection2.Connected := TRUE;

      // Query 2
      Query2 := TFDQuery.Create(nil);
      Query2.Connection := Connection2;

      Query2.SQL.Text := 'SELECT * FROM dbo.TestTable1';

      DebugOut('===== Query 2 About to open =====');

      Query2.Open;
      DebugOut('===== Query 2 is now open =====');

      // This FetchAll has to run long enough, so that the loop for Query1 runs while this loads the data
      Query2.FetchAll;
      DebugOut('===== Query 2 fetched all =====');

      DebugOut('===== Query 2 DONE =====');

      FreeAndNil(Query2);
      FreeAndNil(Connection2);
    end);

  // This loop has to run while the Task loads the data (FetchAll)
  Loop := 0;
  Query1.First;
  while not Query1.Eof do begin
    Inc(Loop);
    DebugOut(Loop);
    Query1.Next;
  end;
end;


end.
