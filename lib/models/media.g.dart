// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFolderCollection on Isar {
  IsarCollection<Folder> get folders => this.collection();
}

const FolderSchema = CollectionSchema(
  name: r'Folder',
  id: 6793289488482879694,
  properties: {
    r'name': PropertySchema(id: 0, name: r'name', type: IsarType.string),
    r'path': PropertySchema(id: 1, name: r'path', type: IsarType.string),
  },

  estimateSize: _folderEstimateSize,
  serialize: _folderSerialize,
  deserialize: _folderDeserialize,
  deserializeProp: _folderDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'entities': LinkSchema(
      id: 5433199146967939149,
      name: r'entities',
      target: r'Media',
      single: false,
    ),
  },
  embeddedSchemas: {},

  getId: _folderGetId,
  getLinks: _folderGetLinks,
  attach: _folderAttach,
  version: '3.3.0',
);

int _folderEstimateSize(
  Folder object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.path.length * 3;
  return bytesCount;
}

void _folderSerialize(
  Folder object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.name);
  writer.writeString(offsets[1], object.path);
}

Folder _folderDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Folder();
  object.id = id;
  object.name = reader.readString(offsets[0]);
  object.path = reader.readString(offsets[1]);
  return object;
}

P _folderDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _folderGetId(Folder object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _folderGetLinks(Folder object) {
  return [object.entities];
}

void _folderAttach(IsarCollection<dynamic> col, Id id, Folder object) {
  object.id = id;
  object.entities.attach(col, col.isar.collection<Media>(), r'entities', id);
}

extension FolderQueryWhereSort on QueryBuilder<Folder, Folder, QWhere> {
  QueryBuilder<Folder, Folder, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FolderQueryWhere on QueryBuilder<Folder, Folder, QWhereClause> {
  QueryBuilder<Folder, Folder, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Folder, Folder, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Folder, Folder, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension FolderQueryFilter on QueryBuilder<Folder, Folder, QFilterCondition> {
  QueryBuilder<Folder, Folder, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> nameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> pathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> pathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> pathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> pathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'path',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> pathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> pathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> pathContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> pathMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'path',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> pathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'path', value: ''),
      );
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> pathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'path', value: ''),
      );
    });
  }
}

extension FolderQueryObject on QueryBuilder<Folder, Folder, QFilterCondition> {}

extension FolderQueryLinks on QueryBuilder<Folder, Folder, QFilterCondition> {
  QueryBuilder<Folder, Folder, QAfterFilterCondition> entities(
    FilterQuery<Media> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'entities');
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> entitiesLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'entities', length, true, length, true);
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> entitiesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'entities', 0, true, 0, true);
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> entitiesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'entities', 0, false, 999999, true);
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> entitiesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'entities', 0, true, length, include);
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> entitiesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'entities', length, include, 999999, true);
    });
  }

  QueryBuilder<Folder, Folder, QAfterFilterCondition> entitiesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
        r'entities',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension FolderQuerySortBy on QueryBuilder<Folder, Folder, QSortBy> {
  QueryBuilder<Folder, Folder, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Folder, Folder, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Folder, Folder, QAfterSortBy> sortByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<Folder, Folder, QAfterSortBy> sortByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }
}

extension FolderQuerySortThenBy on QueryBuilder<Folder, Folder, QSortThenBy> {
  QueryBuilder<Folder, Folder, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Folder, Folder, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Folder, Folder, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Folder, Folder, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Folder, Folder, QAfterSortBy> thenByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<Folder, Folder, QAfterSortBy> thenByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }
}

extension FolderQueryWhereDistinct on QueryBuilder<Folder, Folder, QDistinct> {
  QueryBuilder<Folder, Folder, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Folder, Folder, QDistinct> distinctByPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'path', caseSensitive: caseSensitive);
    });
  }
}

extension FolderQueryProperty on QueryBuilder<Folder, Folder, QQueryProperty> {
  QueryBuilder<Folder, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Folder, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Folder, String, QQueryOperations> pathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'path');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMediaCollection on Isar {
  IsarCollection<Media> get medias => this.collection();
}

