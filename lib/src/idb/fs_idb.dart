library tekartik_fs_shim.src.lfs_idb;

import '../../fs.dart' as fs;
import 'package:idb_shim/idb_client.dart' as idb;
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:tekartik_fs_shim/src/common/fs_mixin.dart';
import 'package:tekartik_fs_shim/src/common/memory_sink.dart';
import 'package:path/path.dart' as path_pkg;

IdbError get _noSuchPathError => new IdbError(2, "No such file or directory");
IdbError get _notEmptyError => new IdbError(39, "Directory not empty");
IdbError get _alreadyExistsError => new IdbError(17, "File exists");
IdbError get _notADirectoryError => new IdbError(20, "Not a directory");
IdbError get _isADirectoryError => new IdbError(21, "Is a directory");

class IdbError implements fs.OSError {
  IdbError(this.errorCode, this.message);
  final int errorCode;
  final String message;

  @override
  String toString() {
    return "(OS Error: ${message}, errno = ${errorCode})";
  }
}

_notADirectoryException(String path, String msg) => new IdbFileSystemException(
    fs.FileSystemException.statusNotADirectory, path, msg, _notADirectoryError);

_isADirectoryException(String path, String msg) => new IdbFileSystemException(
    fs.FileSystemException.statusIsADirectory, path, msg, _isADirectoryError);

_notEmptyException(String path, String msg) => new IdbFileSystemException(
    fs.FileSystemException.statusNotEmpty, path, msg, _notEmptyError);

_notFoundException(String path, String msg) => new IdbFileSystemException(
    fs.FileSystemException.statusNotFound, path, msg, _noSuchPathError);

_alreadyExistsException(String path, String msg) => new IdbFileSystemException(
    fs.FileSystemException.statusAlreadyExists, path, msg, _alreadyExistsError);

class IdbFileSystemException implements fs.FileSystemException {
  IdbFileSystemException(this.status, this.path, [this._message, this.osError]);

  @override
  final int status;

  String _message;
  @override
  final IdbError osError;

  @override
  String get message =>
      _message == null ? (osError == null ? null : osError.message) : _message;

  @override
  final String path;

  @override
  String toString() {
    return "${status == null ? '' : '[${status}] '}FileSystemException: ${message}, path = '${path}' ${osError}";
  }
}

abstract class IdbFileSystemEntity implements fs.FileSystemEntity {
  IdbFileSystem _fs;

  @override
  final String path;

  // subclass type
  fs.FileSystemEntityType get _type;

  IdbFileSystemEntity(this._fs, this.path) {
    if (path == null) {
      throw new ArgumentError.notNull("path");
    }
  }

  Future<IdbFileSystemEntity> delete({bool recursive: false}) {
    return _fs.delete(_type, path, recursive: recursive).then((_) => this);
  }

  @override
  Future<bool> exists() {
    return _fs.exists(path);
  }

  @override
  Future<fs.FileStat> stat() {
    return _fs.stat(path);
  }

  @override
  bool get isAbsolute => path_pkg.isAbsolute(path);

  // don't care about recursive
  //@override
  //Future<fs.FileSystemEntity> delete({bool recursive: false}) async {
//    _fs._impl.delete(path, recursive: recursive);
//    return this;
//  }

  @override
  String toString() => path;
}

class IdbDirectory extends IdbFileSystemEntity implements fs.Directory {
  IdbDirectory(IdbFileSystem fs, String path) : super(fs, path);

  @override
  Future<IdbDirectory> create({bool recursive: false}) {
    return _fs.createDirectory(path, recursive: recursive).then((_) => this);
  }

  @override
  fs.FileSystemEntityType get _type => fs.FileSystemEntityType.DIRECTORY;

  @override
  Future<IdbDirectory> rename(String newPath) {
    return _fs
        .rename(_type, path, newPath)
        .then((_) => new IdbDirectory(_fs, newPath));
  }

  @override
  Stream<IdbFileSystemEntity> list(
          {bool recursive: false, bool followLinks: true}) =>
      _fs.list(path, recursive: recursive, followLinks: followLinks);

  @override
  IdbDirectory get absolute => new IdbDirectory(_fs, _makePathAbsolute(path));
}

class IdbFile extends IdbFileSystemEntity with FileMixin implements fs.File {
  IdbFile(IdbFileSystem fs, String path) : super(fs, path);

