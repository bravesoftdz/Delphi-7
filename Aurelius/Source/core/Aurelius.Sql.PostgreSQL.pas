unit Aurelius.Sql.PostgreSQL;

{$I Aurelius.inc}

interface

uses
  DB,
  Aurelius.Sql.AnsiSqlGenerator,
  Aurelius.Sql.BaseTypes,
  Aurelius.Sql.Commands,
  Aurelius.Sql.Interfaces,
  Aurelius.Sql.Metadata,
  Aurelius.Sql.Register;

type
  TPostgreSQLGenerator = class(TAnsiSQLGenerator)
  protected
    function GetMaxConstraintNameLength: Integer; override;
    procedure DefineColumnType(Column: TColumnMetadata); override;

    function GetGeneratorName: string; override;
    function GetSqlDialect: string; override;

    function GenerateGetNextSequenceValue(Command: TGetNextSequenceValueCommand): string; override;
    function GenerateCreateSequence(Sequence: TSequenceMetadata): string; override;
    function GenerateDropSequence(Sequence: TSequenceMetadata): string; override;
    function GenerateDropField(Column: TColumnMetadata): string; override;
    function GenerateLimitedSelect(SelectSql: TSelectSql; Command: TSelectCommand): string; override;

    function GetSupportedFeatures: TDBFeatures; override;

    // Database compatibility methods
    function GetSupportedFieldTypes: TFieldTypeSet; override;
    function ConvertValue(Value: Variant; FromType, ToType: TFieldType): Variant; override;
  end;

implementation
uses
  Variants, SysUtils;

{ TPostgreSQLGenerator }

function TPostgreSQLGenerator.ConvertValue(Value: Variant; FromType,
  ToType: TFieldType): Variant;
begin
//  if (FromType in [ftDate, ftTime, ftDateTime]) and (ToType in [ftDate, ftTime, ftDateTime]) then
//    Result := VarToDateTime(Value)
//  else
//  if (FromType = ftBlob) or (ToType = ftBlob) then
//    Result := Value
//  else
//    Result := inherited ConvertValue(Value, FromType, ToType);
  Result := inherited ConvertValue(Value, FromType, ToType);
end;

procedure TPostgreSQLGenerator.DefineColumnType(Column: TColumnMetadata);
begin
  DefineNumericColumnType(Column);
  if Column.DataType <> '' then
    Exit;

  case Column.FieldType of
    ftLargeint:
      Column.DataType := 'BIGINT';

    ftWideString:
      Column.DataType := 'VARCHAR($len)';
    ftFixedWideChar:
      Column.DataType := 'CHAR($len)';

    ftBoolean:
      Column.DataType := 'BOOLEAN';
    ftMemo:
      Column.DataType := 'TEXT';
    ftWideMemo:
      Column.DataType := 'TEXT';
    ftBlob:
      Column.DataType := 'BYTEA';
    ftGuid:
      Column.DataType := 'UUID';
  else
    inherited DefineColumnType(Column);
  end;
end;

function TPostgreSQLGenerator.GenerateCreateSequence(Sequence: TSequenceMetadata): string;
begin
  Result := Format('CREATE SEQUENCE %s START WITH %s INCREMENT BY %s MAXVALUE 9999999999;',
    [Sequence.Name, IntToStr(Sequence.InitialValue), IntToStr(Sequence.Increment)]);
end;

function TPostgreSQLGenerator.GenerateDropField(Column: TColumnMetadata): string;
begin
  result := InternalGenerateDropField(Column, True);
end;

function TPostgreSQLGenerator.GenerateDropSequence(Sequence: TSequenceMetadata): string;
begin
  Result := Format('DROP SEQUENCE %s;', [Sequence.Name]);
end;

function TPostgreSQLGenerator.GenerateGetNextSequenceValue(Command: TGetNextSequenceValueCommand): string;
begin
  Result := Format('SELECT NEXTVAL(''%s'');', [Command.SequenceName]);
end;

function TPostgreSQLGenerator.GenerateLimitedSelect(SelectSql: TSelectSql;
  Command: TSelectCommand): string;
begin
  Result := GenerateRegularSelect(SelectSql) + #13#10;

  if Command.HasMaxRows then
    Result := Result + Format('LIMIT %d', [Command.MaxRows]);
  if Command.HasFirstRow then
    Result := Result + Format(' OFFSET %d', [Command.FirstRow]);
end;

function TPostgreSQLGenerator.GetSqlDialect: string;
begin
  Result := 'PostgreSQL';
end;

function TPostgreSQLGenerator.GetGeneratorName: string;
begin
  Result := 'PostgreSQL SQL Generator';
end;

function TPostgreSQLGenerator.GetMaxConstraintNameLength: Integer;
begin
  Result := 63;
end;

function TPostgreSQLGenerator.GetSupportedFeatures: TDBFeatures;
begin
  Result := AllDBFeatures - [TDBFeature.AutoGenerated];
end;

function TPostgreSQLGenerator.GetSupportedFieldTypes: TFieldTypeSet;
begin
  Result := inherited GetSupportedFieldTypes;
  Result := Result + [ftBoolean, ftGuid];
end;

initialization
  TSQLGeneratorRegister.GetInstance.RegisterGenerator(TPostgreSQLGenerator.Create);

end.