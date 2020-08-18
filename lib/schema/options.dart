// @dart = 2.8

import 'package:json_annotation/json_annotation.dart';
import 'package:yaml/yaml.dart';

// I can't use the default json_serializable flow because the artemis generator
// would crash when importing options.dart file.
part 'options.g2.dart';

/// This generator options, gathered from `build.yaml` file.
@JsonSerializable(fieldRename: FieldRename.snake, anyMap: true)
class GeneratorOptions {
  /// If instances of [GraphQLQuery] should be generated.
  @JsonKey(defaultValue: true)
  final bool generateHelpers;

  /// A list of scalar mappings.
  @JsonKey(defaultValue: [])
  final List<ScalarMap> scalarMapping;

  /// A list of fragments apply for all query files without declare them.
  final String fragmentsGlob;

  /// A list of schema mappings.
  @JsonKey(defaultValue: [])
  final List<SchemaMap> schemaMapping;

  /// Instantiate generator options.
  GeneratorOptions({
    this.generateHelpers = true,
    this.scalarMapping = const [],
    this.fragmentsGlob,
    this.schemaMapping = const [],
  });

  /// Build options from a JSON map.
  factory GeneratorOptions.fromJson(Map<String, dynamic> json) =>
      _$GeneratorOptionsFromJson(json);

  /// Convert this options instance to JSON.
  Map<String, dynamic> toJson() => _$GeneratorOptionsToJson(this);
}

/// Define a Dart type.
@JsonSerializable()
class DartType {
  /// Dart type name.
  final String name;

  /// Package imports related to this type.
  @JsonKey(defaultValue: <String>[])
  final List<String> imports;

  /// Instantiate a Dart type.
  const DartType({
    this.name,
    this.imports = const [],
  });

  /// Build a Dart type from a JSON string or map.
  factory DartType.fromJson(dynamic json) {
    if (json is String) {
      return DartType(name: json);
    } else if (json is Map<String, dynamic>) {
      return _$DartTypeFromJson(json);
    } else if (json is YamlMap) {
      return _$DartTypeFromJson({
        'name': json['name'],
        'imports': (json['imports'] as YamlList).map((s) => s).toList(),
      });
    } else {
      throw 'Invalid YAML: $json';
    }
  }

  /// Convert this Dart type instance to JSON.
  Map<String, dynamic> toJson() => _$DartTypeToJson(this);
}

/// Maps a GraphQL scalar to a Dart type.
@JsonSerializable(fieldRename: FieldRename.snake)
class ScalarMap {
  /// The GraphQL type name.
  @JsonKey(name: 'graphql_type')
  final String graphQLType;

  /// The Dart type linked to this GraphQL type.
  final DartType dartType;

  /// If custom parser would be used.
  final String customParserImport;

  /// Instatiates a scalar mapping.
  ScalarMap({
    this.graphQLType,
    this.dartType,
    this.customParserImport,
  });

  /// Build a scalar mapping from a JSON map.
  factory ScalarMap.fromJson(Map<String, dynamic> json) =>
      _$ScalarMapFromJson(json);

  /// Convert this scalar mapping instance to JSON.
  Map<String, dynamic> toJson() => _$ScalarMapToJson(this);
}

/// The naming scheme to be used on generated classes names.
enum NamingScheme {
  /// Default, where the names of previous types are used as prefix of the
  /// next class. This can generate duplication on certain schemas.
  pathedWithTypes,

  /// The names of previous fields are used as prefix of the next class.
  pathedWithFields,

  /// Considers only the actual GraphQL class name. This will probably lead to
  /// duplication and an Artemis error unless user uses aliases.
  simple,
}

/// Maps a GraphQL schema to queries files.
@JsonSerializable(fieldRename: FieldRename.snake)
class SchemaMap {
  /// The output file of this queries glob.
  final String output;

  /// The GraphQL schema string.
  final String schema;

  /// A [Glob] to find queries files.
  final String queriesGlob;

  /// A metadata file this schema mapping to be used.
  final String metadataFile;

  /// A entity folder containing the entities.
  final String entityOutputFolder;

  /// A list of entities generated for this schema.
  final List<String> entities;

  /// The resolve type field used on this schema.
  @JsonKey(defaultValue: '__typename')
  final String typeNameField;

  /// The naming scheme to be used.
  ///
  /// - [NamingScheme.pathedWithTypes]: default, where the names of
  /// previous classes are used to generate the prefix.
  /// - [NamingScheme.pathedWithFields]: the field names are joined
  /// together to generate the path.
  /// - [NamingScheme.simple]: considers only the actual GraphQL class name.
  /// This will probably lead to duplication and an Artemis error unless you
  /// use aliases.
  @JsonKey(unknownEnumValue: NamingScheme.pathedWithTypes)
  final NamingScheme namingScheme;

  /// Instantiates a schema mapping.
  SchemaMap({
    this.output,
    this.schema,
    this.queriesGlob,
    this.metadataFile,
    this.entityOutputFolder,
    this.entities,
    this.typeNameField = '__typename',
    this.namingScheme = NamingScheme.pathedWithTypes,
  });

  /// Build a schema mapping from a JSON map.
  factory SchemaMap.fromJson(Map<String, dynamic> json) =>
      _$SchemaMapFromJson(json);