  Future<IdbFile> create({bool recursive: false}) {
    return _fs.createFile(path, recursive: recursive).then((_) => this);
  }

  fs.FileSystemEntityType get _type => fs.FileSystemEntityType.FILE;

  // don't care about encoding - assume UTF8
  @override
  StreamSink<List<int>> openWrite(
          {fs.FileMode mode: fs.FileMode.WRITE, Encoding encoding: UTF8}) //
      =>
      _fs.openWrite(path, mode: mode);

  @override
  Stream<List<int>> openRead([int start, int end]) =>
      _fs.openRead(path, start, end);

  @override
  Future<IdbDirectory> rename(String newPath) {
    return _fs
        .rename(_type, path, newPath)
        .then((_) => new IdbFile(_fs, newPath));
  }

  @override
  Future<IdbFile> copy(String newPath) {
    return _fs.copyFile(path, newPath).then((_) => new IdbFile(_fs, newPath));
  }

  @override
  Future<IdbFile> writeAsBytes(List<int> bytes,
          {fs.FileMode mode: fs.FileMode.WRITE, bool flush: false}) =>
      doWriteAsBytes(bytes, mode: mode, flush: flush);

  @override
  Future<IdbFile> writeAsString(String contents,
          {fs.FileMode mode: fs.FileMode.WRITE,
          Encoding encoding: UTF8,
          bool flush: false}) =>
      doWriteAsString(contents, mode: mode, encoding: encoding, flush: flush);

  @override
  IdbFile get absolute => new IdbFile(_fs, _makePathAbsolute(path));
}

const String _treeStore = "tree";
const String _fileStore = "file";
const String _name = "name";
const String _parentName = "pn"; // indexed
const String _parentNameIndex = _parentName;

const String _parent = "parent"; // indexed
const String _parentIndex = _parent;
const String _type = "type";
const String _modified = "modified";
const String _size = "size";

class TreeEntity {
  int id;
  TreeEntity parent;
  int _depth;
  String name;
  fs.FileSystemEntityType type;
  int size;
  DateTime modified;

  TreeEntity(this.parent, this.name, this.type, this.modified, this.size,
      [this.id]) {
    _depth = parent == null ? 1 : parent._depth + 1;
  }

  factory TreeEntity.fromMap(TreeEntity parent, Map map, int id) {
    int parentId = map[_parent];
    if (parentId != null || parent != null) {
      assert(parent.id == parentId);
    }
    String name = map[_name];
    String modifiedString = map[_modified];
    DateTime modified;
    if (modifiedString != null) {
      modified = DateTime.parse(modifiedString);
    }
    int size = map[_size];
    fs.FileSystemEntityType type = _typeFromString(map[_type]);

    return new TreeEntity(parent, name, type, modified, size, id);
  }

  Map toMap() {
    Map map = {_name: name, _type: type.toString()};
    if (parent != null) {
      map[_parent] = parent.id;
    }
    if (modified != null) {
      map[_modified] = modified.toIso8601String();
    }
    if (size != null) {
      map[_size] = size;
    }
    map[_parentName] = parentName;
    return map;
  }

  // Slow!
  String get path => joinAll(segments);

  List<String> get segments {
    List<String> segments = [];
    TreeEntity entity = this;
    do {
      segments.insert(0, entity.name);
      entity = entity.parent;
    } while (entity != null);
    return segments;
  }

  String get parentName => _getParentName(parent, name);

  @override
  String toString() => toMap().toString();
}

List<String> _getPathSegments(String path) {
  path = _makePathAbsolute(path);
  return split(path);
}

List<fs.FileSystemEntityType> _allTypes = [
  fs.FileSystemEntityType.FILE,
  fs.FileSystemEntityType.DIRECTORY,
  fs.FileSystemEntityType.LINK
];
fs.FileSystemEntityType _typeFromString(String typeString) {
  for (fs.FileSystemEntityType type in _allTypes) {
    if (type.toString() == typeString) {
      return type;
    }
  }
  return fs.FileSystemEntityType.NOT_FOUND;
}

class _GetTreeSearchResult {
  List<String> segments;
  TreeEntity highest;
  int get depth => highest != null ? highest._depth : 0;
  int get depthDiff => segments.length - depth;
  bool get matches => highest != null && depthDiff == 0;

