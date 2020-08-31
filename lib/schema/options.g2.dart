// GENERATED CODE - DO NOT MODIFY BY HAND
// @dart=2.8

part of 'options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratorOptions _$GeneratorOptionsFromJson(Map json) {
  return GeneratorOptions(
    generateHelpers: json['generate_helpers'] as bool ?? true,
    scalarMapping: (json['scalar_mapping'] as List)
            ?.map((e) => e == null
                ? null
                : ScalarMap.fromJson((e as Map)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )))
            ?.toList() ??
        [],
    fragmentsGlob: json['fragments_glob'] as String,
    schemaMapping: (json['schema_mapping'] as List)
            ?.map((e) => e == null
                ? null
                : SchemaMap.fromJson((e as Map)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )))
            ?.toList() ??
        [],
  );
}

Map<String, dynamic> _$GeneratorOptionsToJson(GeneratorOptions instance) =>
    <String, dynamic>{
      'generate_helpers': instance.generateHelpers,
      'scalar_mapping': instance.scalarMapping,
      'fragments_glob': instance.fragmentsGlob,
      'schema_mapping': instance.schemaMapping,
    };

DartType _$DartTypeFromJson(Map<String, dynamic> json) {
  return DartType(
    name: json['name'] as String,
    imports: (json['imports'] as List)?.map((e) => e as String)?.toList() ?? [],
  );
}

Map<String, dynamic> _$DartTypeToJson(DartType instance) => <String, dynamic>{
      'name': instance.name,
      'imports': instance.imports,
    };

ScalarMap _$ScalarMapFromJson(Map<String, dynamic> json) {
  return ScalarMap(
    graphQLType: json['graphql_type'] as String,
    dartType:
        json['dart_type'] == null ? null : DartType.fromJson(json['dart_type']),
    customParserImport: json['custom_parser_import'] as String,
  );
}

Map<String, dynamic> _$ScalarMapToJson(ScalarMap instance) => <String, dynamic>{
      'graphql_type': instance.graphQLType,
      'dart_type': instance.dartType,
      'custom_parser_import': instance.customParserImport,
    };

SchemaMap _$SchemaMapFromJson(Map<String, dynamic> json) {
  return SchemaMap(
    output: json['output'] as String,
    schema: json['schema'] as String,
    queriesGlob: json['queries_glob'] as String,
    metadataFile: json['metadata_file'] as String,
    entityOutputFolder: json['entity_output_folder'] as String,
    entities: (json['entities'] as List)?.map((e) => e as String)?.toList(),
    typeNameField: json['type_name_field'] as String ?? '__typename',
    namingScheme: _$enumDecodeNullable(
        _$NamingSchemeEnumMap, json['naming_scheme'],
        unknownValue: NamingScheme.pathedWithTypes),
  );
}

