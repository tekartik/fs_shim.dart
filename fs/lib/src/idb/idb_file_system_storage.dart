// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_browser.dart';
import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/import.dart'; // ignore: unnecessary_import
import 'package:idb_shim/idb_client.dart' as idb;
import 'package:idb_shim/utils/idb_utils.dart';

import 'idb_fs.dart';

/// Default page size
const defaultPageSize = 16 * 1024;

const String treeStoreName = 'tree';
const String fileStoreName = 'file'; // Whole file content
const String partStoreName = 'part'; // Page based file content
const String nameKey = 'name';

/// That's life to deal with existing
///
/// For file: 'pn': '1/file.txt'
/// For root: 'pn': '/'
///
/// So basically the id of the parent separated with the file name. Unique access
const String parentNameKey = 'pn'; // indexed - this is actually the full name
const String parentNameIndexName = parentNameKey;

/// Indexed, id of the parent record
const String parentKey = 'parent'; // indexed
const String parentIndexName = parentKey;
const String typeKey = 'type';
const String modifiedKey = 'modified';
const String sizeKey = 'size';
const String pageSizeKey = 'ps'; // page size (in page, if null, means in file)
const String targetKey = 'target'; // Link only

/// Page
/// part (generated>:
/// file: <treeId> (id in tree)
/// index: <partIndex>
/// content: <blob>

const String indexKey = 'index'; // part index
const String fileKey = 'file'; // id in tree
const String contentKey = 'content'; // content in part

const String partFilePartIndexName = '${partStoreName}_$indexKey';

List toFilePartIndexKey(int fileId, int index) => [fileId, index];

List _filePartIndexKeyAsList(Object key) => (key as List);

int filePartIndexKeyFileId(Object key) =>
    _filePartIndexKeyAsList(key)[0] as int;

int filePartIndexKeyPartIndex(Object key) =>
    _filePartIndexKeyAsList(key)[1] as int;

bool segmentsAreAbsolute(Iterable<String> segments) {
  return segments.isNotEmpty &&
      segments.first.startsWith(idbPathContext.separator);
}

bool segmentsAreRelative(Iterable<String> segments) =>
    !segmentsAreAbsolute(segments);

List<String> getAbsoluteSegments(Node origin, List<String> target) {
  if (segmentsAreAbsolute(target)) {
    return target;
  }
  final targetSegments = List<String>.from(getParentSegments(origin.segments)!);
  targetSegments.addAll(target);
  return targetSegments;
}

/// We use the same database
class IdbFileSystemStorageWithDelegate extends IdbFileSystemStorage {
  final IdbFileSystemStorage delegate;
  @override
  idb.Database? get db => delegate.db;
  @override
  Future get ready => delegate.ready;

  IdbFileSystemStorageWithDelegate(
      {required this.delegate, required FileSystemIdbOptions options})
      : super(delegate.idbFactory, delegate.dbPath, options: options);
}

// not exported
class IdbFileSystemStorage {
  idb.IdbFactory idbFactory;
  String dbPath;
  FileSystemIdbOptions options;
  int get pageSize => options.pageSize ?? 0;

  IdbFileSystemStorage(this.idbFactory, this.dbPath, {required this.options});

  /// Use for derived options
  IdbFileSystemStorage withOptions({required FileSystemIdbOptions options}) =>
      IdbFileSystemStorageWithDelegate(delegate: this, options: options);

  idb.Database? db;
  Completer? _readyCompleter;

