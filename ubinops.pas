unit uBinOps;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  { TForm1 }

  Gamepad = class
    public
      name:String;
      nButtons:integer;
      analog:boolean;
  end;

  TForm1 = class(TForm)
    btnAdd: TButton;
    btnClear: TButton;
    btnReadPads: TButton;
    btnReadSFile: TButton;
    btnWritePads: TButton;
    btnWriteSFile: TButton;
    cbDataTypes: TComboBox;
    chAnalog: TCheckBox;
    edDataTypeSize: TEdit;
    edPadName: TEdit;
    edPadButtons: TEdit;
    edSFileContents: TEdit;
    edSimpleIOFileName: TEdit;
    gbDataSizes: TGroupBox;
    gbSimpleFile: TGroupBox;
    gbComplexFile: TGroupBox;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lbName: TLabel;
    lbPads: TListBox;
    lbButtons: TLabel;
    mmLog: TMemo;
    Panel1: TPanel;
    procedure btnAddClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnReadPadsClick(Sender: TObject);
    procedure btnReadSFileClick(Sender: TObject);
    procedure btnWritePadsClick(Sender: TObject);
    procedure btnWriteSFileClick(Sender: TObject);
    procedure lbPadsClick(Sender: TObject);
    procedure RefreshSizeData;
    procedure ListPads;
    procedure AddPad;
    procedure ClearPads;
    procedure ShowPad;
    procedure Log(txt:string);
    procedure cbDataTypesChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  gPads:array of Gamepad;

implementation

{$R *.lfm}

{ TForm1 }

function byteVolumeForDataType(dt:string):integer;
var dtUpcased:string;
begin
  dtUpcased:=UpCase(dt);
  case (dtUpcased) of
  'BOOLEAN':
    begin
      result:=SizeOf(Boolean);
    end;
  'INTEGER':
    begin
      result:=SizeOf(Integer);
    end;
  'BYTE':
    begin
      result:=SizeOf(Byte);
    end;
  'SHORTINT':
    begin
      result:=SizeOf(ShortInt);
    end;
  'REAL':
    begin
      result:=SizeOf(Real);
    end;
  'DOUBLE':
    begin
      result:=SizeOf(Double);
    end;
  'CHAR':
    begin
      result:=SizeOf(Char);
    end;
  end;
end;

procedure TForm1.RefreshSizeData;
begin
  edDataTypeSize.Text:=inttostr(byteVolumeForDataType(cbDataTypes.Text));
end;

procedure TForm1.ListPads;
var cSel,i,l:integer;
begin
  cSel:=lbPads.ItemIndex;
  lbPads.Clear;
  l:=Length(gPads);
  if (l>0) then
  for i:=0 to l-1 do
  begin
    lbPads.Items.Add(gPads[i].name);
  end;
  lbPads.ItemIndex:=cSel;
end;

procedure TForm1.AddPad;
var co,l:integer;
begin
  l:=Length(gPads);
  SetLength(gPads,l+1);
  inc(l);

  co:=High(gPads);
  gPads[co]:=Gamepad.Create;
  gPads[co].name:=edPadName.Text;
  gPads[co].nButtons:=StrToInt(edPadButtons.Text);
  gPads[co].analog:=chAnalog.Checked;

  ListPads;
end;

procedure Tform1.ClearPads;
begin
  SetLength(gPads,0);
  ListPads;
  lbPads.ItemIndex:=-1;
  ShowPad;
end;

procedure TForm1.ShowPad;
var pts:integer;
begin
  pts:=lbPads.ItemIndex;
  if (pts<>-1) then
  begin
    edPadName.Text:=gPads[pts].name;
    edPadButtons.Text:=intTostr(gPads[pts].nButtons);
    chAnalog.Checked:=gPads[pts].analog;
  end
  else
  begin
    edPadName.Text:='???';
    edPadButtons.Text:='0';
    chAnalog.Checked:=false;
  end;
end;

procedure TForm1.btnWriteSFileClick(Sender: TObject);
var dataFile:File;
    dataSet:string;
    dataSetSymbol:char;
    i,l:integer;
begin
  AssignFile(dataFile,edSimpleIOFileName.Text);
  Rewrite(dataFile,SizeOf(Char));

  dataSet:=edSFileContents.Text;
  l:=length(dataSet);

  for i:=1 to l do
  begin
    dataSetSymbol:=dataSet[i];
    BlockWrite(dataFile,dataSetSymbol,1);
  end;

  CloseFile(dataFile);

