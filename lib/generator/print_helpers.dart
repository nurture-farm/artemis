// @dart = 2.8

import 'package:artemis/generator/data/data.dart';
import 'package:artemis/generator/data/enum_value_definition.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:gql_code_gen/gql_code_gen.dart' as dart;
import 'package:recase/recase.dart';

import '../generator/helpers.dart';
import '../schema/options.dart';
import '../schema/options.dart';
import '../schema/options.dart';
import '../schema/options.dart';
import '../schema/options.dart';
import '../schema/options.dart';
import '../schema/options.dart';
import '../schema/options.dart';
import '../schema/options.dart';

/// Generates a [Spec] of a single enum definition.
Spec enumDefinitionToSpec(EnumDefinition definition) =>
    CodeExpression(Code('''enum ${definition.name.namePrintable} {
  ${definition.values.removeDuplicatedBy((i) => i).map(_enumValueToSpec).join()}
}'''));

String _enumValueToSpec(EnumValueDefinition value) {
  final annotations = value.annotations
      .map((annotation) => '@$annotation')
      .followedBy(['@JsonValue("${value.name.name}")']).join(' ');

  return '$annotations${value.name.namePrintable}, ';
}

/// Generate a [Spec] from single enum extension which will include two values.
Spec enumDefinitionExtensionToSpec(EnumDefinition definition) {
  final enumName = definition.name.namePrintable;
  final buffer = StringBuffer()
    ..writeln('extension ${enumName}Ext on ${enumName} {')
    ..writeln('  String toValue() {')
    ..writeln('    return _\$${enumName}EnumMap[this];')
    ..writeln('  }\n')
    ..writeln('  ${enumName} fromValue(String name) {')
    ..writeln('    return ${enumName}.artemisUnknown;')
    ..writeln('  }')
    ..writeln('}');
  return CodeExpression(Code(buffer.toString()));
}

String _fromJsonBody(ClassDefinition definition) {
  final buffer = StringBuffer();
  buffer.writeln(
      '''switch (json['${definition.typeNameField.name}'].toString()) {''');

  for (final p in definition.factoryPossibilities.entries) {
    buffer.writeln('''      case r'${p.key}':
        return ${p.value.namePrintable}.fromJson(json);''');
  }

  buffer.writeln('''      default:
    }
    return _\$${definition.name.namePrintable}FromJson(json);''');
  return buffer.toString();
}

String _toJsonBody(ClassDefinition definition) {
  final buffer = StringBuffer();
  final typeName = definition.typeNameField.namePrintable;
  buffer.writeln('''switch ($typeName) {''');

  for (final p in definition.factoryPossibilities.entries) {
    buffer.writeln('''      case r'${p.key}':
        return (this as ${p.value.namePrintable}).toJson();''');
  }

  buffer.writeln('''      default:
    }
    return _\$${definition.name.namePrintable}ToJson(this);''');
  return buffer.toString();
}

Method _propsMethod(String body) {
  return Method((m) => m
    ..type = MethodType.getter
    ..returns = refer('List<Object>')
    ..annotations.add(CodeExpression(Code('override')))
    ..name = 'props'
    ..lambda = true
    ..body = Code(body));
}

Method _stringifyMethod() {
  return Method((m) => m
    ..type = MethodType.getter
    ..returns = refer('bool')
    ..annotations.add(CodeExpression(Code('override')))
    ..name = 'stringify'
    ..lambda = true
    ..body = Code('true'));
}

