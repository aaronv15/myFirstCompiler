program cradle;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes
  { you can add units after this };

const
  TAB = ^I;
  CR = ^M;

var
  Look: char;

procedure Expression; Forward;

procedure GetChar;
begin
  Read(Look);
end;

procedure Error(s: string);
begin
  WriteLn;
  WriteLn(^G, 'Error: ', s, '.');
end;

procedure Abort(s: string);
begin
  Error(s);
  Halt;
end;

procedure Expected(s: string);
begin
  Abort(s + ' Expected');
end;

procedure Match(x: char);
begin
  if Look = x then
    GetChar
  else
    Expected('''' + x + '''');
end;

function IsAlpha(c: char): boolean;
begin
  IsAlpha := upcase(c) in ['A'..'Z'];
end;

function IsDigit(c: char): boolean;
begin
  IsDigit := c in ['0'..'9'];
end;

function IsAlNum(c: char): boolean;
begin
  IsAlNum := IsAlpha(c) or IsDigit(c);
end;

function IsAddop(c: char): boolean;
begin
  IsAddop := c in ['+', '-'];
end;

function IsMulop(c: char): boolean;
begin
  IsMulop := c in ['*', '/'];
end;

function GetName: string;
var
  Token: string;
begin
  Token := '';
  if not IsAlpha(Look) then
    Expected('Name');
  while IsAlNum(Look) do
  begin
    Token := Token + UpCase(Look);
    GetChar;
  end;
  GetName := Token;
end;

function GetNum: string;
var Value:
  string;
begin
  Value := '';
  if not IsDigit(Look) then
    Expected('Integer');
  while IsDigit(Look) do
  begin
    Value := Value + Look;
    GetChar;
  end;
  GetNum := Value;
end;

procedure Emit(s: string);
begin
  Write(TAB, s);
end;

procedure EmitLn(s: string);
begin
  Emit(s);
  WriteLn;
end;

procedure Init;
begin
  GetChar;
end;

procedure Ident;
var
  Name: char;
begin
  Name := GetName;
  if Look = '(' then
  begin
    Match('(');
    Match(')');
    EmitLn('BSR ' + Name);
    end
  else
    EmitLn('MOVE ' + Name + '(PC),D0')
end;

procedure Factor;
begin
  if Look = '(' then begin
    Match('(');
    Expression;
    Match(')');
    end
  else if IsAlpha(Look) then
    Ident
  else
    EmitLn('MOVE #' + GetNum + ',D0');
end;

procedure Multiply;
begin
  Match('*');
  Factor;
  EmitLn('MULS (SP)+,D0');
end;

procedure Divide;
begin
  Match('/');
  Factor;
  EmitLn('MOVE (SP)+,D1');
  EmitLn('DIVS D1,D0');
end;

procedure Term;
begin
  Factor;
  while isMulop(Look) do
  begin
    EmitLn('MOVE D0,-(SP)');
    case Look of
      '*': Multiply;
      '/': Divide;
    end;
  end;
end;

procedure Add;
begin
  Match('+');
  Term;
  EmitLn('ADD (SP)+,D0');
end;

procedure Subtract;
begin
  Match('-');
  Term;
  EmitLn('SUB (SP)+,D0');
  EmitLn('NEG D0');
end;

procedure Expression;
begin
  if IsAddop(Look) then
    EmitLn('CLR D0')
  else
    Term;
  while IsAddop(Look) do
  begin
    EmitLn('MOVE D0,-(SP)');
    case Look of
      '+': Add;
      '-': Subtract;
    end;
  end;
end;

procedure Assignment;
  var
    Name: char;
  begin
    Name := GetName;
    Match('=');
    Expression;
    EmitLn('LEA ' + Name + '(PC),A0');
    EmitLn('MOVE D0,(A0)')
end;

begin
  Init;
  Assignment;
  {if Look <> CR then Expected('Newline'); }
end.

