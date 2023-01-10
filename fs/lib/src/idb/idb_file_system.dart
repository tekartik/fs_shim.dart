// ignore_for_file: public_member_api_docs
import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/fs_mixin.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/src/common/log_utils.dart';
import 'package:fs_shim/src/idb/idb_file_write.dart';
import 'package:fs_shim/src/idb/idb_random_access_file.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'idb_directory.dart';
import 'idb_file.dart';
import 'idb_file_read.dart';
import 'idb_file_stat.dart';
import 'idb_file_system_entity.dart';
import 'idb_file_system_exception.dart';
import 'idb_file_system_storage.dart';
import 'idb_link.dart';

var debugIdbShowLogs = false;
// var debugIdbShowLogs = devWarning(true);

var idbSupportsV2Format = true;
// var idbSupportsV2Format = devWarning(true);

/// Settle on using the url way for idb files, (even on Windows).
p.Context get idbPathContext => p.url;

// might not be absolute
List<String> _getTargetSegments(String path) {
  return idbPathContext.split(path);
}

String idbMakePathAbsolute(String path) =>
    segmentsToPath(idbPathGetSegments(path));

IdbFileSystemStorage fsStorage(IdbFileSystem fs) => fs._storage;

/// Delegate mixin
mixin IdbFileSystemDelegateMixin implements fs.FileSystem {
  fs.FileSystem get delegate;

  @override
  fs.Directory directory(String path) => delegate.directory(path);

  @override
  fs.File file(String path) => delegate.file(path);

  @override
  Future<bool> isDirectory(String? path) => delegate.isDirectory(path);

  @override
  Future<bool> isFile(String? path) => delegate.isFile(path);

  @override
  Future<bool> isLink(String? path) => delegate.isLink(path);

  @override
  fs.Link link(String path) => delegate.link(path);

  @override
  String get name => delegate.name;

  @override
  p.Context get path => delegate.path;

  @override
  // ignore: deprecated_member_use_from_same_package
  p.Context get pathContext => delegate.pathContext;

  @override
  bool get supportsFileLink => delegate.supportsFileLink;

  @override
  bool get supportsLink => delegate.supportsLink;

  @override
  bool get supportsRandomAccess => delegate.supportsRandomAccess;

  @override
  Future<fs.FileSystemEntityType> type(String? path,
          {bool followLinks = true}) =>
      delegate.type(path, followLinks: followLinks);
}

/// New internal name.
typedef FileSystemIdb = IdbFileSystem;