/// Generates a [Spec] of a single class definition.
Spec classDefinitionToSpec(
  ClassDefinition definition,
  Iterable<FragmentClassDefinition> fragments,
  GqlMetadataInfo gqlMetadataInfo,
  Map<String, GqlQueryInfo> queryMappings,
) {
  final fromJson = definition.factoryPossibilities.isNotEmpty
      ? Constructor(
          (b) => b
            ..factory = true
            ..name = 'fromJson'
            ..requiredParameters.add(Parameter(
              (p) => p
                ..type = refer('Map<String, dynamic>')
                ..name = 'json',
            ))
            ..body = Code(_fromJsonBody(definition)),
        )
      : Constructor(
          (b) => b
            ..factory = true
            ..name = 'fromJson'
            ..lambda = true
            ..requiredParameters.add(Parameter(
              (p) => p
                ..type = refer('Map<String, dynamic>')
                ..name = 'json',
            ))
            ..body = Code('_\$${definition.name.namePrintable}FromJson(json)'),
        );

  final toJson = definition.factoryPossibilities.isNotEmpty
      ? Method(
          (m) => m
            ..name = 'toJson'
            ..returns = refer('Map<String, dynamic>')
            ..body = Code(_toJsonBody(definition)),
        )
      : Method(
          (m) => m
            ..name = 'toJson'
            ..lambda = true
            ..returns = refer('Map<String, dynamic>')
            ..body = Code('_\$${definition.name.namePrintable}ToJson(this)'),
        );

  final props = definition.mixins
      .map((i) {
        return fragments
            .firstWhere((f) {
              return f.name == i;
            })
            .properties
            .map((p) => p.name.namePrintable);
      })
      .expand((i) => i)
      .followedBy(definition.properties.map((p) => p.name.namePrintable));

  var classExtension = definition.extension != null
      ? refer(definition.extension.namePrintable)
      : null;

  final customOverrides = <Method>[];
  final className = definition.name.namePrintable;
  if (queryMappings.containsKey(className)) {
    final queryInfo = queryMappings[className];
    var gqlEntityInfo = null == gqlMetadataInfo.entities
        ? null
        : gqlMetadataInfo.entities[queryInfo.entity];
    if (queryInfo.responseType == QUERY_RESPONSE) {
      //add query response mapping for list type or detail type
      classExtension = refer(
          (null == gqlEntityInfo) ? EMPTY_QUERY_RESPONSE : QUERY_RESPONSE);
      _addQueryResponseMethods(customOverrides, gqlEntityInfo);
    } else if (queryInfo.responseType == QUERY_LIST_RESPONSE) {
      //add list mappings for current queryType
      classExtension = refer(QUERY_LIST_RESPONSE);
      classExtension = refer((null == gqlEntityInfo)
          ? EMPTY_QUERY_LIST_RESPONSE
          : QUERY_LIST_RESPONSE);
      _addQueryListResponseMethods(customOverrides, gqlEntityInfo, queryInfo);
    } else if (queryInfo.responseType == QUERY_DETAIL_RESPONSE) {
      //add detail mapping for current queryType
      classExtension = refer(QUERY_DETAIL_RESPONSE);
      _addQueryDetailResponseMethods(customOverrides, gqlEntityInfo, queryInfo);
    } else {
      throw Exception('Unknown response type ${queryInfo.responseType}');
    }
  }

  return Class(
    (b) => b
      ..annotations.add(CodeExpression(
          Code('JsonSerializable(explicitToJson: true, includeIfNull: false)')))
      ..name = definition.name.namePrintable
      ..mixins.add(refer('EquatableMixin'))
      ..mixins.addAll(definition.mixins.map((i) => refer(i.namePrintable)))
      ..methods.add(_propsMethod('[${props.join(',')}]'))
      ..methods.add(_stringifyMethod())
      ..extend = classExtension
      ..implements.addAll(definition.implementations.map((i) => refer(i)))
      ..constructors.add(Constructor((b) {
        if (definition.isInput) {
          b
            ..optionalParameters.addAll(definition.properties
                .where((property) =>
                    !property.isOverride && !property.isResolveType)
                .map(
                  (property) => Parameter(
                    (p) {
                      p
                        ..name = property.name.namePrintable
                        ..named = true
                        ..toThis = true;

                      if (property.isNonNull) {
                        p.annotations.add(refer('required'));
                      }
                    },
                  ),
                ));
        }
      }))
      ..constructors.add(fromJson)
      ..methods.add(toJson)
      ..methods.addAll(customOverrides)
      ..fields.addAll(definition.properties.map((p) {
        final field = Field(
          (f) => f
            ..name = p.name.namePrintable
            ..type = refer(p.type.namePrintable)
            ..annotations.addAll(
              p.annotations.map((e) => CodeExpression(Code(e))),
            ),
        );
        return field;
      })),
  );
}