  TreeEntity get match => matches ? highest : null;

  Iterable<String> get remainingSegments =>
      segments.getRange(depth, segments.length);

  String get path => joinAll(segments);

  _GetTreeSearchResult get parent {
    assert(!matches);
    return new _GetTreeSearchResult()
      ..segments = segments.sublist(0, segments.length - 1)
      ..highest = highest;
  }
}

class IdbFileStat implements fs.FileStat {
  int _size;
  int get size => _size == null ? -1 : _size;
  fs.FileSystemEntityType type;
  DateTime modified;

  String toString() {
    Map map = {"type": type};
    if (modified != null) {
      map["modified"] = modified;
    }
    if (_size != null) {
      map["size"] = size;
    }
    return map.toString();
  }
}

class IdbFileSystem extends Object
    with FileSystemMixin
    implements fs.FileSystem {
  String get name => 'idb';
  final idb.IdbFactory _factory;
  final String _dbPath;
  idb.Database _db;
  idb.Database get db => _db;
  static const dbPath = 'lfs.db';
  IdbFileSystem(this._factory, [String path])
      : _dbPath = path == null ? dbPath : path {}

  @override
  Future<fs.FileSystemEntityType> type(String path,
      {bool followLinks: true}) async {
    await _ready;

    List<String> segments = _getPathSegments(path);

    idb.Transaction txn = _db.transaction(_treeStore, idb.idbModeReadWrite);
    try {
      idb.ObjectStore store = txn.objectStore(_treeStore);
      TreeEntity entity = (await _get(store, segments)).match;
      if (entity == null) {
        return fs.FileSystemEntityType.NOT_FOUND;
      }
      return entity.type;
    } finally {
      await txn.completed;
    }
  }

  @override
  IdbDirectory newDirectory(String path) {
    return new IdbDirectory(this, path);
  }

  @override
  IdbFile newFile(String path) {
    return new IdbFile(this, path);
  }

  Completer _readyCompleter;
  Future get _ready async {
    if (_readyCompleter == null) {
      _readyCompleter = new Completer();

      // version 4: add file store
      _db = await _factory.open(_dbPath, version: 6,
          onUpgradeNeeded: (idb.VersionChangeEvent e) {
        idb.Database db = e.database;
        idb.ObjectStore store;

        if (e.oldVersion < 6) {
          // delete previous if any
          Iterable<String> storeNames = db.objectStoreNames;
          if (storeNames.contains(_treeStore)) {
            db.deleteObjectStore(_treeStore);
          }
          if (storeNames.contains(_fileStore)) {
            db.deleteObjectStore(_fileStore);
          }

          store = db.createObjectStore(_treeStore, autoIncrement: true);
          store.createIndex(_parentNameIndex, _parentName,
              unique: true); // <id_parent>/<name>
          store.createIndex(_parentIndex, _parent);

          store = db.createObjectStore(_fileStore);
        }
      }, onBlocked: (e) {
        print(e);
        print('#### db format change - reload');
      });
      _readyCompleter.complete();
    }
    return _readyCompleter.future;
  }

  createDirectory(String path, {bool recursive: false}) async {
    await _ready;
    // Go up one by one
    // List<String> segments = getSegments(path);
    List<String> segments = _getPathSegments(path);

    idb.Transaction txn = _db.transaction(_treeStore, idb.idbModeReadWrite);
    idb.ObjectStore store = txn.objectStore(_treeStore);
    try {
      // Try to find the file if it exists
      _GetTreeSearchResult result = await _get(store, segments);
      TreeEntity entity = result.match;
      if (entity != null) {
        if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
          return entity;
        }
        throw _alreadyExistsException(path, "Creation failed");
      }

      // not recursive and too deep, cancel
      if ((result.depthDiff > 1) && (recursive != true)) {
        throw _notFoundException(path, "Creation failed");
      }

      // check depth
      entity = await _createDirectory(store, result);
      if (entity == null) {
        throw _notFoundException(path, "Creation failed");
      }
    } finally {
      await txn.completed;
    }
  }

  Future<TreeEntity> _createFile(idb.ObjectStore store, List<String> segments,
      {bool recursive: false}) {
    // Try to find the file if it exists
    return _get(store, segments).then((_GetTreeSearchResult result) {
      TreeEntity entity = result.match;
      if (entity != null) {
        if (entity.type == fs.FileSystemEntityType.FILE) {
          return entity;
        }
        //TODO assume dir for now
        throw _isADirectoryException(result.path, "Creation failed");
      }

      // not recursive and too deep, cancel
      if ((result.depthDiff > 1) && (recursive != true)) {
        throw _notFoundException(result.path, "Creation failed");
      }

      Future<TreeEntity> _addFile(TreeEntity parent) {
        // create it!
        entity = new TreeEntity(parent, segments.last,
            fs.FileSystemEntityType.FILE, new DateTime.now(), 0);
        //print('adding ${entity}');
        return store.add(entity.toMap()).then((int id) {
          entity.id = id;
          return entity;
        });
      }
      // check depth
      if (result.parent.remainingSegments.isNotEmpty) {
        return _createDirectory(store, result.parent).then((TreeEntity parent) {
          if (parent == null) {
            throw _notFoundException(result.path, "Creation failed");
          }
          return _addFile(parent);
        });
      } else {
        return _addFile(result.highest);
      }
    });
  }

  Future createFile(String path, {bool recursive: false}) async {
    await _ready;
    List<String> segments = getSegments(path);

    idb.Transaction txn = _db.transaction(_treeStore, idb.idbModeReadWrite);
    idb.ObjectStore store = txn.objectStore(_treeStore);
    return _createFile(store, segments, recursive: recursive).whenComplete(() {
      return txn.completed;
    });
  }

  Future delete(fs.FileSystemEntityType type, String path,
      {bool recursive: false}) async {
    await _ready;
    List<String> segments = getSegments(path);

    idb.Transaction txn =
        _db.transactionList([_treeStore, _fileStore], idb.idbModeReadWrite);

    try {
      await _delete(txn, type, segments, recursive: recursive);
    } finally {
      await txn.completed;
    }
  }

  Future _deleteEntity(idb.Transaction txn, TreeEntity entity,
      {bool recursive: false}) {
    var error;

    idb.ObjectStore store = txn.objectStore(_treeStore);

    _delete() {
      return store.delete(entity.id).then((_) {
        // For file delete content as well
        if (entity.type == fs.FileSystemEntityType.FILE) {
          store = txn.objectStore(_fileStore);
          return store.delete(entity.id);
        }
      });
    }

    if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
      // check children first
      idb.Index parentIndex = store.index(_parentIndex);
      Completer done = new Completer.sync();

      List<Future> futures = [];
      parentIndex
          .openCursor(key: entity.id, autoAdvance: false)
          .listen((idb.CursorWithValue cwv) {
        TreeEntity child =
            new TreeEntity.fromMap(entity, cwv.value, cwv.primaryKey);
        if (recursive == true) {
          futures.add(_deleteEntity(txn, child, recursive: true));
          cwv.next();
        } else {
          error = _notEmptyException(entity.path, "Deletion failed");
          done.complete();
        }
      }).asFuture().then((_) {
        if (!done.isCompleted) {
          done.complete();
        }
      });
      return done.future.then((_) {
        if (error != null) {
          throw error;
        }
        return Future.wait(futures);
      }).then((_) {
        return _delete();
      });
    } else {
      return _delete();
    }
  }

  Future _delete(
      idb.Transaction txn, fs.FileSystemEntityType type, List<String> segments,
      {bool recursive: false}) {
    idb.ObjectStore store = txn.objectStore(_treeStore);
    return _get(store, segments).then((_GetTreeSearchResult result) {
      TreeEntity entity = result.match;
      // not existing throw error
      if (entity == null) {
        throw _notFoundException(result.path, "Deletion failed");
      } else if (type != null) {
        if (type != entity.type) {
          if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
            throw _isADirectoryException(result.path, "Deletion failed");
          }
          throw _notADirectoryException(result.path, "Deletion failed");
        }
      }
      // ? has kids
      return _deleteEntity(txn, entity, recursive: recursive);
    });
  }

  Future<bool> exists(String path) async {
    await _ready;
    List<String> segments = getSegments(path);

    idb.Transaction txn = _db.transaction(_treeStore, idb.idbModeReadOnly);

    idb.ObjectStore store = txn.objectStore(_treeStore);
    return _get(store, segments).then((result) {
      return result.matches;
    }).whenComplete(() {
      return txn.completed;
    });
  }

  Future<IdbFileStat> stat(String path) async {
    await _ready;
    List<String> segments = getSegments(path);

    idb.Transaction txn = _db.transaction(_treeStore, idb.idbModeReadOnly);
    try {
      idb.ObjectStore store = txn.objectStore(_treeStore);
      TreeEntity entity = (await _get(store, segments)).match;

      IdbFileStat stat = new IdbFileStat();
      if (entity == null) {
        stat.type = fs.FileSystemEntityType.NOT_FOUND;
      } else {
        stat.type = entity.type;
        stat._size = entity.size;
        stat.modified = entity.modified;
      }
      return stat;
    } finally {
      await txn.completed;
    }
  }

  Future rename(
      fs.FileSystemEntityType type, String path, String newPath) async {
    await _ready;
    List<String> segments = getSegments(path);
    List<String> newSegments = getSegments(newPath);

    idb.Transaction txn =
        _db.transactionList([_treeStore, _fileStore], idb.idbModeReadWrite);

    idb.ObjectStore store = txn.objectStore(_treeStore);

    return _get(store, segments).then((_GetTreeSearchResult result) {
      TreeEntity entity = result.match;

      if (entity == null) {
        throw throw _notFoundException(path, "Rename failed");
      }

      return _get(store, newSegments).then((_GetTreeSearchResult newResult) {
        TreeEntity newEntity = newResult.match;

        TreeEntity newParent;

        Future _changeParent() {
          // change _parent
          entity.parent = newParent;

          entity.name = newSegments.last;
          return store.put(entity.toMap(), entity.id);
        }
        if (newEntity != null) {
          newParent = newEntity.parent;
          // Same type ok
          if (newEntity.type == entity.type) {
            if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
              // check if _notEmptyError
              idb.Index index = store.index(_parentIndex);
              // any child will matter
              return index.getKey(newEntity.id).then((int parentId) {
                if (parentId != null) {
                  throw _notEmptyException(path, "Rename failed");
                }
              }).then((_) {
                // delete existing
                return store.delete(newEntity.id).then((_) {
                  return _changeParent();
                });
              });
            } else {
              return _deleteEntity(txn, newEntity).then((_) {
                return _changeParent();
              });
            }
          } else {
            if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
              throw _notADirectoryException(path, "Rename failed");
            } else {
              throw _isADirectoryException(path, "Rename failed");
            }
          }
        } else {
          // check destination (parent folder must exists)
          if (newResult.depthDiff > 1) {
            throw _notFoundException(path, "Rename failed");
          }
          newParent = newResult.highest; // highest is the parent at depth 1
        }

        return _changeParent();
      }).whenComplete(() {
        return txn.completed;
      });
    });
  }

  Future copyFile(String path, String newPath) async {
    await _ready;
    List<String> segments = getSegments(path);
    List<String> newSegments = getSegments(newPath);

    DateTime _modified = new DateTime.now();

    idb.Transaction txn =
        _db.transactionList([_treeStore, _fileStore], idb.idbModeReadWrite);
    try {
      idb.ObjectStore store = txn.objectStore(_treeStore);

      TreeEntity entity = (await _get(store, segments)).match;
      _GetTreeSearchResult newResult = await _get(store, newSegments);
      TreeEntity newEntity = newResult.match;

      if (entity == null) {
        throw throw _notFoundException(path, "Copy failed");
      }

      if (newEntity != null) {
        // Same type ok
        if (newEntity.type != entity.type) {
          if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
            throw _notADirectoryException(path, "Copy failed");
          } else {
            throw _isADirectoryException(path, "Copy failed");
          }
        }
      } else {
        // check destination (parent folder must exists)
        if (newResult.depthDiff > 1) {
          throw _notFoundException(path, "Copy failed");
        }

        TreeEntity newParent =
            newResult.highest; // highest is the parent at depth 1
        newEntity = new TreeEntity(newParent, newSegments.last,
            fs.FileSystemEntityType.FILE, _modified, 0);
        // add file
        newEntity.id = await store.add(newEntity.toMap());
      }

      // update content
      store = txn.objectStore(_fileStore);

      // get original
      List<int> data = await store.getObject(entity.id);
      if (data != null) {
        await store.put(data, newEntity.id);

        // update size
        newEntity.size = data.length;
        store = txn.objectStore(_treeStore);
        await store.put(newEntity.toMap(), newEntity.id);
      } else {
        await store.delete(newEntity.id);
      }
    } finally {
      await txn.completed;
    }
  }

  Future<TreeEntity> _getWithParent(
      idb.Index index, TreeEntity parent, String name) {
    String parentName = _getParentName(parent, name);

    return index.getKey(parentName).then((int id) {
      if (id == null) {
        return null;
      }
      return index.get(parentName).then((Map map) {
        return new TreeEntity.fromMap(parent, map, id);
      });
    });
  }

  Future<_GetTreeSearchResult> _get(
      idb.ObjectStore store, List<String> segments) {
    _GetTreeSearchResult result = new _GetTreeSearchResult()
      ..segments = segments;
    idb.Index index = store.index(_parentNameIndex);
    TreeEntity parent;
    TreeEntity entity;

    int i = 0;
    _next() {
      String segment = segments[i];
      return _getWithParent(index, parent, segment).then((TreeEntity entity_) {
        entity = entity_;
        if (entity != null) {
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
    return result;
  }

  Future<TreeEntity> _createDirectory(
      idb.ObjectStore store, _GetTreeSearchResult result) {
    TreeEntity entity = result.highest;

    List<String> remainings = new List.from(result.remainingSegments);
    int i = 0;
    _next() {
      String segment = remainings[i];
      TreeEntity parent = entity;
      // create it!
      entity = new TreeEntity(parent, segment,
          fs.FileSystemEntityType.DIRECTORY, new DateTime.now(), 0);
      //print('adding ${entity}');
      return store.add(entity.toMap()).then((int id) {
        entity.id = id;
        if (i++ < remainings.length - 1) {
          return _next();
        }
      });
    }
    return _next().then((_) {
      return entity;
    });
  }

  StreamSink<List<int>> openWrite(String path,
      {fs.FileMode mode: fs.FileMode.WRITE}) {
    if (mode == null) {
      mode = fs.FileMode.WRITE;
    }
    if (mode == fs.FileMode.READ) {
      throw new ArgumentError("Invalid file mode '${mode}' for this operation");
    }
    path = _makePathAbsolute(path);

    IdbWriteStreamSink sink = new IdbWriteStreamSink(this, path, mode);

    return sink;
  }

  Stream<List<int>> openRead(String path, int start, int end) {
    path = _makePathAbsolute(path);
    IdbReadStreamCtlr ctlr = new IdbReadStreamCtlr(this, path, start, end);
    /*
    MemoryFileSystemEntityImpl fileImpl = getEntity(path);
    // if it exists we're fine
    if (fileImpl is MemoryFileImpl) {
      ctlr.addStream(fileImpl.openRead()).then((_) {
        ctlr.close();
      });
    } else {
      ctlr.addError(new _MemoryFileSystemException(
          path, "Cannot open file", _noSuchPathError));
    }
    */
    return ctlr.stream;
  }

  Stream<IdbFileSystemEntity> list(String path,
      {bool recursive: false, bool followLinks: true}) {
    List<String> segments = getSegments(path);

    StreamController<IdbFileSystemEntity> ctlr = new StreamController();

    _ready.then((_) {
      List<Future> recursives = [];
      idb.Transaction txn = _db.transaction(_treeStore, idb.idbModeReadOnly);
      idb.ObjectStore store = txn.objectStore(_treeStore);
      idb.Index index = store.index(_parentIndex);

      return _get(store, segments).then((result) {
        TreeEntity entity = result.match;
        if (entity == null) {
          ctlr.addError(_notFoundException(path, "List failed"));
        } else {
          Future _list(TreeEntity entity) {
            return index
                .openCursor(key: entity.id, autoAdvance: true)
                .listen((idb.CursorWithValue cwv) {
              TreeEntity childEntity =
                  new TreeEntity.fromMap(entity, cwv.value, cwv.primaryKey);
              if (childEntity.type == fs.FileSystemEntityType.DIRECTORY) {
                IdbDirectory directory =
                    new IdbDirectory(this, childEntity.path);
                ctlr.add(directory);
                if (recursive == true) {
                  recursives.add(_list(childEntity));
                }
              } else if (childEntity.type == fs.FileSystemEntityType.FILE) {
                IdbFile file = new IdbFile(this, childEntity.path);
                ctlr.add(file);
              } else {
                throw new UnsupportedError(
                    "type ${childEntity.type} not supported");
              }
            }).asFuture();
          }
          return _list(entity);
        }
      }).whenComplete(() async {
        await txn.completed;

        // wait after completed to avoid deadlock
        await Future.wait(recursives);

        ctlr.close();
      });
    });
    return ctlr.stream;
  }
}

class IdbReadStreamCtlr {
  IdbFileSystem _fs;
  String path;
  int start;
  int end;
  StreamController<List<int>> _ctlr;
  IdbReadStreamCtlr(this._fs, this.path, this.start, this.end) {
    _ctlr = new StreamController(sync: true);

    // put data
    _fs._ready.then((_) async {
      idb.Transaction txn = _fs._db
          .transactionList([_treeStore, _fileStore], idb.idbModeReadWrite);
      idb.ObjectStore store = txn.objectStore(_treeStore);

      try {
        // Try to find the file if it exists
        List<String> segments = getSegments(path);
        TreeEntity entity = (await _fs._get(store, segments)).match;
        if (entity == null) {
          _ctlr.addError(_notFoundException(path, "Read failed"));
          return;
        }
        if (entity.type != fs.FileSystemEntityType.FILE) {
          _ctlr.addError(_isADirectoryException(path, "Read failed"));
          return;
        }

        // get existing content
        store = txn.objectStore(_fileStore);
        List<int> content = await store.getObject(entity.id);
        if (content != null) {
          // All at once!
          if (start != null) {
            content = content.sublist(start, end);
          }
          _ctlr.add(content);
        }
        await _ctlr.close();
      } finally {
        await txn.completed;
      }
    });
  }

  Stream<List<int>> get stream => _ctlr.stream;
}

class IdbWriteStreamSink extends MemorySink {
  IdbFileSystem _fs;
  String path;
  fs.FileMode mode;
  IdbWriteStreamSink(this._fs, this.path, this.mode) : super();

  @override
  Future close() async {
    await super.close();

    await _fs._ready;

    idb.Transaction txn =
        _fs._db.transactionList([_treeStore, _fileStore], idb.idbModeReadWrite);
    idb.ObjectStore treeStore = txn.objectStore(_treeStore);

    try {
      // Try to find the file if it exists
      List<String> segments = getSegments(path);
      TreeEntity entity = (await _fs._get(treeStore, segments)).match;
      if (entity == null) {
        if (mode == fs.FileMode.WRITE || mode == fs.FileMode.APPEND) {
          entity = await _fs._createFile(treeStore, segments);
        }
      }
      if (entity == null) {
        throw _notFoundException(path, "Write failed");
      }
      if (entity.type != fs.FileSystemEntityType.FILE) {
        throw _isADirectoryException(path, "Write failed");
      }
      // else {      throw new UnsupportedError("TODO");      }

      // get existing content
      idb.ObjectStore fileStore = txn.objectStore(_fileStore);
      List<int> content;
      bool exists = false;
      if (mode == fs.FileMode.WRITE) {
        content == null;
      } else {
        content = await fileStore.getObject(entity.id);
        if (content != null) {
          // on idb the content is readonly, create a new done
          content = new List.from(content);
          exists = true;
        }
      }

      if (content == null) {
        content = [];
      }
      if (this.content != null) {
        content.addAll(this.content);
      }

      if (content.isEmpty) {
        if (exists) {
          await fileStore.delete(entity.id);
        }
      } else {
        fileStore.put(content, entity.id);
      }

      // update size and modified date
      entity.size = content.length;
      entity.modified = new DateTime.now();

      treeStore.put(entity.toMap(), entity.id);
    } finally {
      await txn.completed;
    }
  }
}

String _makePathAbsolute(String path) {
  if (!isAbsolute(path)) {
    return join(separator, path);
  }
  return path;
}

List<String> getSegments(String path) {
  List<String> segments = split(path);
  if (!isAbsolute(path)) {
    segments.insert(0, separator);
  }
  return segments;
}

String _getParentName(TreeEntity parent, String name) {
  if (parent == null) {
    return join(separator, name);
  } else {
    return join(parent.id.toString(), name);
  }
}
