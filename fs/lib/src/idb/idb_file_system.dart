// ignore_for_file: public_member_api_docs
import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/src/common/fs_mixin.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/src/common/memory_sink.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'idb_directory.dart';
import 'idb_file.dart';
import 'idb_file_stat.dart';
import 'idb_file_system_entity.dart';
import 'idb_file_system_exception.dart';
import 'idb_file_system_storage.dart';
import 'idb_fs.dart';
import 'idb_link.dart';

/// Settle on using url way for idb files, (even on Windows).
p.Context get idbPathContext => p.url;

List<String> _getPathSegments(String path) {
  path = idbMakePathAbsolute(path);
  return idbPathContext.split(path);
}

// might not be absolute
List<String> _getTargetSegments(String path) {
  return idbPathContext.split(path);
}

class IdbReadStreamCtlr {
  final IdbFileSystem _fs;
  String path;
  int? start;
  int? end;
  late StreamController<Uint8List> _ctlr;

  IdbReadStreamCtlr(this._fs, this.path, this.start, this.end) {
    _ctlr = StreamController(sync: true);

    // put data
    _fs._ready.then((_) async {
      final txn = _fs._db!.transactionList(
          [treeStoreName, fileStoreName], idb.idbModeReadWrite);
      var store = txn.objectStore(treeStoreName);

      try {
        // Try to find the file if it exists
        final segments = getSegments(path);
        final entity = await _fs._storage.txnGetNode(store, segments, true);
        if (entity == null) {
          _ctlr.addError(idbNotFoundException(path, 'Read failed'));
          return;
        }
        if (entity.type != fs.FileSystemEntityType.file) {
          _ctlr.addError(idbIsADirectoryException(path, 'Read failed'));
          return;
        }

        // get existing content
        store = txn.objectStore(fileStoreName);
        var content = (await store.getObject(entity.id!) as List?)?.cast<int>();
        if (content != null) {
          // All at once!
          if (start != null) {
            content = content.sublist(start!, end);
          }
          _ctlr.add(asUint8List(content));
        }
        await _ctlr.close();
      } finally {
        await txn.completed;
      }
    });
  }

  Stream<Uint8List> get stream => _ctlr.stream;
}

Uint8List asUint8List(List? list) {
  if (list is Uint8List) {
    return list;
  } else if (list is List<int>) {
    return Uint8List.fromList(list);
  }
  return Uint8List.fromList(list!.cast<int>());
}

List<int> asIntList(List list) {
  if (list is List<int>) {
    return list;
  }
  return list.cast<int>();
}

class IdbWriteStreamSink extends MemorySink {
  final IdbFileSystem _fs;
  String path;
  fs.FileMode mode;

  IdbWriteStreamSink(this._fs, this.path, this.mode) : super();

  @override
  Future close() async {
    await super.close();

    await _fs._ready;

    final txn = _fs._db!
        .transactionList([treeStoreName, fileStoreName], idb.idbModeReadWrite);
    final treeStore = txn.objectStore(treeStoreName);

    try {
      // Try to find the file if it exists
      final segments = getSegments(path);
      var entity = await _fs._storage.txnGetNode(treeStore, segments, true);
      if (entity == null) {
        if (mode == fs.FileMode.write || mode == fs.FileMode.append) {
          entity = await _fs._txnCreateFile(treeStore, segments);
        }
      }
      if (entity == null) {
        throw idbNotFoundException(path, 'Write failed');
      }
      if (entity.type != fs.FileSystemEntityType.file) {
        throw idbIsADirectoryException(path, 'Write failed');
      }
      // else {      throw new UnsupportedError('TODO');      }

      // get existing content
      final fileStore = txn.objectStore(fileStoreName);
      List<int>? content;
      var exists = false;
      if (mode == fs.FileMode.write) {
        // was created or existing
      } else {
        content = (await fileStore.getObject(entity.id!) as List?)?.cast<int>();
        if (content != null) {
          // on idb the content is readonly, create a new done

          // devWarning('was content = List.from(content);');
          content = List.from(content);
          //content = Uint8List.fromList(content);

          exists = true;
        }
      }

      content ??= <int>[];

      content.addAll(this.content);

      if (content.isEmpty) {
        if (exists) {
          await fileStore.delete(entity.id!);
        }
      } else {
        // devPrint('wrilte all ${content.length}');
        // New in 2020/11/1
        content = asUint8List(content);

        await fileStore.put(content, entity.id);
      }

      // update size and modified date
      entity.size = content.length;
      entity.modified = DateTime.now();

      await treeStore.put(entity.toMap(), entity.id);
    } finally {
      await txn.completed;
    }
  }
}