void _addQueryListResponseMethods(
  List<Method> customOverrides,
  GqlEntityInfo gqlEntityInfo,
  GqlQueryInfo gqlQueryInfo,
) {
  if (null != gqlEntityInfo) {
    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('String')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'tableName'
      ..lambda = true
      ..body = Code('\'${gqlEntityInfo.tableName}\'')));

    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('String')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'deleteIdFieldName'
      ..lambda = true
      ..body = Code('\'${gqlEntityInfo.deleteIdField.fieldName}\'')));

    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('int')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'lastFetchedTimestamp'
      ..lambda = true
      ..body = Code((null == gqlQueryInfo.lastFetchedField)
          ? '0'
          : '${gqlQueryInfo.entryPoint}.${gqlQueryInfo.lastFetchedField}')));

    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('List<${gqlEntityInfo.deleteIdField.fieldDataType}>')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'deleteIds'
      ..lambda = true
      ..body = Code((null == gqlQueryInfo.deleteIdsField)
          ? '[]'
          : '${gqlQueryInfo.entryPoint}.${gqlQueryInfo.deleteIdsField}')));

    var rowsBody = (null == gqlQueryInfo.resultField)
        ? '${gqlQueryInfo.entryPoint}'
        : '${gqlQueryInfo.entryPoint}.${gqlQueryInfo.resultField}';
    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('List<QueryResponse>')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'rows'
      ..lambda = true
      ..body = Code(rowsBody)));
  }
}

void _addQueryDetailResponseMethods(
  List<Method> customOverrides,
  GqlEntityInfo gqlEntityInfo,
  GqlQueryInfo gqlQueryInfo,
) {
  var tableName = (null == gqlEntityInfo) ? '' : gqlEntityInfo.tableName;
  customOverrides.add(Method((m) => m
    ..type = MethodType.getter
    ..returns = refer('String')
    ..annotations.add(CodeExpression(Code('override')))
    ..name = 'tableName'
    ..lambda = true
    ..body = Code('\'${tableName}\'')));

  customOverrides.add(Method((m) => m
    ..type = MethodType.getter
    ..returns = refer('QueryResponse')
    ..annotations.add(CodeExpression(Code('override')))
    ..name = 'row'
    ..lambda = true
    ..body = Code('${gqlQueryInfo.entryPoint}')));
}