  Future get ready async {
    if (_readyCompleter == null) {
      _readyCompleter = Completer();

      // version 4: add file store
      db = await idbFactory.open(dbPath, version: 7,
          onUpgradeNeeded: (idb.VersionChangeEvent e) {
        final db = e.database;
        idb.ObjectStore store;

        // Older export have version equals to 1 so handle it
        if (e.oldVersion < 1) {
          // delete previous if any
          final storeNames = db.objectStoreNames;
          if (storeNames.contains(treeStoreName)) {
            db.deleteObjectStore(treeStoreName);
          }
          if (storeNames.contains(fileStoreName)) {
            db.deleteObjectStore(fileStoreName);
          }
          if (storeNames.contains(partStoreName)) {
            db.deleteObjectStore(partStoreName);
          }
          store = db.createObjectStore(treeStoreName, autoIncrement: true);
          store.createIndex(parentNameIndexName, parentNameKey,
              unique: true); // <id_parent>/<name>
          store.createIndex(parentIndexName, parentKey);

          store = db.createObjectStore(fileStoreName);
        }
        if (e.oldVersion < 7) {
          store = db.createObjectStore(partStoreName, autoIncrement: true);
          store.createIndex(partFilePartIndexName, [fileKey, indexKey],
              unique: true);
        }
      }, onBlocked: (e) {
        print(e);
        print('#### db format change - reload');
      });
      _readyCompleter!.complete();
    }
    return _readyCompleter!.future;
  }

  /// Set the content of a file and update meta.
  Future<Node> txnSetFileDataV1(
      idb.Transaction txn, Node treeEntity, Uint8List bytes) async {
    // devPrint('_txnSetFileData all ${bytes.length}');
    // Content store
    var fileStore = txn.objectStore(fileStoreName);
    await fileStore.put(bytes, treeEntity.id);

    // update size
    var treeStore = txn.objectStore(treeStoreName);
    var newTreeEntity = treeEntity.clone(pageSize: 0, size: bytes.length);
    await treeStore.put(newTreeEntity.toMap(), treeEntity.id);
    return newTreeEntity;
  }

  int _pageCountFromSize(int size) =>
      pageSize == 0 ? 1 : ((((size - 1) ~/ pageSize)) + 1);

  /// Set the content of a file and update meta. return the updated node
  Future<Node> txnSetFileDataV2(
      idb.Transaction txn, Node treeEntity, Uint8List bytes) async {
    var fileId = treeEntity.id!;
    var partCount = _pageCountFromSize(bytes.length);
    // Ignore existing
    var partStore = txn.objectStore(partStoreName);
    var partIndex = partStore.index(partFilePartIndexName);
    var stream = partIndex.openKeyCursor(
        range: idb.KeyRange.bound(toFilePartIndexKey(fileId, 0),
            toFilePartIndexKey(fileId + 1, 0), true, false),
        autoAdvance: true);
    final list = <KeyCursorRow>[];
    await stream.listen((idb.Cursor cursor) {
      var partFileIndex = filePartIndexKeyPartIndex(cursor.key);
      if (partFileIndex >= partCount) {
        // devPrint('delete part ${cursor.key}');
        cursor.delete();
      } else {
        list.add(KeyCursorRow(cursor.key, cursor.primaryKey));
      }
    }).asFuture();
    var rows = list;
    var rowByPageIndex = rows.asMap().map(
        (index, row) => MapEntry((rows[index].key as List)[1] as int, row));

    // Write the new ones
    var chunks = uint8ListChunk(bytes, pageSize);
    for (var i = 0; i < chunks.length; i++) {
      var chunk = chunks[i];
      // read and remove
      var existing = rowByPageIndex.remove(i);
      late int partId;
      var partEntry = {indexKey: i, fileKey: fileId, contentKey: chunk};
      if (existing != null) {
        partId = existing.primaryKey as int;
        await partStore.put(partEntry, partId);
      } else {
        partId = (await partStore.add(partEntry)) as int;
      }
    }

    /// Safety delete remaining if any, but this should be empty
    for (var existing in rowByPageIndex.values) {
      await partStore.delete(existing.primaryKey as int);
    }

    // update size
    var newTreeEntity =
        treeEntity.clone(pageSize: pageSize, size: bytes.length);

    var treeStore = txn.objectStore(treeStoreName);
    await treeStore.put(newTreeEntity.toMap(), treeEntity.id);
    return newTreeEntity;
  }

