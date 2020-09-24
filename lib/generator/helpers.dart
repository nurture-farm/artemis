// @dart = 2.8

import 'package:artemis/generator/data/data.dart';

import '../schema/options.dart';

typedef _IterableFunction<T, U> = U Function(T i);
typedef _MergeableFunction<T> = T Function(T oldT, T newT);

/// a list of dart lang keywords
List<String> dartKeywords = const [
  'abstract',
  'else',
  'import',
  'super',
  'as',
  'enum',
  'in',
  'switch',
  'assert',
  'export',
  'interface',
  'sync',
  'async',
  'extends',
  'is',
  'this',
  'await',
  'extension',
  'library',
  'throw',
  'break',
  'external',
  'mixin',
  'true',
  'case',
  'factory',
  'new',
  'try',
  'catch',
  'false',
  'null',
  'typedef',
  'class',
  'final',
  'on',
  'var',
  'const',
  'finally',
  'operator',
  'void',
  'continue',
  'for',
  'part',
  'while',
  'covariant',
  'Function',
  'rethrow',
  'with',
  'default',
  'get',
  'return',
  'yield',
  'deferred',
  'hide',
  'set',
  'do',
  'if',
  'show',
  'dynamic',
  'implements',
  'static',
];

Iterable<T> _removeDuplicatedBy<T, U>(
    Iterable<T> list, _IterableFunction<T, U> fn) {
  final values = <U, bool>{};
  return list.where((i) {
    final value = fn(i);
    return values.update(value, (_) => false, ifAbsent: () => true);
  }).toList();
}

/// List data type prefix
final String listPrefix = 'List<';

/// normalizes name
/// _variable => $variable
/// __typename => $$typename
/// new -> kw$new
String normalizeName(String name) {
  if (name == null) {
    return name;
  }

  final regExp = RegExp(r'^(_+)([\w$]*)$');
  var matches = regExp.allMatches(name);

  if (matches.isNotEmpty) {
    var match = matches.elementAt(0);
    var fieldName = match.group(2);

    return fieldName.padLeft(name.length, r'$');
  }

  if (dartKeywords.contains(name.toLowerCase())) {
    return 'kw\$$name';
  }

//  if (name.startsWith(listPrefix)) {
//    var prefixIndex = name.indexOf(listPrefix) + listPrefix.length;
//    var prefix = name.substring(0, listPrefix.length);
//    var infix = name.substring(prefixIndex, prefixIndex + 1);
//    var suffix = name.substring(prefixIndex + 1);
//    return '$prefix${infix.toUpperCase()}$suffix';
//  }

  return name;
}

Iterable<T> _mergeDuplicatesBy<T, U>(Iterable<T> list,
    _IterableFunction<T, U> fn, _MergeableFunction<T> mergeFn) {
  final values = <U, T>{};
  list.forEach((i) {
    final value = fn(i);
    values.update(value, (oldI) => mergeFn(oldI, i), ifAbsent: () => i);
  });
  return values.values.toList();
}

/// Merge multiple values from an iterable given a predicate without modifying
/// the original iterable.
extension ExtensionsOnIterable<T, U> on Iterable<T> {
  /// Merge multiple values from an iterable given a predicate without modifying
  /// the original iterable.
  Iterable<T> mergeDuplicatesBy(
          _IterableFunction<T, U> fn, _MergeableFunction<T> mergeFn) =>
      _mergeDuplicatesBy(this, fn, mergeFn);

  /// Remove duplicated values from an iterable given a predicate without
  /// modifying the original iterable.
  Iterable<T> removeDuplicatedBy(_IterableFunction<T, U> fn) =>
      _removeDuplicatedBy(this, fn);
}

/// checks if the passed queries contain at least one non nullable field
bool hasNonNullableInput(Iterable<QueryDefinition> queries) {
  for (final query in queries) {
    for (final clazz in query.classes.whereType<ClassDefinition>()) {
      for (final property in clazz.properties) {
        if (property.isNonNull) {
          return true;
        }
      }
    }
    for (final input in query.inputs) {
      if (input.isNonNull) {
        return true;
      }
    }
  }

  return false;
}

/// Check if [obj] has value (isn't null or empty).
bool hasValue(Object obj) {
  if (obj is Iterable) {
    return obj != null && obj.isNotEmpty;
  }
  return obj != null && obj.toString().isNotEmpty;
}

/// Check if values are equal
bool equalsIgnoreCase(String a, String b) =>
    (a == null && b == null) ||
    (a != null && b != null && a.toLowerCase() == b.toLowerCase());

/// a list of sqlite types that can be stored in db
List<String> sqliteTypes = const [
  'int',
  'double',
  'String',
  'bool',
  'Uint8List'
];

/// Field type of enum
const String FT_PRIMITIVE = 'PRIMITIVE';
const String FT_ENUM = 'ENUM';
const String FT_LIST = 'LIST';
const String FT_OBJECT = 'OBJECT';

/// A constant specifying query response type object
const String QUERY_RESPONSE = 'QueryResponse';
const String EMPTY_QUERY_RESPONSE = 'EmptyQueryResponse';

/// A constant specifying query list response type object
const String QUERY_LIST_RESPONSE = 'QueryListResponse';
const String EMPTY_QUERY_LIST_RESPONSE = 'EmptyQueryListResponse';

/// A constant specifying query detail response type object
const String QUERY_DETAIL_RESPONSE = 'QueryDetailResponse';