Map<String, dynamic> _$SchemaMapToJson(SchemaMap instance) => <String, dynamic>{
      'output': instance.output,
      'schema': instance.schema,
      'queries_glob': instance.queriesGlob,
      'metadata_file': instance.metadataFile,
      'entity_output_folder': instance.entityOutputFolder,
      'entities': instance.entities,
      'type_name_field': instance.typeNameField,
      'naming_scheme': _$NamingSchemeEnumMap[instance.namingScheme],
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$NamingSchemeEnumMap = {
  NamingScheme.pathedWithTypes: 'pathedWithTypes',
  NamingScheme.pathedWithFields: 'pathedWithFields',
  NamingScheme.simple: 'simple',
};

GqlMetadataInfo _$GqlMetadataInfoFromJson(Map<String, dynamic> json) {
  return GqlMetadataInfo(
    queries: (json['queries'] as List)
        ?.map((e) =>
            e == null ? null : GqlQueryInfo.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    entities: (json['entities'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k,
          e == null ? null : GqlEntityInfo.fromJson(e as Map<String, dynamic>)),
    ),
  );
}

Map<String, dynamic> _$GqlMetadataInfoToJson(GqlMetadataInfo instance) =>
    <String, dynamic>{
      'queries': instance.queries?.map((e) => e?.toJson())?.toList(),
      'entities': instance.entities?.map((k, e) => MapEntry(k, e?.toJson())),
    };

GqlQueryInfo _$GqlQueryInfoFromJson(Map<String, dynamic> json) {
  return GqlQueryInfo(
    operationName: json['operationName'] as String,
    entryPoint: json['entryPoint'] as String,
    responseType: json['responseType'] as String,
    resultField: json['resultField'] as String,
    deleteIdsField: json['deleteIdsField'] as String,
    lastFetchedField: json['lastFetchedField'] as String,
    entity: json['entity'] as String,
  );
}

Map<String, dynamic> _$GqlQueryInfoToJson(GqlQueryInfo instance) =>
    <String, dynamic>{
      'operationName': instance.operationName,
      'entryPoint': instance.entryPoint,
      'responseType': instance.responseType,
      'resultField': instance.resultField,
      'deleteIdsField': instance.deleteIdsField,
      'lastFetchedField': instance.lastFetchedField,
      'entity': instance.entity,
    };

GqlEntityInfo _$GqlEntityInfoFromJson(Map<String, dynamic> json) {
  return GqlEntityInfo(
    tableName: json['tableName'] as String,
    pkFields: (json['pkFields'] as List)
        ?.map((e) => e == null
            ? null
            : GqlEntityPKFieldInfo.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    deleteIdField: json['deleteIdField'] == null
        ? null
        : EntityFieldInfo.fromJson(
            json['deleteIdField'] as Map<String, dynamic>),
    indexFields: (json['indexFields'] as List)
        ?.map((e) => e == null
        ? null
        : EntityFieldInfo.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    detailFieldName: json['detailFieldName'] as String,
    detailFields:
        (json['detailFields'] as List)?.map((e) => e as String)?.toList(),
  );
}

Map<String, dynamic> _$GqlEntityInfoToJson(GqlEntityInfo instance) =>
    <String, dynamic>{
      'tableName': instance.tableName,
      'pkFields': instance.pkFields?.map((e) => e?.toJson())?.toList(),
      'deleteIdField': instance.deleteIdField?.toJson(),
      'indexFields': instance.indexFields,
      'detailFieldName': instance.detailFieldName,
      'detailFields': instance.detailFields,
    };

GqlEntityPKFieldInfo _$GqlEntityPKFieldInfoFromJson(Map<String, dynamic> json) {
  return GqlEntityPKFieldInfo(
    fieldName: json['fieldName'] as String,
    auto: json['auto'] as bool,
    mappedFieldDataType: json['mappedFieldDataType'] as String,
  );
}

Map<String, dynamic> _$GqlEntityPKFieldInfoToJson(
        GqlEntityPKFieldInfo instance) =>
    <String, dynamic>{
      'fieldName': instance.fieldName,
      'auto': instance.auto,
      'mappedFieldDataType': instance.mappedFieldDataType,
    };


GqlEntityFieldInfo _$GqlEntityFieldInfoFromJson(Map<String, dynamic> json) {
  return GqlEntityFieldInfo(
    fieldType: json['fieldType'] as String,
    fieldDataType: json['fieldDataType'] as String,
    mappedFieldDataType: json['mappedFieldDataType'] as String,
  );
}

Map<String, dynamic> _$GqlEntityFieldInfoToJson(GqlEntityFieldInfo instance) =>
    <String, dynamic>{
      'fieldType': instance.fieldType,
      'fieldDataType': instance.fieldDataType,
      'mappedFieldDataType': instance.mappedFieldDataType,
    };

EntityFieldInfo _$EntityFieldInfoFromJson(Map<String, dynamic> json) {
  return EntityFieldInfo(
    fieldName: json['fieldName'] as String,
    mappedFieldDataType: json['mappedFieldDataType'] as String,
  );
}

Map<String, dynamic> _$EntityFieldInfoToJson(EntityFieldInfo instance) =>
    <String, dynamic>{
      'fieldName': instance.fieldName,
      'mappedFieldDataType': instance.mappedFieldDataType,
    };
