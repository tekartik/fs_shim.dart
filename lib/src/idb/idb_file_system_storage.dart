library fs_shim.src.idb.idb_file_system_storage;

import 'idb_fs.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'dart:async';
import '../../fs.dart' as fs;
import 'package:path/path.dart';

const String treeStoreName = "tree";
const String fileStoreName = "file";
const String nameKey = "name";
const String parentNameKey = "pn"; // indexed
const String parentNameIndexName = parentNameKey;

const String parentKey = "parent"; // indexed
const String parentIndexName = parentKey;
const String typeKey = "type";
const String modifiedKey = "modified";
const String sizeKey = "size";
const String targetKey = "target"; // Link only

bool segmentsAreAbsolute(Iterable<String> segments) {
  return segments.isNotEmpty && segments.first.startsWith(separator);
}

bool segmentsAreRelative(Iterable<String> segments) =>
    !segmentsAreAbsolute(segments);

Iterable<String> getAbsoluteSegments(Node origin, List<String> target) {
  if (segmentsAreAbsolute(target)) {
    return target;
  }
  List<String> targetSegments =
      new List.from(getParentSegments(origin.segments));
  targetSegments.addAll(target);
  return targetSegments;
}

// not exported
class IdbFileSystemStorage {
  idb.IdbFactory idbFactory;
  String dbPath;
  IdbFileSystemStorage(this.idbFactory, this.dbPath);

  idb.Database db;
  Completer _readyCompleter;