const MediaSchema = CollectionSchema(
  name: r'Media',
  id: 6434281596432674333,
  properties: {
    r'addedAt': PropertySchema(
      id: 0,
      name: r'addedAt',
      type: IsarType.dateTime,
    ),
    r'dominantColorValue': PropertySchema(
      id: 1,
      name: r'dominantColorValue',
      type: IsarType.long,
    ),
    r'durationMs': PropertySchema(
      id: 2,
      name: r'durationMs',
      type: IsarType.long,
    ),
    r'hasSubtitles': PropertySchema(
      id: 3,
      name: r'hasSubtitles',
      type: IsarType.bool,
    ),
    r'isFinished': PropertySchema(
      id: 4,
      name: r'isFinished',
      type: IsarType.bool,
    ),
    r'lastWatchedAt': PropertySchema(
      id: 5,
      name: r'lastWatchedAt',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(id: 6, name: r'name', type: IsarType.string),
    r'path': PropertySchema(id: 7, name: r'path', type: IsarType.string),
    r'playbackPositionMs': PropertySchema(
      id: 8,
      name: r'playbackPositionMs',
      type: IsarType.long,
    ),
    r'thumbnailPath': PropertySchema(
      id: 9,
      name: r'thumbnailPath',
      type: IsarType.string,
    ),
    r'watchedFraction': PropertySchema(
      id: 10,
      name: r'watchedFraction',
      type: IsarType.double,
    ),
    r'watchedTogetherAt': PropertySchema(
      id: 11,
      name: r'watchedTogetherAt',
      type: IsarType.dateTime,
    ),
    r'watchedWith': PropertySchema(
      id: 12,
      name: r'watchedWith',
      type: IsarType.stringList,
    ),
  },

  estimateSize: _mediaEstimateSize,
  serialize: _mediaSerialize,
  deserialize: _mediaDeserialize,
  deserializeProp: _mediaDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'folder': LinkSchema(
      id: 1350394804088625431,
      name: r'folder',
      target: r'Folder',
      single: false,
      linkName: r'entities',
    ),
  },
  embeddedSchemas: {},

  getId: _mediaGetId,
  getLinks: _mediaGetLinks,
  attach: _mediaAttach,
  version: '3.3.0',
);

