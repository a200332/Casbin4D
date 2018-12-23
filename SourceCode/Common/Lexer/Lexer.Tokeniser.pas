unit Lexer.Tokeniser;

interface

uses
  Core.Base.Types, Lexer.Tokens.Messages, Lexer.Tokens.List, Core.Logger.Types,
  System.Generics.Collections, Lexer.Tokeniser.Types, Lexer.Tokens.Types;

type
  TTokeniser = class (TBaseInterfacedObject, ITokeniser)
  private
    fInputString: string;
    fTokenList: TTokenList;
    fLogger: ILogger;
    fTokenMessages: TObjectList<TTokenMessage>;
    fStatus: TTokeniserStatus;

    procedure addToken(const currCh: Char; const currPosition: TPosition);
  private
{$REGION 'Interface'}

    function getLogger: ILogger;
    function getTokenList: TTokenList;
    function getTokenMessages: TObjectList<TTokenMessage>;
    procedure setLogger(const aValue: ILogger);
    procedure tokenise;
    function getStatus: TTokeniserStatus;
{$ENDREGION}
  public
    constructor Create(const aInputString: string);
    destructor Destroy; override;
  end;

implementation

uses
  Core.Logger.Default, System.SysUtils, System.StrUtils, Lexer.Utilities;

constructor TTokeniser.Create(const aInputString: string);
begin
  inherited Create;
  fLogger:=TDefaultLogger.Create;
  fTokenList:=TTokenList.Create;
  fTokenMessages:=TObjectList<TTokenMessage>.Create(true);
  fInputString:=aInputString;
  fStatus:=tsNotStarted;
end;

destructor TTokeniser.Destroy;
begin
  fLogger:=nil;
  fTokenMessages.Free;
  fTokenList.Free;
  inherited;
end;

function TTokeniser.getLogger: ILogger;
begin
  Result:=fLogger;
end;

function TTokeniser.getStatus: TTokeniserStatus;
begin
  Result:=fStatus;
end;

function TTokeniser.getTokenList: TTokenList;
begin
  Result:=fTokenList;
end;

function TTokeniser.getTokenMessages: TObjectList<TTokenMessage>;
begin
  Result := fTokenMessages;
end;

procedure TTokeniser.setLogger(const aValue: ILogger);
begin
  fLogger:=nil;
  fLogger:=aValue;
end;

//////////////////////////
{ TCharBuffer }
type
  PCharBuffer = ^TCharBuffer;
  TCharBuffer = record
    PreviousChar: Char;
    CurrentChar: Char;
    NextChar: Char;

    function nextTwoChars: string;
  end;


function TCharBuffer.nextTwoChars: string;
begin
  Result:=CurrentChar+NextChar;
end;

procedure TTokeniser.addToken(const currCh: Char; const currPosition:
    TPosition);
var
  token: PToken;
begin
  token:=tokenForOneCharReserved(currCh);

  token.StartPosition.Column:=currPosition.Column;
  token.StartPosition.Row:=currPosition.Row;
  token.EndPosition.Column:=currPosition.Column;
  token.EndPosition.Row:=currPosition.Row;

  fTokenList.Add(token);
end;

/////////////////////////

procedure TTokeniser.tokenise;
var
  tokenMessage: TTokenMessage;
  currPosition: TPosition;
  lastPosition: TPosition;
  currCh: Char;
  value: string;
  token: PToken;
  buffer: PCharBuffer;
begin
  fTokenList.Clear;
  fTokenMessages.Clear;

  // Empty parse string is passed
  if Trim(fInputString) = '' then
  begin