end;

procedure TForm1.lbPadsClick(Sender: TObject);
begin
  ShowPad;
end;

procedure TForm1.btnReadSFileClick(Sender: TObject);
var dataFile:File;
    dataSet:string;
    dataSetSymbol:char;
    i,l:integer;
begin

  dataSet:='';

  AssignFile(dataFile,edSimpleIOFileName.Text);
  Reset(dataFile,SizeOf(Char));

  while not EOF(dataFile) do
  begin
    BlockRead(dataFile,dataSetSymbol,1);
    dataSet:=dataSet+dataSetSymbol;
  end;

  CloseFile(dataFile);

  edSFileContents.Text:=dataSet;
end;

procedure TForm1.btnWritePadsClick(Sender: TObject);
var i,j,l,sl,n,bn:integer;
    pn:string;
    cs:char;
    ca:boolean;
    dataFile:file;
begin
  AssignFile(dataFile,'gamepads.bin');

  //to be safe we set block size to 1, so we will write data in
  //chunks of 1 byte. therefore, when calling blockwrite we must indicate
  //the specific data size in bytes
  Rewrite(dataFile,1);

  l:=Length(gPads);

  //first we write the length of our database
  BlockWrite(dataFile,l,SizeOf(Integer));

  //we write each field of class Gamepad separately in cycle
  //1) name length + name itself
  //2) number of buttons
  //3) has analog sticks
  //and we will read it in the same order
  if (l>0) then
  for i:=0 to l-1 do
  begin
    sl:=Length(gPads[i].name);
    BlockWrite(dataFile,sl,SizeOf(Integer));
    //we could actually blockwrite a string, but to be safer
    //we write it as eachindividual char
    if (sl>0) then
    for j:=1 to sl do
    begin
      cs:=gPads[i].name[j];
      BlockWrite(dataFile,cs,SizeOf(Char));
    end;
    BlockWrite(dataFile,gPads[i].nButtons,SizeOf(Integer));
    BlockWrite(dataFile,gPads[i].analog,SizeOf(Boolean));
  end;

  CloseFile(dataFile);
end;

procedure TForm1.btnClearClick(Sender: TObject);
begin
  ClearPads;
end;

procedure TForm1.Log(txt:string);
begin
  mmLog.Lines.Add(txt);
end;

procedure TForm1.btnReadPadsClick(Sender: TObject);
var i,j,l,sl,n,bn:integer;
    pn:string;
    cs:char;
    ca:boolean;
    dataFile:file;
begin
  AssignFile(dataFile,'gamepads.bin');

  //reset file with block volume of 1 byte
  Reset(dataFile,1);


  //blockread expects volume of 1 byte, so to read
  //the entire var we need to set data size to size of needed data type
  //ergo sizeof(integer)in this case
  BlockRead(dataFile,n,SizeOf(Integer));

  Log('Found '+IntToStr(n)+ ' DB entries...');

  if (n>0) then
  begin

    SetLength(gPads,n);

    i:=0;
    while (i<n) do
    begin
      gPads[i]:=Gamepad.Create;
      Log('Running data for pad '+IntToStr(i));
      BlockRead(dataFile,sl,SizeOf(Integer));
      Log('sl = '+IntToStr(sl));
      gPads[i].name:='';
      if (sl>0) then
      begin
        j:=0;
        while (j<sl) do
        begin
          BlockRead(dataFile,cs,SizeOf(char));
          gPads[i].name:=gPads[i].name+cs;
          inc(j);
        end;
      end;
      Log('Name =  '+gPads[i].name);
      BlockRead(dataFile,bn,SizeOf(integer));
      gPads[i].nButtons:=bn;
      Log('bn = '+IntToStr(bn));
      BlockRead(dataFile,ca,SizeOf(Boolean));
      gPads[i].analog:=ca;
      Log('ca = '+BoolToStr(ca));
      inc(i);
    end;
  end;

  CloseFile(dataFile);

  ListPads;

end;

procedure TForm1.btnAddClick(Sender: TObject);
begin
  AddPad;
end;

procedure TForm1.cbDataTypesChange(Sender: TObject);
begin
  RefreshSizeData;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  RefreshSizeData;
end;

end.