  /// For the given [parent] find the child named [name]
  Future<Node?> txnGetChildNode(idb.ObjectStore treeStore, idb.Index index,
      Node? parent, String name, bool followLastLink) {
    final parentName = getParentName(parent, name);

    FutureOr<Node?> nodeFromKey(dynamic id) {
      if (id == null) {
        return null;
      }

      FutureOr<Node?> nodeFromMap(dynamic map) {
        final entity = Node.fromMap(
            parent, (map as Map).cast<String, Object?>(), id as int);
        if (followLastLink && entity.isLink) {
          return txnResolveLinkNode(treeStore, entity);
        }
        return entity;
      }

      return index.get(parentName).then(nodeFromMap);
    }

    return index.getKey(parentName).then(nodeFromKey);
  }

  Future<Node?> getChildNode(Node? parent, String name, bool followLink) async {
    await ready;
    final txn = db!.transaction(treeStoreName, idb.idbModeReadWrite);
    final store = txn.objectStore(treeStoreName);
    final index = store.index(parentNameIndexName);

    final entity =
        await txnGetChildNode(store, index, parent, name, followLink);

    await txn.completed;
    return entity;
  }

  Future<Node?> txnResolveLinkNode(idb.ObjectStore treeStore, Node link) {
    // convert to absolute
    final targetSegments = getAbsoluteSegments(link, link.targetSegments!);
    return txnGetNode(treeStore, targetSegments, true);
  }

  // Return a matching result
  Future<Node?> txnGetNode(
      idb.ObjectStore store, List<String> segments, bool followLastLink) {
    //idb.idbDevPrint('#XX');
    Future<Node?> nodeFromSegments(List<String> segments) {
      return txnSearch(store, segments, followLastLink)
          .then((NodeSearchResult result) {
        final entity = result.match;
        //print('##${entity}');
        if (entity == null) {
          return null;
        }
        /*
        if (followLastLink && entity.type == fs.FileSystemEntityType.LINK) {
          //TODO handle self link
          //return __get(entity.targetSegments);
          return txnGetNode(store, entity.targetSegments,true)
        }
        */

        return entity;
      });
    }

    return nodeFromSegments(segments);
  }

  Future<Node?> getNode(List<String> segments, bool followLastLink) async {
    await ready;
    final txn = db!.transaction(treeStoreName, idb.idbModeReadWrite);
    final store = txn.objectStore(treeStoreName);

    final entity = await txnGetNode(store, segments, followLastLink);
    //print('##-${entity}');
    await txn.completed;
    return entity;
  }

  /// Search in the tree
  /// follow link only for last one
  Future<NodeSearchResult> txnSearch(
      idb.ObjectStore store, List<String> segments, bool followLastLink) {
    final result = NodeSearchResult()..segments = segments;
    final index = store.index(parentNameIndexName);
    Node? parent;

    var i = 0;

    bool isLastSegment() {
      return (i == segments.length - 1);
    }

    Future next() {
      final segment = segments[i];

      // try to lookup without following links for last segment
      if (isLastSegment()) {
        return txnGetChildNode(store, index, parent, segment, followLastLink)
            .then((Node? nodeEntity) {
          if (nodeEntity != null) {
            var entity = nodeEntity;

            result.segments = entity.segments;
            if (entity.isLink) {
              result.targetSegments = entity.targetSegments;
            }

            // make it the result
            result.highest = entity;
          }
        });
      }
      return txnGetChildNode(store, index, parent, segment, true)
          .then((Node? nodeEntity) {
        if (nodeEntity != null) {
          var entity = nodeEntity;
          // Change segments if changing parent
          if (entity.parent != parent) {
            //print('### ${segment}');
          }
          //segments = entity.segments;
          result.highest = entity;
          // last ?
          if (i++ < segments.length - 1) {
            parent = entity;
            return next();
          }
        }
      });
    }

    return next().then((_) {
      return result;
    });
    /*
    for (String segment in segments) {
      entity = await _getWithParent(index, parent, segment);
      if (entity == null) {
        break;
      }
      result.highest = entity;
      parent = entity;
    }
    */
    //return result;
  }

