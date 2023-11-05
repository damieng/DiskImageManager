unit Comparers;

{$mode Delphi}

interface

uses
  Classes, SysUtils, ComCtrls;

function CompareItems(Item1, Item2: TListItem; ListView: TListView): integer;
function CompareObjects(Object1, Object2: TObject; Field: string): integer;
function CompareValues(Value1, Value2: string): integer;

implementation

function CompareItems(Item1, Item2: TListItem; ListView: TListView): integer;
begin
  if ListView.SortColumn = 0 then
    Result := CompareValues(Item1.Caption, Item2.Caption)
  else
    Result := CompareValues(Item1.SubItems[ListView.SortColumn - 1], Item2.SubItems[ListView.SortColumn - 1]);

  if ListView.SortDirection = sdDescending then Result := -Result;
end;

function CompareObjects(Object1, Object2: TObject; Field: string): integer;
begin
  Result := 0;
end;

function CompareValues(Value1, Value2: string): integer;
var
  Date1, Date2: TDateTime;
  Float1, Float2: double;
begin
  if TryStrToDateTime(Value1, Date1) and TryStrToDateTime(Value2, Date2) then
    Result := Trunc(Date1 - Date2)
  else
  if TryStrToFloat(Value1, Float1) and TryStrToFloat(Value2, Float2) then
    Result := Trunc(Float1 - Float2)
  else
    Result := CompareText(Value1, Value2);
end;

end.
