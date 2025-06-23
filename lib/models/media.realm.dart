// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class Folder extends _Folder with RealmEntity, RealmObjectBase, RealmObject {
  Folder(
    ObjectId id,
    String path,
    String name, {
    Iterable<Media> entities = const [],
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'path', path);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set<RealmList<Media>>(
      this,
      'entities',
      RealmList<Media>(entities),
    );
  }

  Folder._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, 'id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get path => RealmObjectBase.get<String>(this, 'path') as String;
  @override
  set path(String value) => RealmObjectBase.set(this, 'path', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  RealmList<Media> get entities =>
      RealmObjectBase.get<Media>(this, 'entities') as RealmList<Media>;
  @override
  set entities(covariant RealmList<Media> value) =>
      throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<Folder>> get changes =>
      RealmObjectBase.getChanges<Folder>(this);

  @override
  Stream<RealmObjectChanges<Folder>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Folder>(this, keyPaths);

  @override
  Folder freeze() => RealmObjectBase.freezeObject<Folder>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'path': path.toEJson(),
      'name': name.toEJson(),
      'entities': entities.toEJson(),
    };
  }

  static EJsonValue _toEJson(Folder value) => value.toEJson();
  static Folder _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'id': EJsonValue id, 'path': EJsonValue path, 'name': EJsonValue name} =>
        Folder(
          fromEJson(id),
          fromEJson(path),
          fromEJson(name),
          entities: fromEJson(ejson['entities']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Folder._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Folder, 'Folder', [
      SchemaProperty('id', RealmPropertyType.objectid, primaryKey: true),
      SchemaProperty('path', RealmPropertyType.string),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty(
        'entities',
        RealmPropertyType.object,
        linkTarget: 'Media',
        collectionType: RealmCollectionType.list,
      ),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class Media extends _Media with RealmEntity, RealmObjectBase, RealmObject {
  Media(ObjectId id, String path, String name, String thumbnailPath) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'path', path);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'thumbnailPath', thumbnailPath);
  }

  Media._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, 'id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get path => RealmObjectBase.get<String>(this, 'path') as String;
  @override
  set path(String value) => RealmObjectBase.set(this, 'path', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  String get thumbnailPath =>
      RealmObjectBase.get<String>(this, 'thumbnailPath') as String;
  @override
  set thumbnailPath(String value) =>
      RealmObjectBase.set(this, 'thumbnailPath', value);

  @override
  RealmResults<Folder> get folder {
    if (!isManaged) {
      throw RealmError('Using backlinks is only possible for managed objects.');
    }
    return RealmObjectBase.get<Folder>(this, 'folder') as RealmResults<Folder>;
  }

  @override
  set folder(covariant RealmResults<Folder> value) =>
      throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<Media>> get changes =>
      RealmObjectBase.getChanges<Media>(this);

  @override
  Stream<RealmObjectChanges<Media>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Media>(this, keyPaths);

  @override
  Media freeze() => RealmObjectBase.freezeObject<Media>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'path': path.toEJson(),
      'name': name.toEJson(),
      'thumbnailPath': thumbnailPath.toEJson(),
    };
  }

  static EJsonValue _toEJson(Media value) => value.toEJson();
  static Media _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'path': EJsonValue path,
        'name': EJsonValue name,
        'thumbnailPath': EJsonValue thumbnailPath,
      } =>
        Media(
          fromEJson(id),
          fromEJson(path),
          fromEJson(name),
          fromEJson(thumbnailPath),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Media._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Media, 'Media', [
      SchemaProperty('id', RealmPropertyType.objectid, primaryKey: true),
      SchemaProperty('path', RealmPropertyType.string),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('thumbnailPath', RealmPropertyType.string),
      SchemaProperty(
        'folder',
        RealmPropertyType.linkingObjects,
        linkOriginProperty: 'entities',
        collectionType: RealmCollectionType.list,
        linkTarget: 'Folder',
      ),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