void _addQueryResponseMethods(
  List<Method> customOverrides,
  GqlEntityInfo gqlEntityInfo,
) {
  if (null != gqlEntityInfo) {
    // add detail mapping if present
    final buffer = StringBuffer();
    if (null != gqlEntityInfo.detailFields) {
      buffer.clear();
      buffer.writeln('{');
      for (var fieldInfo in gqlEntityInfo.detailFields) {
        if (equalsIgnoreCase(fieldInfo.fieldType, FT_PRIMITIVE)) {
          buffer.writeln('\'${fieldInfo.fieldName}\': ${fieldInfo.fieldName},');
        } else if (equalsIgnoreCase(fieldInfo.fieldType, FT_ENUM)) {
          buffer.writeln(
              '\'${fieldInfo.fieldName}\': ${fieldInfo.fieldName}.toValue(),');
        } else if (equalsIgnoreCase(fieldInfo.fieldType, FT_LIST)) {
          buffer.writeln(
              '\'${fieldInfo.fieldName}\': ${fieldInfo.fieldName}?.map((e) => e?.toJson())?.toList(),');
        } else if (equalsIgnoreCase(fieldInfo.fieldType, FT_OBJECT)) {
          buffer.writeln(
              '\'${fieldInfo.fieldName}\': ${fieldInfo.fieldName}?.toJson(),');
        }
      }
      buffer.writeln('}');

      customOverrides.add(
        Method(
          (m) => m
            ..type = MethodType.getter
            ..returns = refer('Map<String, dynamic>')
            ..name = gqlEntityInfo.detailFieldName
            ..lambda = true
            ..body = Code(buffer.toString()),
        ),
      );
    }

    buffer.clear();
    buffer.writeln('{');

    // If primary key is not auto generated and is not a custom field then add field
    gqlEntityInfo.pkFields.forEach((pkField) {
      if (!pkField.isAutoIncremented && !pkField.isCustomField) {
        buffer.writeln(
            '\'${ReCase(pkField.fieldName).snakeCase}\': ${pkField.fieldName},');
      }
    });

    for (var indexField in gqlEntityInfo.indexFields) {
      if (!indexField.isCustomField) {
        if (equalsIgnoreCase(indexField.fieldType, FT_PRIMITIVE)) {
          buffer.writeln(
              '\'${ReCase(indexField.fieldName).snakeCase}\': ${indexField.fieldName},');
        } else if (equalsIgnoreCase(indexField.fieldType, FT_ENUM)) {
          buffer.writeln(
              '\'${ReCase(indexField.fieldName).snakeCase}\': ${indexField.fieldName}.toValue(),');
        } else {
          throw Exception(
              'Index field can primitive or enum, but found ${indexField.fieldType}');
        }
      }
    }

    if (null != gqlEntityInfo.detailFieldName) {
      final detailColName = ReCase(gqlEntityInfo.detailFieldName).snakeCase;
      final detailColValue = 'jsonEncode(${gqlEntityInfo.detailFieldName})';
      buffer.writeln('\'$detailColName\': $detailColValue,');
    }
    buffer.writeln('}');

    //add column values
    customOverrides.add(Method((m) => m
      ..type = MethodType.getter
      ..returns = refer('Map<String, dynamic>')
      ..annotations.add(CodeExpression(Code('override')))
      ..name = 'columnValues'
      ..lambda = true
      ..body = Code(buffer.toString())));
  }
}

/// Generates a [Spec] of a single fragment class definition.
Spec fragmentClassDefinitionToSpec(FragmentClassDefinition definition) {
  final fields = (definition.properties ?? []).map((p) {
    final lines = <String>[];
    lines.addAll(p.annotations.map((e) => '@${e}'));
    lines.add('${p.type.namePrintable} ${p.name.namePrintable};');
    return lines.join('\n');
  });

  return CodeExpression(Code('''mixin ${definition.name.namePrintable} {
  ${fields.join('\n')}
}'''));
}

/// Generates a [Spec] of a detail model class.
Spec generateModelDetailClassSpec(
  String detailFieldName,
  List<GqlEntityFieldInfo> detailFields,
) {
  final detailFieldDefinitions = <Field>[];
  for (var detailField in detailFields) {
    detailFieldDefinitions.add(Field((f) => f
      ..type = refer(detailField.fieldDataType)
      ..name = detailField.fieldName));
  }
  final detailModelClassName = ReCase(detailFieldName).pascalCase;
  return Class(
    (b) => b
      ..annotations.add(CodeExpression(
          Code('JsonSerializable(explicitToJson: true, includeIfNull: false)')))
      ..name = detailModelClassName
      ..constructors.add(Constructor(
        (b) => b,
      ))
      ..constructors.add(Constructor(
        (b) => b
          ..factory = true
          ..name = 'fromJson'
          ..lambda = true
          ..requiredParameters.add(Parameter(
            (p) => p
              ..type = refer('Map<String, dynamic>')
              ..name = 'json',
          ))
          ..body = Code('_\$${detailModelClassName}FromJson(json)'),
      ))
      ..methods.add(Method(
        (m) => m
          ..name = 'toJson'
          ..lambda = true
          ..returns = refer('Map<String, dynamic>')
          ..body = Code('_\$${detailModelClassName}ToJson(this)'),
      ))
      ..fields.addAll(detailFieldDefinitions),
  );
}