//    tokenMessage.Create(tmtError, 'Empty string to parse', position);
//    tokenMessage.ErrorType:=tmeSyntaxError;
//    fTokenMessages.Add(tokenMessage);
    fStatus:=tsFatalError;
    Exit;
  end;

  currPosition.Column:=Low(string);
  currPosition.Row:=0;
  lastPosition.Column:=currPosition.Column;
  lastPosition.Row:=currPosition.Row;
  fStatus:=tsRunning;

  New(buffer);
  FillChar(buffer^, SizeOf(TCharBuffer), 0);

  for currCh in fInputString do
  begin
    //Update Buffer
    buffer^.CurrentChar:=currCh;
    if currPosition.Column - 1 >= Low(string) then
      buffer^.PreviousChar:=fInputString[currPosition.Column - 1]
    else
      buffer^.PreviousChar:=#0;
    if currPosition.Column + 1 <= Length(fInputString) then
      buffer^.NextChar:= fInputString[currPosition.Column + 1]
    else
      buffer^.NextChar:=#0;

    //Check if character is in reserved chars or/and whitespace
    if CharInSet(currCh, oneCharReserved + whiteSpaceChars) then
      addToken(currCh, currPosition);



    //Increase the Column
    Inc(currPosition.Column);
  end;

  fStatus:=tsFinished;
  Dispose(buffer);
end;

end.

//    if CharInSet(currCh, [#13, #10]) or
//      (((currPosition.Column+1)<=High(fInputString)) and
//          (Copy(fInputString, currPosition.Column, Length(sLineBreak)) =
//                                                            sLineBreak)) then
//    begin
//      if Trim(value)<>'' then
//      begin
//        //Here we must check for keywords
//        //For now we declare it as identifier
//        New(token);
//        FillChar(token^, SizeOf(TToken), 0);
//        token^.&Type:=ttIdentifier;
//        token^.Value:=value;
//
//        token.StartPosition.Column:=lastPosition.Column;
//        token.StartPosition.Row:=lastPosition.Row;
//
//        token.EndPosition.Column:=currPosition.Column;
//        token.EndPosition.Row:=currPosition.Row;
//
//        fTokenList.Add(token);
//      end;
//      Inc(currPosition.Row);
//      currPosition.Column:=Low(string);
//    end
//    else
//    begin
//      if (not CharInSet(currCh, [#32, #9])) or
//            (CharInSet(currCh, [#32, #9]) and (Trim(value)<>'')) then
//      begin
//        if not CharInSet(currCh, oneCharReserved) then
//        begin
//          if Trim(currCh)<>'' then
//            value:=value+currCh;
//          if ((currPosition.Column+1)<=High(fInputString)) and
//            (CharInSet(fInputString[currPosition.Column+1],
//                                          oneCharReserved)) then
//          begin
//            //Here we must check for keywords
//            //For now we declare it as identifier
//            New(token);
//            FillChar(token^, SizeOf(TToken), 0);
//            token^.&Type:=ttIdentifier;
//            token^.Value:=value;
//
//            token.StartPosition.Column:=lastPosition.Column;
//            token.StartPosition.Row:=lastPosition.Row;
//
//            token.EndPosition.Column:=currPosition.Column;
//            if CharInSet(currCh, [#32, #9]) then
//              Dec(token.EndPosition.Column);
//
//            token.EndPosition.Row:=currPosition.Row;
//
//            fTokenList.Add(token);
//
//            lastPosition.Column:=currPosition.Column+1;
//            lastPosition.Row:=currPosition.Row;
//          end;
//        end
//        else
//        begin
//          token:=tokenForOneCharReserved(currCh);
//
//          token.StartPosition.Column:=lastPosition.Column;
//          token.StartPosition.Row:=lastPosition.Row;
//          token.EndPosition.Column:=currPosition.Column;
//          token.EndPosition.Row:=currPosition.Row;
//
//          fTokenList.Add(token);
//
//          lastPosition.Column:=currPosition.Column+1;
//          lastPosition.Row:=currPosition.Row;
//          value:='';
//        end;
//      end
//      else
//      begin
//        lastPosition.Column:=currPosition.Column+1;
//        lastPosition.Row:=currPosition.Row;
//      end;
//    end;
//    Inc(currPosition.Column);
//  end;