///
/// File system implement on idb_shim
///
class IdbFileSystem extends Object
    with FileSystemMixin
    implements fs.FileSystem {
  // file system name
  @override
  String get name => 'idb';

  late final IdbFileSystemStorage _storage;

  @visibleForTesting
  String get storageDbPath => _storage.dbPath;

  idb.Database? get _db => _storage.db;

  idb.Database? get db => _db;
  static const dbPath = 'lfs.db';

  IdbFileSystem._(this._storage);

  IdbFileSystem(idb.IdbFactory factory, String? path,
      {FileSystemIdbOptions? options, IdbFileSystemStorage? storage}) {
    // legacy page size = 0
    options ??= const FileSystemIdbOptions(pageSize: 0);
    _storage = storage ??
        IdbFileSystemStorage(factory, path ?? dbPath, options: options);
  }

  /// Non null database.
  idb.Database get database => db!;

  IdbFileSystem withOptionsImpl({required FileSystemIdbOptions options}) {
    var storage = _storage.withOptions(options: options);
    return IdbFileSystem._(storage);
  }

  @override
  bool operator ==(Object other) {
    if (other is IdbFileSystem) {
      return other._storage == _storage;
    }
    return false;
  }

  @override
  String toString() => 'IdbFs($storageDbPath, $db)';

  @override
  int get hashCode => _storage.hashCode;

  @override
  bool get supportsLink => true;

  @override
  bool get supportsFileLink => true;

  @override
  bool get supportsRandomAccess => true;

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

    final segments = getSegments(path!);

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
    final segments = idbPathGetSegments(path);

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
      } else {
        // not recursive and too deep, cancel
        if ((result.depthDiff > 1) && (recursive != true)) {
          throw idbNotFoundException(path, 'Creation failed');
        }
      }

      // check depth
      entity = await _createDirectory(store, result);
    } finally {
      await txn.completed;
    }
  }

  Future<Node> txnCreateFile(idb.ObjectStore store, List<String> segments,
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

          return txnCreateFile(store, targetSegments, recursive: recursive);

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

        /// create the file.
        entity = Node(parent, segments.last, fs.FileSystemEntityType.file,
            DateTime.now(), 0,
            pageSize: idbOptions.expectedPageSize);
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
    await txnCreateFile(store, segments, recursive: recursive);
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
        if (debugIdbShowLogs) {
          print('Deleting $entity');
        }
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
          if (debugIdbShowLogs) {
            print('change parent $entity');
          }
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

  Future copyFile(File file, String newPath) async {
    await _ready;
    final segments = getSegments(file.path);
    final newSegments = getSegments(newPath);

    final modified = DateTime.now();

    final txn = _db!.writeAllTransactionList();
    try {
      var store = txn.objectStore(treeStoreName);

      final entity = (await txnSearch(store, segments, true)).match;
      final newResult = await txnSearch(store, newSegments, true);
      var newEntity = newResult.match;

      if (entity == null) {
        throw throw idbNotFoundException(file.path, 'Copy failed');
      }

      if (newEntity != null) {
        // Same type ok
        if (newEntity.type != entity.type) {
          if (entity.type == fs.FileSystemEntityType.directory) {
            throw idbNotADirectoryException(file.path, 'Copy failed');
          } else {
            throw idbIsADirectoryException(file.path, 'Copy failed');
          }
        }
      } else {
        // check destination (parent folder must exists)
        if (newResult.depthDiff > 1) {
          throw idbNotFoundException(file.path, 'Copy failed');
        }

        final newParent = newResult.highest; // highest is the parent at depth 1
        newEntity = Node(newParent, newSegments.last,
            fs.FileSystemEntityType.file, modified, 0,
            pageSize: idbOptions.expectedPageSize);
        // add file
        newEntity.id = await store.add(newEntity.toMap()) as int;
      }

      // update content
      store = txn.objectStore(fileStoreName);

      var result = await txnReadCheckNodeFileContent(txn, file, entity);

      // get original
      await txnWriteNodeFileContent(
          txn, newEntity, anyListAsUint8List(result.content));
    } finally {
      await txn.completed;
    }
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
        if (debugIdbShowLogs) {
          print(
              '_createDirectory(${logTruncateAny(entity!.segments)}): $id ${logTruncateAny(entity)}');
        }
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

  StreamSink<List<int>> openWrite(File file,
      {fs.FileMode mode = fs.FileMode.write}) {
    if (mode == fs.FileMode.read) {
      throw ArgumentError("Invalid file mode '$mode' for this operation");
    }

    final sink = IdbWriteStreamSink(file, mode);

    return sink;
  }

  Future<Node> txnOpenNode(idb.ObjectStore treeStore, List<String> segments,
      {required fs.FileMode mode}) async {
    var entity = await storage.txnGetNode(treeStore, segments, true);
    if (entity == null) {
      if (mode == fs.FileMode.write || mode == fs.FileMode.append) {
        entity = await txnCreateFile(treeStore, segments);
      }
    }
    if (entity == null) {
      throw idbNotFoundException(segmentsToPath(segments), '$mode failed');
    }
    if (entity.type != fs.FileSystemEntityType.file) {
      throw idbIsADirectoryException(segmentsToPath(segments), '$mode failed');
    }
    return entity;
  }

  /// Open (can create too in write mode), convert if needed
  Future<Node> openNodeFile(File file, {required FileMode mode}) async {
    await idbReady;
    final txn = storage.db!.openNodeTreeTransaction(mode: mode);

    var node = await txnOpenNodeFile(txn, file, mode: mode);

    await txn.completed;
    return node;
  }

  /// Open a node file content ready to use.
  ///
  /// in write mode, convert if needed
  Future<Node> txnOpenNodeFile(idb.Transaction txn, File file,
      {FileMode mode = FileMode.read}) async {
    var treeStore = txn.objectStore(treeStoreName);
    var segments = getSegments(file.path);
    var node = await txnOpenNode(treeStore, segments, mode: mode);
    // convert?
    var expectedPageSize = idbOptions.expectedPageSize;
    var nodePageSize = node.filePageSize;
    if (nodePageSize != expectedPageSize) {
      if (debugIdbShowLogs) {
        print('Read pageSize $nodePageSize expected $expectedPageSize');
      }

      /// Only in write/append mode
      if (mode != FileMode.read) {
        var readCtrl =
            TxnNodeDataReadStreamCtlr(file, txn, node, 0, node.fileSize);

        TxnNodeDataReadStreamCtlr(file, txn, node, 0, node.fileSize);
        var newNode = node.clone(pageSize: expectedPageSize);
        var writeCtlr = TxnWriteStreamSinkIdb(
            file, txn, newNode, fs.FileMode.write,
            initialFileEntity: node);
        await writeCtlr.addStream(readCtrl.stream);
        // Delete previous
        await txnDeleteFileContent(txn, node);
        await writeCtlr.close();

        return newNode;
      }
    }
    return node;
  }

  Future<RandomAccessFile> open(File file,
      {FileMode mode = FileMode.read}) async {
    await _ready;
    var node = await openNodeFile(file, mode: mode);
    final raf = RandomAccessFileIdb(mode: mode, file: file, fileEntity: node);
    return raf;
  }

  Stream<Uint8List> openRead(File file, int? start, int? end) {
    final ctlr = IdbReadStreamCtlr(file, start, end);
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
  idb.IdbFactory get idbFactory {
    return _storage.idbFactory;
  }

  idb.Transaction writeAllTransactionList() {
    return db!.writeAllTransactionList();
  }
}

/// Web specific extesion
extension FileSystemIdbExt on FileSystem {
  FileSystemIdb get _idbFileSystem => this as FileSystemIdb;

  /// Use a specific pageSize
  FileSystem withIdbOptions({required FileSystemIdbOptions options}) {
    return _idbFileSystem.withOptionsImpl(options: options);
  }

  /// Idb specific options.
  FileSystemIdbOptions get idbOptions => _idbFileSystem._storage.options;
}

@protected
extension FileSystemInternalIdbExt on FileSystemIdb {
  /// The internal storage used
  IdbFileSystemStorage get storage => _storage;

  /// File system ready
  Future<void> get idbReady => _ready;

  Future<Node> txnWriteNodeFileContent(
      idb.Transaction txn, Node entity, Uint8List bytes) async {
    if (entity.hasPageSize && idbSupportsV2Format) {
      return await storage.txnSetFileDataV2(txn, entity, bytes);
    } else {
      return await storage.txnSetFileDataV1(txn, entity, bytes);
    }
  }

  Future<void> txnDeleteFileContent(idb.Transaction txn, Node entity) async {
    var fileId = entity.fileId;
    if (entity.hasPageSize && idbSupportsV2Format) {
      await storage.txnDeleteFileDataV2(txn, fileId);
    } else {
      await storage.txnDeleteFileDataV1(txn, fileId);
    }
  }

  @Deprecated('Use txnReadAndNodeFileContent')
  Future<Uint8List> txnReadNodeFileContent(
      idb.Transaction txn, Node entity) async {
    var content = await txnRawReadNodeFileContent(txn, entity);
    if (isDebug) {
      if (content.length != entity.fileSize) {
        print(
            'invalid content read ${content.length} bytes vs ${entity.fileSize} bytes expected');
      }
    }
    // Safe guard for bad storage
    if (entity.fileSize < content.length) {
      content = content.sublist(0, entity.fileSize);
    }

    return content;
  }

  Future<FileEntityContent> txnReadCheckNodeFileContent(
      idb.Transaction txn, File file, Node entity) async {
    var content = await txnRawReadNodeFileContent(txn, entity);

    if (content.length != entity.fileSize) {
      // read node again
      entity = await storage.nodeFromNode(
          txn.objectStore(treeStoreName), file, entity);
      content = await txnRawReadNodeFileContent(txn, entity);
    }

    // Safe guard for bad storage
    if (entity.fileSize < content.length) {
      content = content.sublist(0, entity.fileSize);
    }

    return FileEntityContent(entity, content);
  }

  Future<Uint8List> txnRawReadNodeFileContent(
      idb.Transaction txn, Node entity) async {
    Uint8List content;

    var fileId = entity.fileId;
    if (entity.hasPageSize) {
      content = await storage.txnGetFileDataV2(txn, fileId);
    } else {
      content = await storage.txnGetFileDataV1(txn, fileId);
    }
    return content;
  }
}

class FileEntityContent {
  final Node entity;
  final Uint8List content;

  FileEntityContent(this.entity, this.content);
}