/// Generates a [Spec] of a mutation argument class.
Spec generateArgumentClassSpec(QueryDefinition definition) {
  return Class(
    (b) => b
      ..annotations.add(CodeExpression(
          Code('JsonSerializable(explicitToJson: true, includeIfNull: false)')))
      ..name = '${definition.className}Arguments'
      ..extend = refer('JsonSerializable')
      ..mixins.add(refer('EquatableMixin'))
      ..methods.add(_propsMethod(
          '[${definition.inputs.map((input) => input.name.namePrintable).join(',')}]'))
      ..constructors.add(Constructor(
        (b) => b
          ..optionalParameters.addAll(definition.inputs.map(
            (input) => Parameter(
              (p) {
                p
                  ..name = input.name.namePrintable
                  ..named = true
                  ..toThis = true;

                if (input.isNonNull) {
                  p.annotations.add(refer('required'));
                }
              },
            ),
          )),
      ))
      ..constructors.add(Constructor(
        (b) => b
          ..factory = true
          ..name = 'fromJson'
          ..lambda = true
          ..requiredParameters.add(Parameter(
            (p) => p
              ..type = refer('Map<String, dynamic>')
              ..name = 'json',
          ))
          ..body = Code('_\$${definition.className}ArgumentsFromJson(json)'),
      ))
      ..methods.add(Method(
        (m) => m
          ..name = 'toJson'
          ..lambda = true
          ..returns = refer('Map<String, dynamic>')
          ..body = Code('_\$${definition.className}ArgumentsToJson(this)'),
      ))
      ..fields.addAll(definition.inputs.map(
        (p) => Field(
          (f) => f
            ..name = p.name.namePrintable
            ..type = refer(p.type.namePrintable)
            ..modifier = FieldModifier.final$
            ..annotations
                .addAll(p.annotations.map((e) => CodeExpression(Code(e)))),
        ),
      )),
  );
}

/// Generates a [Spec] of a query/mutation class.
Spec generateQueryClassSpec(QueryDefinition definition) {
  final typeDeclaration = definition.inputs.isEmpty
      ? '${definition.name.namePrintable}, JsonSerializable'
      : '${definition.name.namePrintable}, ${definition.className}Arguments';

  final constructor = definition.inputs.isEmpty
      ? Constructor()
      : Constructor((b) => b
        ..optionalParameters.add(Parameter(
          (p) => p
            ..name = 'variables'
            ..toThis = true
            ..named = true,
        )));

  final fields = [
    Field(
      (f) => f
        ..annotations.add(CodeExpression(Code('override')))
        ..modifier = FieldModifier.final$
        ..type = refer('DocumentNode', 'package:gql/ast.dart')
        ..name = 'document'
        ..assignment = dart.fromNode(definition.document).code,
    ),
    Field(
      (f) => f
        ..annotations.add(CodeExpression(Code('override')))
        ..modifier = FieldModifier.final$
        ..type = refer('String')
        ..name = 'operationName'
        ..assignment = Code('\'${definition.operationName}\''),
    ),
  ];

  if (definition.inputs.isNotEmpty) {
    fields.add(Field(
      (f) => f
        ..annotations.add(CodeExpression(Code('override')))
        ..modifier = FieldModifier.final$
        ..type = refer('${definition.className}Arguments')
        ..name = 'variables',
    ));
  }

  return Class(
    (b) => b
      ..name = '${definition.className}${definition.suffix}'
      ..extend = refer('GraphQLQuery<$typeDeclaration>')
      ..constructors.add(constructor)
      ..fields.addAll(fields)
      ..methods.add(_propsMethod(
          '[document, operationName${definition.inputs.isNotEmpty ? ', variables' : ''}]'))
      ..methods.add(_stringifyMethod())
      ..methods.add(Method(
        (m) => m
          ..annotations.add(CodeExpression(Code('override')))
          ..returns = refer(definition.name.namePrintable)
          ..name = 'parse'
          ..requiredParameters.add(Parameter(
            (p) => p
              ..type = refer('Map<String, dynamic>')
              ..name = 'json',
          ))
          ..lambda = true
          ..body = Code('${definition.name.namePrintable}.fromJson(json)'),
      )),
  );
}

