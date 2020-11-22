import 'dart:async';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/src/common/import.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'package:path/path.dart';

import 'idb_fs.dart';

const String treeStoreName = 'tree';
const String fileStoreName = 'file';
const String nameKey = 'name';
const String parentNameKey = 'pn'; // indexed - this is actually the full name
const String parentNameIndexName = parentNameKey;

const String parentKey = 'parent'; // indexed
const String parentIndexName = parentKey;
const String typeKey = 'type';
const String modifiedKey = 'modified';
const String sizeKey = 'size';
const String targetKey = 'target'; // Link only

bool segmentsAreAbsolute(Iterable<String> segments) {
  return segments.isNotEmpty && segments.first.startsWith(separator);
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

// not exported
class IdbFileSystemStorage {
  idb.IdbFactory idbFactory;
  String dbPath;

  IdbFileSystemStorage(this.idbFactory, this.dbPath);

  idb.Database? db;
  Completer? _readyCompleter;

  Future get ready async {
    if (_readyCompleter == null) {
      _readyCompleter = Completer();

      // version 4: add file store
      db = await idbFactory.open(dbPath, version: 6,
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

          store = db.createObjectStore(treeStoreName, autoIncrement: true);
          store.createIndex(parentNameIndexName, parentNameKey,
              unique: true); // <id_parent>/<name>
          store.createIndex(parentIndexName, parentKey);

          store = db.createObjectStore(fileStoreName);
        }
      }, onBlocked: (e) {
        print(e);
        print('#### db format change - reload');
      });
      _readyCompleter!.complete();
    }
    return _readyCompleter!.future;
  }

  Future<Node?> txnGetChildNode(idb.ObjectStore treeStore, idb.Index index,
      Node? parent, String name, bool followLastLink) {
    final parentName = getParentName(parent, name);

    FutureOr<Node?> _nodeFromKey(dynamic id) {
      if (id == null) {
        return null;
      }

      FutureOr<Node?> _nodeFromMap(dynamic map) {
        final entity = Node.fromMap(
            parent, (map as Map).cast<String, Object?>(), id as int);
        if (followLastLink && entity.isLink) {
          return txnResolveLinkNode(treeStore, entity);
        }
        return entity;
      }

      return index.get(parentName).then(_nodeFromMap);
    }

    return index.getKey(parentName).then(_nodeFromKey);
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
    Future<Node?> __get(List<String> segments) {
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

    return __get(segments);
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

  // follow link only for last one
  Future<NodeSearchResult> txnSearch(
      idb.ObjectStore store, List<String> segments, bool followLastLink) {
    final result = NodeSearchResult()..segments = segments;
    final index = store.index(parentNameIndexName);
    Node? parent;

    var i = 0;

    bool isLastSegment() {
      return (i == segments.length - 1);
    }

    Future _next() {
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
            return _next();
          }
        }
      });
    }

    return _next().then((_) {
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
    //print('adding ${entity}');
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
}

List<fs.FileSystemEntityType> _allTypes = [
  fs.FileSystemEntityType.file,
  fs.FileSystemEntityType.directory,
  fs.FileSystemEntityType.link
];

fs.FileSystemEntityType typeFromString(String? typeString) {
  for (final type in _allTypes) {
    if (type.toString() == typeString) {
      return type;
    }
  }
  return fs.FileSystemEntityType.notFound;
}

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
  List<String>? targetSegments; // for Links only

  Node.file(Node parent, String name, {DateTime? modified})
      : this.node(fs.FileSystemEntityType.file, parent, name,
            modified: modified);

  Node.directory(Node? parent, String name, {DateTime? modified})
      : this(parent, name, fs.FileSystemEntityType.directory, modified, 0);

  Node.link(Node? parent, String name,
      {List<String>? targetSegments, DateTime? modified})
      : this.node(fs.FileSystemEntityType.link, parent, name,
            modified: modified, targetSegments: targetSegments);

  Node.node(this.type, this.parent, this.name,
      {this.targetSegments, this.id, this.modified, this.size});

  Node(this.parent, this.name, this.type, this.modified, this.size, [this.id]) {
    _depth = parent == null ? 1 : parent!._depth! + 1;
  }

  factory Node.fromMap(Node? parent, Map<String, Object?> map, int id) {
    final parentId = map[parentKey] as int?;
    if (parentId != null || parent != null) {
      assert(parent!.id == parentId);
    }
    final name = map[nameKey] as String;
    final modifiedString = map[modifiedKey] as String?;
    DateTime? modified;
    if (modifiedString != null) {
      modified = DateTime.parse(modifiedString);
    }
    final size = map[sizeKey] as int?;
    final type = typeFromString(map[typeKey] as String?);

    return Node(parent, name, type, modified, size, id)
      ..targetSegments = (map[targetKey] as List?)?.cast<String>();
  }

  Map<String, Object?> toMap() {
    final map = <String, Object?>{nameKey: name, typeKey: type.toString()};
    if (parent != null) {
      map[parentKey] = parent!.id;
    }
    if (modified != null) {
      map[modifiedKey] = modified!.toIso8601String();
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
  String get path => joinAll(segments);

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
  bool operator ==(o) {
    return o is Node && o.id == id;
  }

  @override
  int get hashCode => id!;
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

  String get path => joinAll(segments as Iterable<String>);

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
    return idbPathContext.join(idbPathContext.separator, separator, name);
  } else {
    return idbPathContext.join(parent.id.toString(), name);
  }
}