String idbMakePathAbsolute(String path) {
  if (!idbPathContext.isAbsolute(path)) {
    return idbPathContext.join(idbPathContext.separator, path);
  }
  return path;
}

IdbFileSystemStorage fsStorage(IdbFileSystem fs) => fs._storage;

///
/// File system implement on idb_shim
///
class IdbFileSystem extends Object
    with FileSystemMixin
    implements fs.FileSystem {
  // file system name
  @override
  String get name => 'idb';

  final IdbFileSystemStorage _storage;

  idb.Database? get _db => _storage.db;

  idb.Database? get db => _db;
  static const dbPath = 'lfs.db';

  IdbFileSystem(idb.IdbFactory factory, [String? path])
      : _storage = IdbFileSystemStorage(factory, path ?? dbPath);

  @override
  bool operator ==(Object other) {
    if (other is IdbFileSystem) {
      return other._storage == _storage;
    }
    return false;
  }

  @override
  String toString() => 'Idb($db)';

  @override
  int get hashCode => _storage.hashCode;

  @override
  bool get supportsLink => true;

  @override
  bool get supportsFileLink => true;

  @override
  p.Context get pathContext => path;

  @override
  p.Context get path => idbPathContext;

  // when storage is ready
  Future get _ready => _storage.ready;

  @override
  Future<fs.FileSystemEntityType> type(String? path,
      {bool followLinks = true}) async {
    await _ready;

    final segments = _getPathSegments(path!);

    final entity = await _storage.getNode(segments, followLinks);

    if (entity == null) {
      return fs.FileSystemEntityType.notFound;
    }

    return entity.type;
  }

  @override
  IdbDirectory directory(String? path) => IdbDirectory(this, path);

  @override
  IdbFile file(String? path) => IdbFile(this, path);

  @override
  IdbLink link(String? path) => IdbLink(this, path);

  Future createDirectory(String path, {bool recursive = false}) async {
    await _ready;
    // Go up one by one
    // List<String> segments = getSegments(path);
    final segments = _getPathSegments(path);

    final txn = _db!.transaction(treeStoreName, idb.idbModeReadWrite);
    final store = txn.objectStore(treeStoreName);
    try {
      // Try to find the file if it exists
      final result = await txnSearch(store, segments, false);

      var entity = result.match;
      if (entity != null) {
        if (entity.type == fs.FileSystemEntityType.directory) {
          return null;
        }
        throw idbAlreadyExistsException(path, 'Creation failed');
      }

      // Are we creating a root?
      if ((segments.length == 2) &&
          (recursive != true) &&
          (segments[0] == pathContext.separator)) {
        // Always create the root when needed
      } else
      // not recursive and too deep, cancel
      if ((result.depthDiff > 1) && (recursive != true)) {
        throw idbNotFoundException(path, 'Creation failed');
      }

      // check depth
      entity = await _createDirectory(store, result);
    } finally {
      await txn.completed;
    }
  }

  Future<Node> _txnCreateFile(idb.ObjectStore store, List<String> segments,
      {bool recursive = false}) {
    FutureOr<Node> nodeFromSearchResult(NodeSearchResult result) {
      var entity = result.match;
      if (entity != null) {
        if (entity.type == fs.FileSystemEntityType.file) {
          return entity;
        }
        if (entity.type == fs.FileSystemEntityType.directory) {
          throw idbIsADirectoryException(result.path, 'Creation failed');
        } else if (entity.isLink) {
          // Ok if targetSegments is set

          final targetSegments =
              getAbsoluteSegments(entity, entity.targetSegments!);

          return _txnCreateFile(store, targetSegments, recursive: recursive);

          // Should not happen
          // Need actually write on the target then...
          // Resolve the target
          // throw idbAlreadyExistsException(result.path, 'Already exists');
        } else {
          throw 'unsupported type ${entity.type}';
        }
      }

      // Are we creating a root?
      if ((segments.length == 2) &&
          (recursive != true) &&
          (segments[0] == pathContext.separator)) {
        // Always create the root when needed
      } else
      // not recursive and too deep, cancel
      if ((result.depthDiff > 1) && (recursive != true)) {
        throw idbNotFoundException(result.path, 'Creation failed');
      }
      // regular directory case

      Future<Node> addFileWithSegments(Node? parent, List<String> segments) {
        //TODO check ok to throw exception here
        if (parent == null) {
          throw idbNotFoundException(result.path, 'Creation failed');
        } else if (!parent.isDir) {
          throw idbNotADirectoryException(
              result.path, 'Creation failed - parent not a directory');
        }
        // create it!
        entity = Node(parent, segments.last, fs.FileSystemEntityType.file,
            DateTime.now(), 0);
        //print('adding ${entity}');
        return store.add(entity!.toMap()).then((dynamic id) {
          entity!.id = id as int;
          return entity!;
        });
      }

      Future<Node> addFile(Node? parent) =>
          addFileWithSegments(parent, segments);

      // Handle when the last was a dir to it
      if (result.depthDiff == 1 && result.targetSegments != null) {
        final fileSegments = result.targetSegments!;
        // find parent dir
        return _storage
            .txnGetNode(store, getParentSegments(fileSegments)!, true)
            .then((Node? parent) {
          return addFileWithSegments(parent, fileSegments);
        });
      } else
      // check depth
      if (result.parent.remainingSegments.isNotEmpty) {
        // Create parent dir
        return _createDirectory(store, result.parent).then((Node parent) {
          return addFile(parent);
        });
      } else {
        return addFile(result.highest);
      }
    }

    // Try to find the file if it exists
    return txnSearch(store, segments, false).then(nodeFromSearchResult);
  }

  Future<Node> _createLink(
      idb.ObjectStore store, List<String> segments, String target,
      {bool recursive = false}) {
    // Try to find the file if it exists
    Future<Node> nodeFromSearchResult(NodeSearchResult result) {
      var entity = result.match;
      if (entity != null) {
        throw idbAlreadyExistsException(result.path, 'Already exists');
        /*
        if (entity.type == fs.FileSystemEntityType.LINK) {
          return entity;
        }
        //TODO assume dir for now
        if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
          throw _isADirectoryException(result.path, 'Creation failed');
        }
        */
      }

      // not recursive and too deep, cancel
      if ((result.depthDiff > 1) && (recursive != true)) {
        throw idbNotFoundException(result.path, 'Creation failed');
      }

      Future<Node> addLink(Node? parent) {
        // create it!
        entity = Node.link(parent, segments.last,
            modified: DateTime.now(),
            targetSegments: _getTargetSegments(target));
        //print('adding ${entity}');
        return _storage.txnAddNode(store, entity!);
      }

      // check depth
      if (result.parent.remainingSegments.isNotEmpty) {
        return _createDirectory(store, result.parent).then((Node parent) {
          return addLink(parent);
        });
      } else {
        return addLink(result.highest);
      }
    }

    return txnSearch(store, segments, false).then(nodeFromSearchResult);
  }

  Future createFile(String path, {bool recursive = false}) async {
    await _ready;
    final segments = getSegments(path);
    final txn = _db!.transaction(treeStoreName, idb.idbModeReadWrite);
    final store = txn.objectStore(treeStoreName);
    await _txnCreateFile(store, segments, recursive: recursive);
    await txn.completed;
  }

  Future createLink(String path, String target,
      {bool recursive = false}) async {
    await _ready;
    final segments = getSegments(path);

    final txn = _db!.transaction(treeStoreName, idb.idbModeReadWrite);
    final store = txn.objectStore(treeStoreName);
    await _createLink(store, segments, target, recursive: recursive);
    await txn.completed;
  }

  Future delete(fs.FileSystemEntityType type, String path,
      {bool recursive = false}) async {
    await _ready;
    final segments = getSegments(path);

    final txn = _db!
        .transactionList([treeStoreName, fileStoreName], idb.idbModeReadWrite);

    await _delete(txn, type, segments, recursive: recursive);
    await txn.completed;
  }

  Future _deleteEntity(idb.Transaction txn, Node entity,
      {bool recursive = false}) {
    Object? error;

    var store = txn.objectStore(treeStoreName);

    Future delete() {
      return store.delete(entity.id!).then((_) {
        // For file delete content as well
        if (entity.type == fs.FileSystemEntityType.file) {
          store = txn.objectStore(fileStoreName);
          return store.delete(entity.id!);
        }
        return null;
      });
    }

    if (entity.type == fs.FileSystemEntityType.directory) {
      // check children first
      final parentIndex = store.index(parentIndexName);
      final done = Completer.sync();

      final futures = <Future>[];
      parentIndex
          .openCursor(key: entity.id, autoAdvance: false)
          .listen((idb.CursorWithValue cwv) {
            final child = Node.fromMap(
                entity,
                (cwv.value as Map).cast<String, Object?>(),
                cwv.primaryKey as int);
            if (recursive == true) {
              futures.add(_deleteEntity(txn, child, recursive: true));
              cwv.next();
            } else {
              error = idbNotEmptyException(entity.path, 'Deletion failed');
              done.complete();
            }
          })
          .asFuture()
          .then((_) {
            if (!done.isCompleted) {
              done.complete();
            }
          });
      return done.future.then((_) {
        if (error != null) {
          throw error!;
        }
        return Future.wait(futures);
      }).then((_) {
        return delete();
      });
    } else {
      return delete();
    }
  }

  Future _delete(
      idb.Transaction txn, fs.FileSystemEntityType type, List<String> segments,
      {bool recursive = false}) {
    final store = txn.objectStore(treeStoreName);
    // Don't follow last link
    return txnSearch(store, segments, false).then((NodeSearchResult result) {
      final entity = result.match;
      // not existing throw error
      if (entity == null) {
        throw idbNotFoundException(result.path, 'Deletion failed');
      } else {
        if (type != entity.type) {
          if (entity.type == fs.FileSystemEntityType.directory) {
            throw idbIsADirectoryException(result.path, 'Deletion failed');
          }
          throw idbNotADirectoryException(result.path, 'Deletion failed');
        }
      }
      // ? has kids
      return _deleteEntity(txn, entity, recursive: recursive);
    });
  }

  Future<bool> exists(String path) async {
    await _ready;
    final segments = getSegments(path);

    final entity = await _storage.getNode(segments, false);
    return entity != null;
  }

  Future<IdbFileStat> stat(String path) async {
    await _ready;
    final segments = getSegments(path);

    final txn = _db!.transaction(treeStoreName, idb.idbModeReadOnly);
    try {
      final store = txn.objectStore(treeStoreName);

      // Follow last link
      // the stat is on the destination
      final entity = (await txnSearch(store, segments, true)).match;

      final stat = IdbFileStat();
      if (entity == null) {
        stat.type = fs.FileSystemEntityType.notFound;
      } else {
        stat.type = entity.type;
        stat.size = entity.size!;
        stat.modified = entity.modified!;
      }
      return stat;
    } finally {
      await txn.completed;
    }
  }

  Future rename(
      fs.FileSystemEntityType type, String path, String newPath) async {
    await _ready;
    final segments = getSegments(path);
    final newSegments = getSegments(newPath);

    final txn = _db!
        .transactionList([treeStoreName, fileStoreName], idb.idbModeReadWrite);

    final store = txn.objectStore(treeStoreName);

    // Don't follow last link
    return txnSearch(store, segments, false).then((NodeSearchResult result) {
      final entity = result.match;

      if (entity == null) {
        throw throw idbNotFoundException(path, 'Rename failed');
      }

      return txnSearch(store, newSegments, true)
          .then((NodeSearchResult newResult) {
        final newEntity = newResult.match;

        Node? newParent;

        Future changeParent() {
          // change _parent
          entity.parent = newParent;

          entity.name = newSegments.last;
          return store.put(entity.toMap(), entity.id);
        }

        if (newEntity != null) {
          newParent = newEntity.parent;
          // Same type ok
          if (newEntity.type == entity.type) {
            if (entity.type == fs.FileSystemEntityType.directory) {
              // check if _notEmptyError
              final index = store.index(parentIndexName);
              // any child will matter
              return index.getKey(newEntity.id!).then((dynamic parentId) {
                if (parentId != null) {
                  throw idbNotEmptyException(path, 'Rename failed');
                }
              }).then((_) {
                // delete existing
                return store.delete(newEntity.id!).then((_) {
                  return changeParent();
                });
              });
            } else {
              return _deleteEntity(txn, newEntity).then((_) {
                return changeParent();
              });
            }
          } else {
            if (entity.type == fs.FileSystemEntityType.directory) {
              throw idbNotADirectoryException(path, 'Rename failed');
            } else {
              throw idbIsADirectoryException(path, 'Rename failed');
            }
          }
        } else {
          // check destination (parent folder must exists)
          if (newResult.depthDiff > 1) {
            throw idbNotFoundException(path, 'Rename failed');
          }
          newParent = newResult.highest; // highest is the parent at depth 1
        }

        return changeParent();
      }).whenComplete(() async {
        await txn.completed;
      });
    });
  }

  Future<String> linkTarget(String path) async {
    await _ready;
    final segments = getSegments(path);

    final txn = _db!.transaction(treeStoreName, idb.idbModeReadOnly);
    final store = txn.objectStore(treeStoreName);
    // TODO check followLink
    final target =
        txnSearch(store, segments, false).then((NodeSearchResult result) {
      if (result.matches!) {
        return pathContext.joinAll(result.match!.targetSegments!);
      }
      throw idbNotFoundException(path, 'target not found');
    }).whenComplete(() async {
      await txn.completed;
    });
    return await target;
  }

  Future copyFile(String path, String newPath) async {
    await _ready;
    final segments = getSegments(path);
    final newSegments = getSegments(newPath);

    final modified = DateTime.now();

    final txn = _db!
        .transactionList([treeStoreName, fileStoreName], idb.idbModeReadWrite);
    try {
      var store = txn.objectStore(treeStoreName);

      final entity = (await txnSearch(store, segments, true)).match;
      final newResult = await txnSearch(store, newSegments, true);
      var newEntity = newResult.match;

      if (entity == null) {
        throw throw idbNotFoundException(path, 'Copy failed');
      }

      if (newEntity != null) {
        // Same type ok
        if (newEntity.type != entity.type) {
          if (entity.type == fs.FileSystemEntityType.directory) {
            throw idbNotADirectoryException(path, 'Copy failed');
          } else {
            throw idbIsADirectoryException(path, 'Copy failed');
          }
        }
      } else {
        // check destination (parent folder must exists)
        if (newResult.depthDiff > 1) {
          throw idbNotFoundException(path, 'Copy failed');
        }

        final newParent = newResult.highest; // highest is the parent at depth 1
        newEntity = Node(newParent, newSegments.last,
            fs.FileSystemEntityType.file, modified, 0);
        // add file
        newEntity.id = await store.add(newEntity.toMap()) as int;
      }

      // update content
      store = txn.objectStore(fileStoreName);

      // get original
      final data = await store.getObject(entity.id!) as List?;
      if (data != null) {
        await _txnSetFileData(txn, newEntity, asUint8List(data));
      } else {
        await store.delete(newEntity.id!);
      }
    } finally {
      await txn.completed;
    }
  }

  /// Set the content of a file and update meta.
  Future<void> _txnSetFileData(
      idb.Transaction txn, Node treeEntity, Uint8List bytes) async {
    // devPrint('_txnSetFileData all ${bytes.length}');
    // Content store
    var fileStore = txn.objectStore(fileStoreName);
    await fileStore.put(bytes, treeEntity.id);

    // update size
    treeEntity.size = bytes.length;
    var treeStore = txn.objectStore(treeStoreName);
    await treeStore.put(treeEntity.toMap(), treeEntity.id);
  }

  FutureOr<Node?> txnGetWithParent(idb.ObjectStore treeStore, idb.Index index,
          Node parent, String name, bool followLastLink) =>
      _storage.txnGetChildNode(treeStore, index, parent, name, followLastLink);

  // follow link only for last one
  Future<NodeSearchResult> txnSearch(
          idb.ObjectStore store, List<String> segments, bool followLastLink) =>
      _storage.txnSearch(store, segments, followLastLink);

  Future<Node> _createDirectory(
      idb.ObjectStore store, NodeSearchResult result) {
    var entity = result.highest;

    final remainings = List<String>.from(result.remainingSegments);
    var i = 0;
    Future next() {
      final segment = remainings[i];
      final parent = entity;
      // create it!
      entity = Node(parent, segment, fs.FileSystemEntityType.directory,
          DateTime.now(), 0);
      return store.add(entity!.toMap()).then((dynamic id) {
        entity!.id = id as int;
        if (i++ < remainings.length - 1) {
          return next();
        }
        return null;
      });
    }

    return next().then((_) {
      return entity!;
    });
  }

  StreamSink<List<int>> openWrite(String path,
      {fs.FileMode mode = fs.FileMode.write}) {
    if (mode == fs.FileMode.read) {
      throw ArgumentError("Invalid file mode '$mode' for this operation");
    }
    path = idbMakePathAbsolute(path);

    final sink = IdbWriteStreamSink(this, path, mode);

    return sink;
  }

  Stream<Uint8List> openRead(String path, int? start, int? end) {
    path = idbMakePathAbsolute(path);
    final ctlr = IdbReadStreamCtlr(this, path, start, end);
    /*
    MemoryFileSystemEntityImpl fileImpl = getEntity(path);
    // if it exists we're fine
    if (fileImpl is MemoryFileImpl) {
      ctlr.addStream(fileImpl.openRead()).then((_) {
        ctlr.close();
      });
    } else {
      ctlr.addError(new _MemoryFileSystemException(
          path, 'Cannot open file', _noSuchPathError));
    }
    */
    return ctlr.stream;
  }

  fs.FileSystemEntity? nodeToFileSystemEntity(Node node) {
    if (node.isDir) {
      return IdbDirectory(this, node.path);
    } else if (node.isFile) {
      return IdbFile(this, node.path);
    } else if (node.isLink) {
      return IdbLink(this, node.path);
    }
    return null;
  }

  fs.FileSystemEntity? linkNodeToFileSystemEntity(
      String path, Node targetNode) {
    if (targetNode.isDir) {
      return IdbDirectory(this, path);
    } else if (targetNode.isFile) {
      return IdbFile(this, path);
    } else if (targetNode.isLink) {
      // should not happen...
      return IdbLink(this, path);
    }
    return null;
  }

  Stream<IdbFileSystemEntity> list(String path,
      {bool recursive = false, bool followLinks = true}) {
    final segments = getSegments(path);

    final ctlr = StreamController<IdbFileSystemEntity>();

    _ready.then((_) {
      final recursives = <Future>[];
      final txn = _db!.transaction(treeStoreName, idb.idbModeReadOnly);
      final treeStore = txn.objectStore(treeStoreName);
      final index = treeStore.index(parentIndexName);

      // Always follow the parameter if it is a link
      return txnSearch(treeStore, segments, true).then((result) {
        final entity = result.match;
        if (entity == null) {
          ctlr.addError(idbNotFoundException(path, 'List failed'));
        } else {
          Future list(String path, Node entity) {
            return index
                .openCursor(key: entity.id, autoAdvance: true)
                .listen((idb.CursorWithValue cwv) {
              // We have a node but the parent might not match!
              // So create a fake
              final childNode = Node.fromMap(
                  entity,
                  (cwv.value as Map).cast<String, Object?>(),
                  cwv.primaryKey as int);
              final relativePath = pathContext.join(path, childNode.name);
              if (childNode.isDir) {
                final dir = IdbDirectory(this, relativePath);
                ctlr.add(dir);
                if (recursive == true) {
                  recursives.add(list(relativePath, childNode));
                }
              } else if (childNode.isFile) {
                ctlr.add(IdbFile(this, relativePath));
                //ctlr.add(nodeToFileSystemEntity(childNode));
              } else if (childNode.isLink) {
                final link = IdbLink(this, relativePath);

                if (followLinks) {
                  recursives.add(Future.sync(() {
                    return _storage
                        .txnResolveLinkNode(treeStore, childNode)
                        .then((entity) {
                      if (entity != null) {
                        ctlr.add(
                            linkNodeToFileSystemEntity(relativePath, entity)
                                as IdbFileSystemEntity);

                        // recursive?
                        if (entity.isDir && recursive == true) {
                          recursives.add(list(relativePath, entity));
                        }
                      } else {
                        ctlr.add(link);
                      }
                    });
                  }));
                } else {
                  ctlr.add(link);
                }
              } else {
                throw UnsupportedError('type ${childNode.type} not supported');
              }
            }).asFuture();
          }

          return list(path, entity);
        }
        return null;
      }).whenComplete(() async {
        await txn.completed;

        // wait after completed to avoid deadlock
        await Future.wait(recursives);

        await ctlr.close();
      });
    });
    return ctlr.stream;
  }

  /// Cannot be reused, used in tests only.
  @visibleForTesting
  void close() {
    _db?.close();
  }

  /// Get IdbFactory, used in tests only
  @visibleForTesting
  idb.IdbFactory? get idbFactory {
    return _db?.factory;
  }
}