/// Gathers and generates a [Spec] of a whole query/mutation and its
/// dependencies into a single library file.
Spec generateLibrarySpec(
  LibraryDefinition definition,
  GqlMetadataInfo gqlMetadataInfo,
) {
  final importDirectives = [
    Directive.import('package:json_annotation/json_annotation.dart'),
    Directive.import('package:equatable/equatable.dart'),
    Directive.import('package:gql/ast.dart'),
    Directive.import('dart:convert'),
    Directive.import('package:nf_gql_client/nf_gql_client_lib.dart'),
  ];

  if (definition.queries.any((q) => q.generateHelpers)) {
    importDirectives.insertAll(
      0,
      [
        Directive.import('package:artemis/artemis.dart'),
      ],
    );
  }

  // inserts import of meta package only if there is at least one non nullable input
  // see this link for details https://github.com/dart-lang/sdk/issues/4188#issuecomment-240322222
  if (hasNonNullableInput(definition.queries)) {
    importDirectives.insertAll(
      0,
      [
        Directive.import('package:meta/meta.dart'),
      ],
    );
  }

  importDirectives.addAll(definition.customImports
      .map((customImport) => Directive.import(customImport)));

  final bodyDirectives = <Spec>[
    CodeExpression(Code('part \'${definition.basename}.g.dart\';')),
  ];

  final uniqueDefinitions = definition.queries
      .map((e) => e.classes.map((e) => e))
      .expand((e) => e)
      .fold<Map<String, Definition>>(<String, Definition>{}, (acc, element) {
    acc[element.name.name] = element;

    return acc;
  }).values;

  final queryMappings = <String, GqlQueryInfo>{};
  if (null != gqlMetadataInfo) {
    for (var query in definition.queries) {
      final queryInfo = gqlMetadataInfo.queries.firstWhere(
        (element) =>
            equalsIgnoreCase(element.operationName, query.operationName),
        orElse: () => null,
      );
      if (null != queryInfo) {
        //the base class mapping
        queryMappings[query.name.namePrintable] = queryInfo;

        //the detail class mapping if above is a list type
        if (equalsIgnoreCase(queryInfo.responseType, QUERY_LIST_RESPONSE)) {
          if (null == queryInfo.entryPoint || queryInfo.entryPoint.isEmpty) {
            throw Exception(
                'EntryPoint for ${query.operationName} cannot be null');
          }
          final entryPointClass =
              ClassName(name: queryInfo.entryPoint).namePrintable;

          if (null == queryInfo.resultField || queryInfo.resultField.isEmpty) {
            //no result field is present then this is directly mapped to an array
            queryMappings['${query.name.namePrintable}\$${entryPointClass}'] =
                queryInfo.clone(responseType: QUERY_RESPONSE);
          } else {
            //result field is present so map result to this field.
            final responseClass =
                ClassName(name: queryInfo.resultField).namePrintable;
            final detailClass =
                '${query.name.namePrintable}\$${entryPointClass}\$${responseClass}';
            queryMappings[detailClass] =
                queryInfo.clone(responseType: QUERY_RESPONSE);
          }
        }

        //the detail class mapping if above is a detail type
        if (equalsIgnoreCase(queryInfo.responseType, QUERY_DETAIL_RESPONSE)) {
          if (null == queryInfo.entryPoint || queryInfo.entryPoint.isEmpty) {
            throw Exception(
                'EntryPoint for ${query.operationName} cannot be null');
          }
          final entryPointClass =
              ClassName(name: queryInfo.entryPoint).namePrintable;
          final detailClass = '${query.name.namePrintable}\$${entryPointClass}';
          queryMappings[detailClass] =
              queryInfo.clone(responseType: QUERY_RESPONSE);
        }
      }
    }
  }

  final fragments = uniqueDefinitions.whereType<FragmentClassDefinition>();
  final classes = uniqueDefinitions.whereType<ClassDefinition>();
  final enums = uniqueDefinitions.whereType<EnumDefinition>();

  bodyDirectives.addAll(fragments.map(fragmentClassDefinitionToSpec));
  bodyDirectives.addAll(classes.map((cDef) => classDefinitionToSpec(
        cDef,
        fragments,
        gqlMetadataInfo,
        queryMappings,
      )));
  bodyDirectives.addAll(enums.map(enumDefinitionToSpec));
  bodyDirectives.addAll(enums.map(enumDefinitionExtensionToSpec));

  for (final queryDef in definition.queries) {
    if (queryDef.inputs.isNotEmpty && queryDef.generateHelpers) {
      bodyDirectives.add(generateArgumentClassSpec(queryDef));
    }
    if (queryDef.generateHelpers) {
      bodyDirectives.add(generateQueryClassSpec(queryDef));
    }
  }

  //generate model detail class if we have detail fields
  if (null != gqlMetadataInfo.entities && gqlMetadataInfo.entities.isNotEmpty) {
    for (var entityName in gqlMetadataInfo.entities.keys) {
      var gqlEntity = gqlMetadataInfo.entities[entityName];
      if (null != gqlEntity && null != gqlEntity.detailFields) {
        //add a detail class model for the current entity
        bodyDirectives.add(generateModelDetailClassSpec(
          gqlEntity.detailFieldName,
          gqlEntity.detailFields,
        ));
      }
    }
  }

  return Library(
    (b) => b..directives.addAll(importDirectives)..body.addAll(bodyDirectives),
  );
}