  Future get ready async {
    if (_readyCompleter == null) {
      _readyCompleter = new Completer();

      // version 4: add file store
      db = await idbFactory.open(dbPath, version: 6,
          onUpgradeNeeded: (idb.VersionChangeEvent e) {
        idb.Database db = e.database;
        idb.ObjectStore store;

        if (e.oldVersion < 6) {
          // delete previous if any
          Iterable<String> storeNames = db.objectStoreNames;
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
      _readyCompleter.complete();
    }
    return _readyCompleter.future;
  }

  Future<Node> txnGetChildNode(idb.ObjectStore treeStore, idb.Index index,
      Node parent, String name, bool followLastLink) {
    String parentName = getParentName(parent, name);

    _nodeFromKey(int id) {
      if (id == null) {
        return null;
      }

      _nodeFromMap(Map map) {
        Node entity = new Node.fromMap(parent, map, id);
        if (followLastLink && entity.isLink) {
          return txnResolveLinkNode(treeStore, entity);
        }
        return entity;
      }

      return index.get(parentName).then(_nodeFromMap);
    }

    return index.getKey(parentName).then(_nodeFromKey) as Future<Node>;
  }

  Future<Node> getChildNode(Node parent, String name, bool followLink) async {
    await ready;
    idb.Transaction txn = db.transaction(treeStoreName, idb.idbModeReadWrite);
    idb.ObjectStore store = txn.objectStore(treeStoreName);
    idb.Index index = store.index(parentNameIndexName);

    Node entity = await txnGetChildNode(store, index, parent, name, followLink);

    await txn.completed;
    return entity;
  }

  Future<Node> txnResolveLinkNode(idb.ObjectStore treeStore, Node link) {
    // convert to absolute
    List<String> targetSegments =
        getAbsoluteSegments(link, link.targetSegments);
    return txnGetNode(treeStore, targetSegments, true);
  }

  // Return a matching result
  Future<Node> txnGetNode(
      idb.ObjectStore store, List<String> segments, bool followLastLink) {
    Future<Node> __get(List<String> segments) {
      return txnSearch(store, segments, followLastLink)
          .then((NodeSearchResult result) {
        Node entity = result.match;
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

  Future<Node> getNode(List<String> segments, bool followLastLink) async {
    await ready;
    idb.Transaction txn = db.transaction(treeStoreName, idb.idbModeReadWrite);
    idb.ObjectStore store = txn.objectStore(treeStoreName);

    Node entity = await txnGetNode(store, segments, followLastLink);
    //print('##-${entity}');
    await txn.completed;
    return entity;
  }

  // follow link only for last one
  Future<NodeSearchResult> txnSearch(
      idb.ObjectStore store, List<String> segments, followLastLink) {
    NodeSearchResult result = new NodeSearchResult()..segments = segments;
    idb.Index index = store.index(parentNameIndexName);
    Node parent;
    Node entity;

    int i = 0;

    bool isLastSegment() {
      return (i == segments.length - 1);
    }

    _next() {
      String segment = segments[i];

      // try to lookup without following links for last segment
      if (isLastSegment()) {
        return txnGetChildNode(store, index, parent, segment, followLastLink)
            .then((Node entity_) {
          entity = entity_;
          if (entity != null) {
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
          .then((Node entity_) {
        entity = entity_;
        if (entity != null) {
          // Change segments if changing parent
          if (entity.parent != parent) {
            print('### ${segment}');
          }
          //segments = entity.segments;
          result.highest = entity;
          // last ?
          if (i++ < segments.length - 1) {
            parent = entity;
            return _next();
          }
        } else {}
      });
    }
    return _next().then((_) {
      return result;
    }) as Future<NodeSearchResult>;
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
    idb.Transaction txn = db.transaction(treeStoreName, idb.idbModeReadWrite);
    idb.ObjectStore store = txn.objectStore(treeStoreName);

    NodeSearchResult result = await txnSearch(store, segments, followLastLink);
    await txn.completed;
    return result;
  }

  Future<Node> txnAddNode(idb.ObjectStore store, Node entity) {
    //print('adding ${entity}');
    return store.add(entity.toMap()).then((int id) {
      entity.id = id;
      return entity;
    });
  }

  Future<Node> addNode(Node entity) async {
    await ready;
    idb.Transaction txn = db.transaction(treeStoreName, idb.idbModeReadWrite);
    idb.ObjectStore store = txn.objectStore(treeStoreName);

    await txnAddNode(store, entity);

    await txn.completed;
    return entity;
  }
}

List<fs.FileSystemEntityType> _allTypes = [
  fs.FileSystemEntityType.FILE,
  fs.FileSystemEntityType.DIRECTORY,
  fs.FileSystemEntityType.LINK
];
fs.FileSystemEntityType typeFromString(String typeString) {
  for (fs.FileSystemEntityType type in _allTypes) {
    if (type.toString() == typeString) {
      return type;
    }
  }
  return fs.FileSystemEntityType.NOT_FOUND;
}

class Node {
  int id;
  Node parent;
  int _depth;
  String name;
  fs.FileSystemEntityType type;
  bool get isLink => type == fs.FileSystemEntityType.LINK;
  bool get isDir => type == fs.FileSystemEntityType.DIRECTORY;
  bool get isFile => type == fs.FileSystemEntityType.FILE;
  int size;
  DateTime modified;
  List<String> targetSegments; // for Links only

  Node.file(Node parent, String name, {DateTime modified})
      : this.node(fs.FileSystemEntityType.FILE, parent, name,
            modified: modified);

  Node.directory(Node parent, String name, {DateTime modified})
      : this(parent, name, fs.FileSystemEntityType.DIRECTORY, modified, 0);

  Node.link(Node parent, String name,
      {List<String> targetSegments, DateTime modified})
      : this.node(fs.FileSystemEntityType.LINK, parent, name,
            modified: modified, targetSegments: targetSegments);

  Node.node(this.type, this.parent, this.name,
      {this.targetSegments, this.id, this.modified, this.size});
  Node(this.parent, this.name, this.type, this.modified, this.size, [this.id]) {
    _depth = parent == null ? 1 : parent._depth + 1;
  }

  factory Node.fromMap(Node parent, Map map, int id) {
    int parentId = map[parentKey];
    if (parentId != null || parent != null) {
      assert(parent.id == parentId);
    }
    String name = map[nameKey];
    String modifiedString = map[modifiedKey];
    DateTime modified;
    if (modifiedString != null) {
      modified = DateTime.parse(modifiedString);
    }
    int size = map[sizeKey];
    fs.FileSystemEntityType type = typeFromString(map[typeKey]);

    return new Node(parent, name, type, modified, size, id)
      ..targetSegments = (map[targetKey] as List<String>);
  }

  Map toMap() {
    Map map = {nameKey: name, typeKey: type.toString()};
    if (parent != null) {
      map[parentKey] = parent.id;
    }
    if (modified != null) {
      map[modifiedKey] = modified.toIso8601String();
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
    List<String> segments = [];
    Node entity = this;
    do {
      segments.insert(0, entity.name);
      entity = entity.parent;
    } while (entity != null);
    return segments;
  }

  String get parentName => getParentName(parent, name);

  @override
  String toString() => toMap().toString();

  bool operator ==(o) {
    return o.id == id;
  }
}

class NodeSearchResult {
  List<String> segments;
  Node highest;
  List<String> targetSegments; // if the result is a link
  int get depth => highest != null ? highest._depth : 0;
  int get depthDiff => segments.length - depth;
  // To force match
  bool _matches;
  bool get matches {
    if (_matches != null) {
      return _matches;
    }
    return highest != null && depthDiff == 0;
  }

  Node get match => matches ? highest : null;

  Iterable<String> get remainingSegments =>
      segments.getRange(depth, segments.length);

  String get path => joinAll(segments);

  NodeSearchResult get parent {
    assert(!matches);
    return new NodeSearchResult()
      ..segments = getParentSegments(segments)
      ..highest = highest;
  }

  String toString() => '$depthDiff $highest';
}

List<String> getSegments(String path) {
  List<String> segments = split(path);
  if (!isAbsolute(path)) {
    segments.insert(0, separator);
  }
  return segments;
}

List<String> getParentSegments(List<String> segments) {
  if (segments.isEmpty) {
    return null;
  }
  return segments.sublist(0, segments.length - 1);
}

String getParentName(Node parent, String name) {
  if (parent == null) {
    return join(separator, name);
  } else {
    return join(parent.id.toString(), name);
  }
}