  // follow link only for last one
  Future<NodeSearchResult> searchNode(
      List<String> segments, bool followLastLink) async {
    await ready;
    final txn = db!.transaction(treeStoreName, idb.idbModeReadWrite);
    final store = txn.objectStore(treeStoreName);

    final result = await txnSearch(store, segments, followLastLink);
    await txn.completed;
    return result;
  }

  Future<Node> txnAddNode(idb.ObjectStore store, Node entity) {
    // devPrint('adding ${entity}');
    return store.add(entity.toMap()).then((dynamic id) {
      entity.id = id as int;
      return entity;
    });
  }

  Future<Node> addNode(Node entity) async {
    await ready;
    final txn = db!.transaction(treeStoreName, idb.idbModeReadWrite);
    final store = txn.objectStore(treeStoreName);

    await txnAddNode(store, entity);

    await txn.completed;
    return entity;
  }

  /// Delete the associated storage.
  Future<void> delete() async {
    await idbFactory.deleteDatabase(dbPath);
  }
}

String? typeToString(fs.FileSystemEntityType type) {
  switch (type) {
    case fs.FileSystemEntityType.file:
      return _typeFile;
    case fs.FileSystemEntityType.directory:
      return _typeDirectory;
    case fs.FileSystemEntityType.link:
      return _typeLink;
    case fs.FileSystemEntityType.notFound:
      // null
      break;
  }
  return null;
}

fs.FileSystemEntityType typeFromString(String? typeString) {
  switch (typeString) {
    case _typeFile:
      return fs.FileSystemEntityType.file;
    case _typeDirectory:
      return fs.FileSystemEntityType.directory;
    case _typeLink:
      return fs.FileSystemEntityType.link;
  }
  return fs.FileSystemEntityType.notFound;
}

fs.FileSystemEntityType typeFromStringCompat(String? typeString) {
  switch (typeString) {
    case _typeCompatFile:
      return fs.FileSystemEntityType.file;
    case _typeCompatDirectory:
      return fs.FileSystemEntityType.directory;
    case _typeCompatLink:
      return fs.FileSystemEntityType.link;
  }
  return fs.FileSystemEntityType.notFound;
}

const _typeCompatDirectory = 'DIRECTORY';
const _typeCompatFile = 'FILE';
const _typeCompatLink = 'LINK';

const _typeDirectory = 'dir';
const _typeFile = 'file';
const _typeLink = 'link';

/// Tree entity
class Node {
  int? id;
  Node? parent;
  int? _depth;
  String name;
  fs.FileSystemEntityType type;

  bool get isLink => type == fs.FileSystemEntityType.link;

  bool get isDir => type == fs.FileSystemEntityType.directory;

  bool get isFile => type == fs.FileSystemEntityType.file;
  int? size;
  DateTime? modified;
  int? pageSize; // Page size if any
  List<String>? targetSegments; // for Links only

  Node.file(Node parent, String name, {DateTime? modified, int? pageSize})
      : this.node(fs.FileSystemEntityType.file, parent, name,
            modified: modified, pageSize: pageSize);

  Node.directory(Node? parent, String name, {DateTime? modified})
      : this(
          parent,
          name,
          fs.FileSystemEntityType.directory,
          modified,
          0,
        );

  Node.link(Node? parent, String name,
      {List<String>? targetSegments, DateTime? modified})
      : this.node(fs.FileSystemEntityType.link, parent, name,
            modified: modified, targetSegments: targetSegments);

  Node.node(this.type, this.parent, this.name,
      {this.targetSegments, this.id, this.modified, this.size, this.pageSize});

  Node(this.parent, this.name, this.type, this.modified, this.size,
      {this.id, this.pageSize}) {
    _depth = parent == null ? 1 : parent!._depth! + 1;
  }