int _mediaEstimateSize(
  Media object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.path.length * 3;
  {
    final value = object.thumbnailPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.watchedWith.length * 3;
  {
    for (var i = 0; i < object.watchedWith.length; i++) {
      final value = object.watchedWith[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _mediaSerialize(
  Media object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.addedAt);
  writer.writeLong(offsets[1], object.dominantColorValue);
  writer.writeLong(offsets[2], object.durationMs);
  writer.writeBool(offsets[3], object.hasSubtitles);
  writer.writeBool(offsets[4], object.isFinished);
  writer.writeDateTime(offsets[5], object.lastWatchedAt);
  writer.writeString(offsets[6], object.name);
  writer.writeString(offsets[7], object.path);
  writer.writeLong(offsets[8], object.playbackPositionMs);
  writer.writeString(offsets[9], object.thumbnailPath);
  writer.writeDouble(offsets[10], object.watchedFraction);
  writer.writeDateTime(offsets[11], object.watchedTogetherAt);
  writer.writeStringList(offsets[12], object.watchedWith);
}

Media _mediaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Media();
  object.addedAt = reader.readDateTimeOrNull(offsets[0]);
  object.dominantColorValue = reader.readLong(offsets[1]);
  object.durationMs = reader.readLong(offsets[2]);
  object.hasSubtitles = reader.readBool(offsets[3]);
  object.id = id;
  object.lastWatchedAt = reader.readDateTimeOrNull(offsets[5]);
  object.name = reader.readString(offsets[6]);
  object.path = reader.readString(offsets[7]);
  object.playbackPositionMs = reader.readLong(offsets[8]);
  object.thumbnailPath = reader.readStringOrNull(offsets[9]);
  object.watchedTogetherAt = reader.readDateTimeOrNull(offsets[11]);
  object.watchedWith = reader.readStringList(offsets[12]) ?? [];
  return object;
}

P _mediaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 12:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _mediaGetId(Media object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _mediaGetLinks(Media object) {
  return [object.folder];
}

void _mediaAttach(IsarCollection<dynamic> col, Id id, Media object) {
  object.id = id;
  object.folder.attach(col, col.isar.collection<Folder>(), r'folder', id);
}

extension MediaQueryWhereSort on QueryBuilder<Media, Media, QWhere> {
  QueryBuilder<Media, Media, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MediaQueryWhere on QueryBuilder<Media, Media, QWhereClause> {
  QueryBuilder<Media, Media, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Media, Media, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Media, Media, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension MediaQueryFilter on QueryBuilder<Media, Media, QFilterCondition> {
  QueryBuilder<Media, Media, QAfterFilterCondition> addedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'addedAt'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> addedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'addedAt'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> addedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'addedAt', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> addedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'addedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> addedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'addedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> addedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'addedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> dominantColorValueEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dominantColorValue', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  dominantColorValueGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dominantColorValue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> dominantColorValueLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dominantColorValue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> dominantColorValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dominantColorValue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationMsEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'durationMs', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'durationMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'durationMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> durationMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'durationMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> hasSubtitlesEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasSubtitles', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> isFinishedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isFinished', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> lastWatchedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastWatchedAt'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> lastWatchedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastWatchedAt'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> lastWatchedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastWatchedAt', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> lastWatchedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastWatchedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> lastWatchedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastWatchedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> lastWatchedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastWatchedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'path',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'path',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'path', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> pathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'path', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> playbackPositionMsEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'playbackPositionMs', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  playbackPositionMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'playbackPositionMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> playbackPositionMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'playbackPositionMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> playbackPositionMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'playbackPositionMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'thumbnailPath'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'thumbnailPath'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'thumbnailPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'thumbnailPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'thumbnailPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'thumbnailPath', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> thumbnailPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'thumbnailPath', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedFractionEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'watchedFraction',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedFractionGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'watchedFraction',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedFractionLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'watchedFraction',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedFractionBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'watchedFraction',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedTogetherAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'watchedTogetherAt'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  watchedTogetherAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'watchedTogetherAt'),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedTogetherAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'watchedTogetherAt', value: value),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  watchedTogetherAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'watchedTogetherAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedTogetherAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'watchedTogetherAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedTogetherAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'watchedTogetherAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedWithElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'watchedWith',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  watchedWithElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'watchedWith',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedWithElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'watchedWith',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedWithElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'watchedWith',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  watchedWithElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'watchedWith',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedWithElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'watchedWith',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedWithElementContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'watchedWith',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedWithElementMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'watchedWith',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  watchedWithElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'watchedWith', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  watchedWithElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'watchedWith', value: ''),
      );
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedWithLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'watchedWith', length, true, length, true);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedWithIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'watchedWith', 0, true, 0, true);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedWithIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'watchedWith', 0, false, 999999, true);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedWithLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'watchedWith', 0, true, length, include);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition>
  watchedWithLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'watchedWith', length, include, 999999, true);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> watchedWithLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'watchedWith',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension MediaQueryObject on QueryBuilder<Media, Media, QFilterCondition> {}