/// Generate dao spec from given metadata file
Spec generateEntitySpec(
  String packageName,
  String schemaOutputFile,
  String entityOutputFile,
  GqlEntityInfo gqlEntityInfo,
) {
  final outputFile = schemaOutputFile.replaceAll(RegExp(r'^lib/'), '');
  final importDirectives = [
    Directive.import('dart:convert'),
    Directive.import('package:floor/floor.dart'),
    Directive.import('package:$packageName/$outputFile'),
  ];
  final entityClassName = ReCase(
    entityOutputFile.substring(
      entityOutputFile.lastIndexOf('/') + 1,
      entityOutputFile.indexOf('.dart'),
    ),
  ).pascalCase;

  final bodyCode = StringBuffer();

  final entityFields = <Field>[];
  final parameterFields = <Parameter>[];
  //add primary key field if present
  if (null == gqlEntityInfo.pkFields) {
    throw Exception(
        'Primary key is required for entity ${gqlEntityInfo.tableName}');
  }

  gqlEntityInfo.pkFields.forEach((pkField) {
    if (!(equalsIgnoreCase(pkField.fieldType, FT_PRIMITIVE) ||
        equalsIgnoreCase(pkField.fieldType, FT_ENUM))) {
      throw Exception(
          'Field type ${pkField.fieldType} not supported for Primary key');
    }
    var pkAnnotation = pkField.isAutoIncremented
        ? 'PrimaryKey(autoGenerate: true)'
        : 'primaryKey';
    var fieldType = pkField.isAutoIncremented ? 'int' : pkField.fieldDataType;
    entityFields.add(
      Field(
        (f) => f
          ..name = pkField.fieldName
          ..type = refer(fieldType)
          ..annotations.add(CodeExpression(Code(pkAnnotation)))
          ..annotations.add(
            CodeExpression(
              Code(
                  'ColumnInfo(name: \'${ReCase(pkField.fieldName).snakeCase}\')'),
            ),
          ),
      ),
    );
    parameterFields.add(
      Parameter((p) => p
        ..name = pkField.fieldName
        ..toThis = true
        ..named = true),
    );
  });

  //add other index fields
  for (final indexField in gqlEntityInfo.indexFields) {
    if (!(equalsIgnoreCase(indexField.fieldType, FT_PRIMITIVE) ||
        equalsIgnoreCase(indexField.fieldType, FT_ENUM))) {
      throw Exception(
          'Unknown field type ${indexField.fieldType} for index field ${indexField.fieldName}');
    }

    entityFields.add(
      Field(
        (f) => f
          ..name = indexField.fieldName
          ..type = refer(indexField.fieldDataType)
          ..annotations.add(CodeExpression(Code(
              'ColumnInfo(name: \'${ReCase(indexField.fieldName).snakeCase}\')'))),
      ),
    );
    parameterFields.add(
      Parameter((p) => p
        ..name = indexField.fieldName
        ..toThis = true
        ..named = true),
    );
  }

  var entityMethods = <Method>[];
  if (null != gqlEntityInfo.detailFieldName) {
    //add detail field String column which will contain the json string
    entityFields.add(
      Field((f) => f
        ..name = gqlEntityInfo.detailFieldName
        ..type = refer('String')
        ..annotations.add(CodeExpression(Code(
            'ColumnInfo(name: \'${ReCase(gqlEntityInfo.detailFieldName).snakeCase}\')')))),
    );
    parameterFields.add(
      Parameter((p) => p
        ..name = gqlEntityInfo.detailFieldName
        ..toThis = true
        ..named = true),
    );

    final ignoreFieldName = '_${gqlEntityInfo.detailFieldName}Model';
    final modelFieldType = ReCase(gqlEntityInfo.detailFieldName).pascalCase;
    //add ignore field
    entityFields.add(
      Field((f) => f
        ..name = ignoreFieldName
        ..type = refer(modelFieldType)
        ..annotations.add(CodeExpression(Code('ignore')))),
    );

    //add detail model parsing logic
    bodyCode.clear();
    bodyCode.writeln(
        'if (null != $ignoreFieldName || null == ${gqlEntityInfo.detailFieldName}) {');
    bodyCode.writeln('  return $ignoreFieldName;');
    bodyCode.writeln('}');
    bodyCode.writeln(
        '$ignoreFieldName = ${modelFieldType}.fromJson(jsonDecode(${gqlEntityInfo.detailFieldName}));');
    bodyCode.writeln('return $ignoreFieldName;');

    entityMethods.add(
      Method((m) => m
        ..type = MethodType.getter
        ..returns = refer(modelFieldType)
        ..name = '${gqlEntityInfo.detailFieldName}Model'
        ..lambda = false
        ..body = Code(bodyCode.toString())),
    );
  }

  final bodyDirective = Class(
    (b) => b
      ..annotations.add(CodeExpression(
          Code('Entity(tableName: \'${gqlEntityInfo.tableName}\')')))
      ..name = entityClassName
      ..fields.addAll(entityFields)
      ..constructors.add(
        Constructor(
          (b) => b..requiredParameters.addAll(parameterFields),
        ),
      )
      ..methods.addAll(entityMethods),
  );

  return Library(
    (b) => b
      ..directives.addAll(importDirectives)
      ..body.add(bodyDirective),
  );
}