  factory Node.fromMap(Node? parent, Map<String, Object?> map, int id) {
    final parentId = map[parentKey] as int?;
    // For root: map: {name: /, type: DIRECTORY, modified: 2021-02-21T14:42:55.508406, size: 0, pn: /}
    // devPrint('$parentId ${parent?.id} fromMap: $map');
    if (parentId != null || parent != null) {
      assert(parent?.id == parentId, '$parentId != ${parent?.id}');
    }
    final name = map[nameKey] as String;
    final modifiedString = map[modifiedKey] as String?;
    DateTime? modified;
    if (modifiedString != null) {
      modified = DateTime.parse(modifiedString);
    }
    final size = map[sizeKey] as int?;
    final pageSize = (map[pageSizeKey] as int?) ?? 0;

    fs.FileSystemEntityType? type;
    var typeRawString = map[typeKey] as String?;

    // New format 'dir', 'file', 'link'
    type = typeFromString(typeRawString);
    if (type == fs.FileSystemEntityType.notFound) {
      type = typeFromStringCompat(typeRawString);
    }

    return Node(parent, name, type, modified, size, id: id, pageSize: pageSize)
      ..targetSegments = (map[targetKey] as List?)?.cast<String>();
  }

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      nameKey: name,
      typeKey: typeToString(type),
      // omit the page size if 0
      if ((pageSize ?? 0) != 0) pageSizeKey: pageSize
    };
    if (parent != null) {
      map[parentKey] = parent!.id;
    }
    if (modified != null) {
      map[modifiedKey] = modified!.toUtc().toIso8601String();
    }
    if (size != null) {
      map[sizeKey] = size;
    }
    if (targetSegments != null) {
      map[targetKey] = targetSegments;
    }
    map[parentNameKey] = parentName;
    return map;
  }

  // Slow!
  String get path => idbPathContext.joinAll(segments);

  List<String> get segments {
    final segments = <String>[];
    var entity = this;
    do {
      segments.insert(0, entity.name);
      var parent = entity.parent;
      if (parent == null) {
        break;
      }
      entity = entity.parent!;
    } while (true);
    return segments;
  }

  String get parentName => getParentName(parent, name);

  @override
  String toString() => toMap().toString();

  @override
  bool operator ==(Object other) {
    return other is Node && other.id == id;
  }

  @override
  int get hashCode => id!;

  Node clone({int? pageSize, int? size}) => Node.node(type, parent, name,
      pageSize: pageSize ?? this.pageSize,
      id: id,
      modified: modified,
      size: size ?? this.size,
      targetSegments: targetSegments);
}

class NodeSearchResult {
  List<String>? segments;
  Node? highest;
  List<String>? targetSegments; // if the result is a link
  int? get depth => highest != null ? highest!._depth : 0;

  int get depthDiff => segments!.length - depth!;

  // To force match
  bool? _matches;

  bool? get matches {
    if (_matches != null) {
      return _matches;
    }
    return highest != null && depthDiff == 0;
  }

  Node? get match => matches! ? highest : null;

  Iterable<String?> get remainingSegments =>
      segments!.getRange(depth!, segments!.length);

  String get path => idbPathContext.joinAll(segments as Iterable<String>);

  NodeSearchResult get parent {
    assert(!matches!);
    return NodeSearchResult()
      ..segments = getParentSegments(segments!)
      ..highest = highest;
  }

  @override
  String toString() => '$depthDiff $highest';
}

List<String> getSegments(String path) {
  final segments = idbPathContext.split(path);
  if (!idbPathContext.isAbsolute(path)) {
    segments.insert(0, idbPathContext.separator);
  }
  return segments;
}

List<String>? getParentSegments(List<String> segments) {
  if (segments.isEmpty) {
    return null;
  }
  return segments.sublist(0, segments.length - 1);
}

String getParentName(Node? parent, String? name) {
  if (parent == null) {
    return idbPathContext.join(idbPathContext.separator, name);
  } else {
    return idbPathContext.join(parent.id.toString(), name);
  }
}