extension MediaQueryLinks on QueryBuilder<Media, Media, QFilterCondition> {
  QueryBuilder<Media, Media, QAfterFilterCondition> folder(
    FilterQuery<Folder> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'folder');
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> folderLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'folder', length, true, length, true);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> folderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'folder', 0, true, 0, true);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> folderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'folder', 0, false, 999999, true);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> folderLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'folder', 0, true, length, include);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> folderLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'folder', length, include, 999999, true);
    });
  }

  QueryBuilder<Media, Media, QAfterFilterCondition> folderLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
        r'folder',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension MediaQuerySortBy on QueryBuilder<Media, Media, QSortBy> {
  QueryBuilder<Media, Media, QAfterSortBy> sortByAddedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByAddedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByDominantColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dominantColorValue', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByDominantColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dominantColorValue', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByHasSubtitles() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSubtitles', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByHasSubtitlesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSubtitles', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByIsFinished() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFinished', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByIsFinishedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFinished', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByLastWatchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastWatchedAt', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByLastWatchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastWatchedAt', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByPlaybackPositionMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playbackPositionMs', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByPlaybackPositionMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playbackPositionMs', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByWatchedFraction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedFraction', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByWatchedFractionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedFraction', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByWatchedTogetherAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedTogetherAt', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> sortByWatchedTogetherAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedTogetherAt', Sort.desc);
    });
  }
}

extension MediaQuerySortThenBy on QueryBuilder<Media, Media, QSortThenBy> {
  QueryBuilder<Media, Media, QAfterSortBy> thenByAddedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByAddedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addedAt', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByDominantColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dominantColorValue', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByDominantColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dominantColorValue', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByDurationMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationMs', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByHasSubtitles() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSubtitles', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByHasSubtitlesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasSubtitles', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByIsFinished() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFinished', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByIsFinishedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFinished', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByLastWatchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastWatchedAt', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByLastWatchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastWatchedAt', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByPlaybackPositionMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playbackPositionMs', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByPlaybackPositionMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'playbackPositionMs', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByWatchedFraction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedFraction', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByWatchedFractionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedFraction', Sort.desc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByWatchedTogetherAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedTogetherAt', Sort.asc);
    });
  }

  QueryBuilder<Media, Media, QAfterSortBy> thenByWatchedTogetherAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'watchedTogetherAt', Sort.desc);
    });
  }
}

extension MediaQueryWhereDistinct on QueryBuilder<Media, Media, QDistinct> {
  QueryBuilder<Media, Media, QDistinct> distinctByAddedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'addedAt');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByDominantColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dominantColorValue');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByDurationMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationMs');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByHasSubtitles() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasSubtitles');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByIsFinished() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFinished');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByLastWatchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastWatchedAt');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'path', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByPlaybackPositionMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'playbackPositionMs');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByThumbnailPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'thumbnailPath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByWatchedFraction() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'watchedFraction');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByWatchedTogetherAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'watchedTogetherAt');
    });
  }

  QueryBuilder<Media, Media, QDistinct> distinctByWatchedWith() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'watchedWith');
    });
  }
}

extension MediaQueryProperty on QueryBuilder<Media, Media, QQueryProperty> {
  QueryBuilder<Media, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Media, DateTime?, QQueryOperations> addedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addedAt');
    });
  }

  QueryBuilder<Media, int, QQueryOperations> dominantColorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dominantColorValue');
    });
  }

  QueryBuilder<Media, int, QQueryOperations> durationMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationMs');
    });
  }

  QueryBuilder<Media, bool, QQueryOperations> hasSubtitlesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasSubtitles');
    });
  }

  QueryBuilder<Media, bool, QQueryOperations> isFinishedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFinished');
    });
  }

  QueryBuilder<Media, DateTime?, QQueryOperations> lastWatchedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastWatchedAt');
    });
  }

  QueryBuilder<Media, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Media, String, QQueryOperations> pathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'path');
    });
  }

  QueryBuilder<Media, int, QQueryOperations> playbackPositionMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'playbackPositionMs');
    });
  }

  QueryBuilder<Media, String?, QQueryOperations> thumbnailPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailPath');
    });
  }

  QueryBuilder<Media, double, QQueryOperations> watchedFractionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'watchedFraction');
    });
  }

  QueryBuilder<Media, DateTime?, QQueryOperations> watchedTogetherAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'watchedTogetherAt');
    });
  }

  QueryBuilder<Media, List<String>, QQueryOperations> watchedWithProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'watchedWith');
    });
  }
}