/// Emit a [Spec] into a String, considering Dart formatting.
String specToString(Spec spec) {
  final emitter = DartEmitter();
  return DartFormatter().format(spec.accept(emitter).toString());
}

/// Generate Dart code typing's from a query or mutation and its response from
/// a [QueryDefinition] into a buffer.
void writeLibraryDefinitionToBuffer(
  StringBuffer buffer,
  LibraryDefinition definition,
  GqlMetadataInfo gqlMetadataInfo,
) {
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND\n');
  buffer.write(specToString(generateLibrarySpec(
    definition,
    gqlMetadataInfo,
  )));
}

/// Generate an empty file just exporting the library. This is used to avoid
/// a breaking change on file generation.
String writeLibraryForwarder(LibraryDefinition definition) =>
    '''// GENERATED CODE - DO NOT MODIFY BY HAND
export '${definition.basename}.dart';
''';

/// Generate dart code for entity objects into a buffer.
void writeEntityObjectToBuffer(
  StringBuffer buffer,
  String packageName,
  String schemaOutputFile,
  String entityOutputFile,
  GqlEntityInfo gqlEntityInfo,
) {
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND\n');
  buffer.write(
    specToString(
      generateEntitySpec(
        packageName,
        schemaOutputFile,
        entityOutputFile,
        gqlEntityInfo,
      ),
    ),
  );
}