  /// Convert this schema mapping instance to JSON.
  Map<String, dynamic> toJson() => _$SchemaMapToJson(this);
}

/// Gql Metadata info detail for mapping responses from server.
@JsonSerializable(explicitToJson: true)
class GqlMetadataInfo {
  /// List Of queries for this entity type
  final List<GqlQueryInfo> queries;

  /// A map of entity key and entity info
  final Map<String, GqlEntityInfo> entities;

  /// Instantiates a GqlMetadataInfo.
  GqlMetadataInfo({this.queries, this.entities});

  /// Build a metadata info from a JSON map.
  factory GqlMetadataInfo.fromJson(Map<String, dynamic> json) =>
      _$GqlMetadataInfoFromJson(json);

  /// Convert this meta data instance to JSON.
  Map<String, dynamic> toJson() => _$GqlMetadataInfoToJson(this);
}

/// Queries model for this entity type
@JsonSerializable(explicitToJson: true)
class GqlQueryInfo {
  /// The operationName used for the query/mutation
  final String operationName;

  /// The entryPoint used for fetching or updating data
  final String entryPoint;

  /// The response type this query i.e QueryListResponse, QueryResponse and its Empty* equivalent
  final String responseType;

  /// The resultField which holds the output of this query if response type is QueryListResponse
  final String resultField;

  /// The deleteField which holds the ids which needs to be deleted if response type is QueryListResponse
  final String deleteIdsField;

  /// The lastFetchedTimestamp which holds the server timestamp for last fetch for this model.
  final String lastFetchedField;

  /// The entity key which points to the entity info mapping.
  final String entity;

  /// Get a clone of this object
  GqlQueryInfo clone({String responseType}) => GqlQueryInfo(
      operationName: operationName,
      entryPoint: entryPoint,
      responseType: responseType,
      resultField: resultField,
      deleteIdsField: deleteIdsField,
      lastFetchedField: lastFetchedField,
      entity: entity);

  /// Instantiates a DbQueryInfo.
  GqlQueryInfo({
    this.operationName,
    this.entryPoint,
    this.responseType,
    this.resultField,
    this.deleteIdsField,
    this.lastFetchedField,
    this.entity,
  });

  /// Build a db field info from a JSON map.
  factory GqlQueryInfo.fromJson(Map<String, dynamic> json) =>
      _$GqlQueryInfoFromJson(json);

  /// Convert this db field info instance to JSON.
  Map<String, dynamic> toJson() => _$GqlQueryInfoToJson(this);
}

/// Gql entity info
@JsonSerializable(explicitToJson: true)
class GqlEntityInfo {
  /// Table name to use for the response object storage.
  final String tableName;

  /// Primary key field name for the table.
  final GqlEntityFieldInfo pkField;

  /// Index field columns for the table.
  final List<GqlEntityFieldInfo> indexFields;

  /// Info about the detail column for the table.
  final GqlEntityFieldInfo detailField;

  /// The top level response fields to be moved to the detail column.
  final GqlEntityDetailFieldInfo detailFieldInfo;

  /// Instantiates a GqlEntityInfo.
  GqlEntityInfo({
    this.tableName,
    this.pkField,
    this.indexFields,
    this.detailField,
    this.detailFieldInfo,
  });

  /// Build a metadata info from a JSON map.
  factory GqlEntityInfo.fromJson(Map<String, dynamic> json) =>
      _$GqlEntityInfoFromJson(json);

  /// Convert this meta data instance to JSON.
  Map<String, dynamic> toJson() => _$GqlEntityInfoToJson(this);
}

/// Db field info for columns of table.
@JsonSerializable(explicitToJson: true)
class GqlEntityFieldInfo {
  /// Field name used for entity column name derived as snake_case version of this.
  final String fieldName;

  /// Field type of the above field should be one of sqlite supported types.
  final String fieldType;

  /// Instantiates a GqlEntityDetailFieldInfo.
  GqlEntityFieldInfo({this.fieldName, this.fieldType});

  /// Build a db field info from a JSON map.
  factory GqlEntityFieldInfo.fromJson(Map<String, dynamic> json) =>
      _$GqlEntityFieldInfoFromJson(json);

  /// Convert this db field info instance to JSON.
  Map<String, dynamic> toJson() => _$GqlEntityFieldInfoToJson(this);
}

/// Detail field keys info.
@JsonSerializable(explicitToJson: true)
class GqlEntityDetailFieldInfo {
  /// List of all fields which are of list types
  final List<String> listFields;

  /// Object field types
  final List<String> objectFields;

  /// Other field types
  final List<String> otherFields;

  /// Instantiates a GqlEntityDetailFieldInfo.
  GqlEntityDetailFieldInfo(
      {this.listFields, this.objectFields, this.otherFields});

  /// Build a db field info from a JSON map.
  factory GqlEntityDetailFieldInfo.fromJson(Map<String, dynamic> json) =>
      _$GqlEntityDetailFieldInfoFromJson(json);

  /// Convert this db field info instance to JSON.
  Map<String, dynamic> toJson() => _$GqlEntityDetailFieldInfoToJson(this);
}
