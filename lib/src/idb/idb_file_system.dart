library fs_shim.src.idb.idb_file_system;

import 'idb_fs.dart';
import '../../fs.dart' as fs;
import 'idb_file_system_entity.dart';
import '../common/fs_mixin.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'dart:async';
import 'package:path/path.dart';
import 'package:fs_shim/src/common/fs_mixin.dart';
import 'package:fs_shim/src/common/memory_sink.dart';
import 'idb_link.dart';
import 'idb_directory.dart';
import 'idb_file.dart';
import 'idb_file_system_exception.dart';
import 'idb_file_stat.dart';
import 'idb_file_system_storage.dart';

List<String> _getPathSegments(String path) {
  path = idbMakePathAbsolute(path);
  return split(path);
}

// might not be absolute
List<String> _getTargetSegments(String path) {
  return split(path);
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
      idb.Transaction txn = _fs._db.transactionList(
          [treeStoreName, fileStoreName], idb.idbModeReadWrite);
      idb.ObjectStore store = txn.objectStore(treeStoreName);

      try {
        // Try to find the file if it exists
        List<String> segments = getSegments(path);
        Node entity = await _fs._storage.txnGetNode(store, segments, true);
        if (entity == null) {
          _ctlr.addError(idbNotFoundException(path, "Read failed"));
          return;
        }
        if (entity.type != fs.FileSystemEntityType.FILE) {
          _ctlr.addError(idbIsADirectoryException(path, "Read failed"));
          return;
        }

        // get existing content
        store = txn.objectStore(fileStoreName);
        List<int> content = await store.getObject(entity.id) as List<int>;
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

    idb.Transaction txn = _fs._db
        .transactionList([treeStoreName, fileStoreName], idb.idbModeReadWrite);
    idb.ObjectStore treeStore = txn.objectStore(treeStoreName);

    try {
      // Try to find the file if it exists
      List<String> segments = getSegments(path);
      Node entity = await _fs._storage.txnGetNode(treeStore, segments, true);
      if (entity == null) {
        if (mode == fs.FileMode.WRITE || mode == fs.FileMode.APPEND) {
          entity = await _fs._txnCreateFile(treeStore, segments);
        }
      }
      if (entity == null) {
        throw idbNotFoundException(path, "Write failed");
      }
      if (entity.type != fs.FileSystemEntityType.FILE) {
        throw idbIsADirectoryException(path, "Write failed");
      }
      // else {      throw new UnsupportedError("TODO");      }

      // get existing content
      idb.ObjectStore fileStore = txn.objectStore(fileStoreName);
      List<int> content;
      bool exists = false;
      if (mode == fs.FileMode.WRITE) {
        content == null;
      } else {
        content = await fileStore.getObject(entity.id) as List<int>;
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

String idbMakePathAbsolute(String path) {
  if (!isAbsolute(path)) {
    return join(separator, path);
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
  String get name => 'idb';

  final IdbFileSystemStorage _storage;
  idb.Database get _db => _storage.db;
  idb.Database get db => _db;
  static const dbPath = 'lfs.db';
  IdbFileSystem(idb.IdbFactory factory, [String path])
      : _storage =
            new IdbFileSystemStorage(factory, path == null ? dbPath : path) {}

  @override
  bool operator ==(o) {
    if (o is IdbFileSystem) {
      return o._storage == _storage;
    }
    return false;
  }

  @override
  bool get supportsLink => true;

  @override
  bool get supportsFileLink => true;

  @override
  Context get pathContext => context;

  // when storage is ready
  Future get _ready => _storage.ready;

  @override
  Future<fs.FileSystemEntityType> type(String path,
      {bool followLinks: true}) async {
    await _ready;

    List<String> segments = _getPathSegments(path);

    Node entity = await _storage.getNode(segments, followLinks);

    if (entity == null) {
      return fs.FileSystemEntityType.NOT_FOUND;
    }

    return entity.type;
  }

  @override
  IdbDirectory newDirectory(String path) => new IdbDirectory(this, path);

  @override
  IdbFile newFile(String path) => new IdbFile(this, path);

  @override
  IdbLink newLink(String path) => new IdbLink(this, path);

  Future createDirectory(String path, {bool recursive: false}) async {
    await _ready;
    // Go up one by one
    // List<String> segments = getSegments(path);
    List<String> segments = _getPathSegments(path);

    idb.Transaction txn = _db.transaction(treeStoreName, idb.idbModeReadWrite);
    idb.ObjectStore store = txn.objectStore(treeStoreName);
    try {
      // Try to find the file if it exists
      NodeSearchResult result = await txnSearch(store, segments, false);
      Node entity = result.match;
      if (entity != null) {
        if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
          return null;
        }
        throw idbAlreadyExistsException(path, "Creation failed");
      }

      // not recursive and too deep, cancel
      if ((result.depthDiff > 1) && (recursive != true)) {
        throw idbNotFoundException(path, "Creation failed");
      }

      // check depth
      entity = await _createDirectory(store, result);
      if (entity == null) {
        throw idbNotFoundException(path, "Creation failed");
      }
    } finally {
      await txn.completed;
    }
  }

  Future<Node> _txnCreateFile(idb.ObjectStore store, List<String> segments,
      {bool recursive: false}) {
    // Try to find the file if it exists
    return txnSearch(store, segments, false).then((NodeSearchResult result) {
      Node entity = result.match;
      if (entity != null) {
        if (entity.type == fs.FileSystemEntityType.FILE) {
          return entity;
        }
        if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
          throw idbIsADirectoryException(result.path, "Creation failed");
        } else if (entity.isLink) {
          // Ok if targetSegments is set

          List<String> targetSegments =
              getAbsoluteSegments(entity, entity.targetSegments);

          return _txnCreateFile(store, targetSegments, recursive: recursive);

          // Should not happen
          // Need actually write on the target then...
          // Resolve the target
          // throw idbAlreadyExistsException(result.path, "Already exists");
        } else {
          throw 'unsupported type ${entity.type}';
        }
      }

      // not recursive and too deep, cancel
      if ((result.depthDiff > 1) && (recursive != true)) {
        throw idbNotFoundException(result.path, "Creation failed");
      } else
      // regular directory case
      {
        Future<Node> _addFileWithSegments(Node parent, List<String> segments) {
          //TODO check ok to throw exception here
          if (parent == null) {
            throw idbNotFoundException(result.path, "Creation failed");
          } else if (!parent.isDir) {
            throw idbNotADirectoryException(
                result.path, "Creation failed - parent not a directory");
          }
          // create it!
          entity = new Node(parent, segments.last, fs.FileSystemEntityType.FILE,
              new DateTime.now(), 0);
          //print('adding ${entity}');
          return store.add(entity.toMap()).then((int id) {
            entity.id = id;
            return entity;
          }) as Future<Node>;
        }
        Future<Node> _addFile(Node parent) =>
            _addFileWithSegments(parent, segments);

        // Handle when the last was a dir to it
        if (result.depthDiff == 1 && result.targetSegments != null) {
          List<String> fileSegments = result.targetSegments;
          // find parent dir
          return _storage
              .txnGetNode(store, getParentSegments(fileSegments), true)
              .then((Node _parent) {
            return _addFileWithSegments(_parent, fileSegments);
          });
        } else
        // check depth
        if (result.parent.remainingSegments.isNotEmpty) {
          // Create parent dir
          return _createDirectory(store, result.parent).then((Node parent) {
            return _addFile(parent);
          });
        } else {
          return _addFile(result.highest);
        }
      }
    }) as Future<Node>;
  }

  Future<Node> _createLink(
      idb.ObjectStore store, List<String> segments, String target,
      {bool recursive: false}) {
    // Try to find the file if it exists
    return txnSearch(store, segments, false).then((NodeSearchResult result) {
      Node entity = result.match;
      if (entity != null) {
        throw idbAlreadyExistsException(result.path, "Already exists");
        /*
        if (entity.type == fs.FileSystemEntityType.LINK) {
          return entity;
        }
        //TODO assume dir for now
        if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
          throw _isADirectoryException(result.path, "Creation failed");
        }
        */
      }

      // not recursive and too deep, cancel
      if ((result.depthDiff > 1) && (recursive != true)) {
        throw idbNotFoundException(result.path, "Creation failed");
      }

      Future<Node> _addLink(Node parent) {
        // create it!
        entity = new Node.link(parent, segments.last,
            modified: new DateTime.now(),
            targetSegments: _getTargetSegments(target));
        //print('adding ${entity}');
        return _storage.txnAddNode(store, entity);
      }
      // check depth
      if (result.parent.remainingSegments.isNotEmpty) {
        return _createDirectory(store, result.parent).then((Node parent) {
          if (parent == null) {
            throw idbNotFoundException(result.path, "Creation failed");
          }
          return _addLink(parent);
        });
      } else {
        return _addLink(result.highest);
      }
    }) as Future<Node>;
  }

  Future createFile(String path, {bool recursive: false}) async {
    await _ready;
    List<String> segments = getSegments(path);

    idb.Transaction txn = _db.transaction(treeStoreName, idb.idbModeReadWrite);
    idb.ObjectStore store = txn.objectStore(treeStoreName);
    await _txnCreateFile(store, segments, recursive: recursive);
    await txn.completed;
  }

  Future createLink(String path, String target, {bool recursive: false}) async {
    await _ready;
    List<String> segments = getSegments(path);

    idb.Transaction txn = _db.transaction(treeStoreName, idb.idbModeReadWrite);
    idb.ObjectStore store = txn.objectStore(treeStoreName);
    await _createLink(store, segments, target, recursive: recursive);
    await txn.completed;
  }

  Future delete(fs.FileSystemEntityType type, String path,
      {bool recursive: false}) async {
    await _ready;
    List<String> segments = getSegments(path);

    idb.Transaction txn = _db.transactionList(
        [treeStoreName, fileStoreName], idb.idbModeReadWrite);

    await _delete(txn, type, segments, recursive: recursive);
    await txn.completed;
  }

  Future _deleteEntity(idb.Transaction txn, Node entity,
      {bool recursive: false}) {
    var error;

    idb.ObjectStore store = txn.objectStore(treeStoreName);

    _delete() {
      return store.delete(entity.id).then((_) {
        // For file delete content as well
        if (entity.type == fs.FileSystemEntityType.FILE) {
          store = txn.objectStore(fileStoreName);
          return store.delete(entity.id);
        }
      });
    }

    if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
      // check children first
      idb.Index parentIndex = store.index(parentIndexName);
      Completer done = new Completer.sync();

      List<Future> futures = [];
      parentIndex
          .openCursor(key: entity.id, autoAdvance: false)
          .listen((idb.CursorWithValue cwv) {
        Node child = new Node.fromMap(entity, cwv.value, cwv.primaryKey);
        if (recursive == true) {
          futures.add(_deleteEntity(txn, child, recursive: true));
          cwv.next();
        } else {
          error = idbNotEmptyException(entity.path, "Deletion failed");
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
    idb.ObjectStore store = txn.objectStore(treeStoreName);
    // Don't follow last link
    return txnSearch(store, segments, false).then((NodeSearchResult result) {
      Node entity = result.match;
      // not existing throw error
      if (entity == null) {
        throw idbNotFoundException(result.path, "Deletion failed");
      } else if (type != null) {
        if (type != entity.type) {
          if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
            throw idbIsADirectoryException(result.path, "Deletion failed");
          }
          throw idbNotADirectoryException(result.path, "Deletion failed");
        }
      }
      // ? has kids
      return _deleteEntity(txn, entity, recursive: recursive);
    });
  }

  Future<bool> exists(String path) async {
    await _ready;
    List<String> segments = getSegments(path);

    Node entity = await _storage.getNode(segments, false);
    return entity != null;
  }

  Future<IdbFileStat> stat(String path) async {
    await _ready;
    List<String> segments = getSegments(path);

    idb.Transaction txn = _db.transaction(treeStoreName, idb.idbModeReadOnly);
    try {
      idb.ObjectStore store = txn.objectStore(treeStoreName);

      // Follow last link
      // the stat is on the destination
      Node entity = (await txnSearch(store, segments, true)).match;

      IdbFileStat stat = new IdbFileStat();
      if (entity == null) {
        stat.type = fs.FileSystemEntityType.NOT_FOUND;
      } else {
        stat.type = entity.type;
        stat.size = entity.size;
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

    idb.Transaction txn = _db.transactionList(
        [treeStoreName, fileStoreName], idb.idbModeReadWrite);

    idb.ObjectStore store = txn.objectStore(treeStoreName);

    // Don't follow last link
    return txnSearch(store, segments, false).then((NodeSearchResult result) {
      Node entity = result.match;

      if (entity == null) {
        throw throw idbNotFoundException(path, "Rename failed");
      }

      return txnSearch(store, newSegments, true)
          .then((NodeSearchResult newResult) {
        Node newEntity = newResult.match;

        Node newParent;

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
              idb.Index index = store.index(parentIndexName);
              // any child will matter
              return index.getKey(newEntity.id).then((int parentId) {
                if (parentId != null) {
                  throw idbNotEmptyException(path, "Rename failed");
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
              throw idbNotADirectoryException(path, "Rename failed");
            } else {
              throw idbIsADirectoryException(path, "Rename failed");
            }
          }
        } else {
          // check destination (parent folder must exists)
          if (newResult.depthDiff > 1) {
            throw idbNotFoundException(path, "Rename failed");
          }
          newParent = newResult.highest; // highest is the parent at depth 1
        }

        return _changeParent();
      }).whenComplete(() {
        return txn.completed;
      });
    });
  }

  Future<String> linkTarget(String path) async {
    await _ready;
    List<String> segments = getSegments(path);

    idb.Transaction txn = _db.transaction(treeStoreName, idb.idbModeReadOnly);
    idb.ObjectStore store = txn.objectStore(treeStoreName);
    // TODO check followLink
    Future<String> target =
        txnSearch(store, segments, false).then((NodeSearchResult result) {
      if (result.matches) {
        return joinAll(result.match.targetSegments);
      }
    }).whenComplete(() {
      return txn.completed;
    }) as Future<String>;
    return await target;
  }

  Future copyFile(String path, String newPath) async {
    await _ready;
    List<String> segments = getSegments(path);
    List<String> newSegments = getSegments(newPath);

    DateTime _modified = new DateTime.now();

    idb.Transaction txn = _db.transactionList(
        [treeStoreName, fileStoreName], idb.idbModeReadWrite);
    try {
      idb.ObjectStore store = txn.objectStore(treeStoreName);

      Node entity = (await txnSearch(store, segments, true)).match;
      NodeSearchResult newResult = await txnSearch(store, newSegments, true);
      Node newEntity = newResult.match;

      if (entity == null) {
        throw throw idbNotFoundException(path, "Copy failed");
      }

      if (newEntity != null) {
        // Same type ok
        if (newEntity.type != entity.type) {
          if (entity.type == fs.FileSystemEntityType.DIRECTORY) {
            throw idbNotADirectoryException(path, "Copy failed");
          } else {
            throw idbIsADirectoryException(path, "Copy failed");
          }
        }
      } else {
        // check destination (parent folder must exists)
        if (newResult.depthDiff > 1) {
          throw idbNotFoundException(path, "Copy failed");
        }

        Node newParent = newResult.highest; // highest is the parent at depth 1
        newEntity = new Node(newParent, newSegments.last,
            fs.FileSystemEntityType.FILE, _modified, 0);
        // add file
        newEntity.id = await store.add(newEntity.toMap());
      }

      // update content
      store = txn.objectStore(fileStoreName);

      // get original
      List<int> data = await store.getObject(entity.id) as List<int>;
      if (data != null) {
        await store.put(data, newEntity.id);

        // update size
        newEntity.size = data.length;
        store = txn.objectStore(treeStoreName);
        await store.put(newEntity.toMap(), newEntity.id);
      } else {
        await store.delete(newEntity.id);
      }
    } finally {
      await txn.completed;
    }
  }

  Future<Node> txnGetWithParent(idb.ObjectStore treeStore, idb.Index index,
          Node parent, String name, bool followLastLink) =>
      _storage.txnGetChildNode(treeStore, index, parent, name, followLastLink);

  // follow link only for last one
  Future<NodeSearchResult> txnSearch(
          idb.ObjectStore store, List<String> segments, followLastLink) =>
      _storage.txnSearch(store, segments, followLastLink);

  Future<Node> _createDirectory(
      idb.ObjectStore store, NodeSearchResult result) {
    Node entity = result.highest;

    List<String> remainings = new List.from(result.remainingSegments);
    int i = 0;
    _next() {
      String segment = remainings[i];
      Node parent = entity;
      // create it!
      entity = new Node(parent, segment, fs.FileSystemEntityType.DIRECTORY,
          new DateTime.now(), 0);
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
    }) as Future<Node>;
  }

  StreamSink<List<int>> openWrite(String path,
      {fs.FileMode mode: fs.FileMode.WRITE}) {
    if (mode == null) {
      mode = fs.FileMode.WRITE;
    }
    if (mode == fs.FileMode.READ) {
      throw new ArgumentError("Invalid file mode '${mode}' for this operation");
    }
    path = idbMakePathAbsolute(path);

    IdbWriteStreamSink sink = new IdbWriteStreamSink(this, path, mode);

    return sink;
  }

  Stream<List<int>> openRead(String path, int start, int end) {
    path = idbMakePathAbsolute(path);
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

  fs.FileSystemEntity nodeToFileSystemEntity(Node node) {
    if (node.isDir) {
      return new IdbDirectory(this, node.path);
    } else if (node.isFile) {
      return new IdbFile(this, node.path);
    } else if (node.isLink) {
      return new IdbLink(this, node.path);
    }
    return null;
  }

  fs.FileSystemEntity linkNodeToFileSystemEntity(String path, Node targetNode) {
    if (targetNode.isDir) {
      return new IdbDirectory(this, path);
    } else if (targetNode.isFile) {
      return new IdbFile(this, path);
    } else if (targetNode.isLink) {
      // should not happen...
      return new IdbLink(this, path);
    }
    return null;
  }

  Stream<IdbFileSystemEntity> list(String path,
      {bool recursive: false, bool followLinks: true}) {
    List<String> segments = getSegments(path);

    StreamController<IdbFileSystemEntity> ctlr = new StreamController();

    _ready.then((_) {
      List<Future> recursives = [];
      idb.Transaction txn = _db.transaction(treeStoreName, idb.idbModeReadOnly);
      idb.ObjectStore treeStore = txn.objectStore(treeStoreName);
      idb.Index index = treeStore.index(parentIndexName);

      // Always follow the parameter if it is a link
      return txnSearch(treeStore, segments, true).then((result) {
        Node entity = result.match;
        if (entity == null) {
          ctlr.addError(idbNotFoundException(path, "List failed"));
        } else {
          Future _list(String path, Node entity) {
            return index
                .openCursor(key: entity.id, autoAdvance: true)
                .listen((idb.CursorWithValue cwv) {
              // We have a node but the parent might not match!
              // So create a fake
              Node childNode =
                  new Node.fromMap(entity, cwv.value, cwv.primaryKey);
              String relativePath = join(path, childNode.name);
              if (childNode.isDir) {
                IdbDirectory dir = new IdbDirectory(this, relativePath);
                ctlr.add(dir);
                if (recursive == true) {
                  recursives.add(_list(dir.path, childNode));
                }
              } else if (childNode.isFile) {
                ctlr.add(new IdbFile(this, relativePath));
                //ctlr.add(nodeToFileSystemEntity(childNode));
              } else if (childNode.isLink) {

                IdbLink link = new IdbLink(this, relativePath);

                if (followLinks) {
                  recursives.add(new Future.sync(() {
                    return _storage
                        .txnResolveLinkNode(treeStore, childNode)
                        .then((Node entity) {
                      if (entity != null) {
                        ctlr.add(
                            linkNodeToFileSystemEntity(relativePath, entity));
                      } else {
                        ctlr.add(link);
                      }
                    });
                  }));
                } else {
                  ctlr.add(link);
                }
              } else {
                throw new UnsupportedError(
                    "type ${childNode.type} not supported");
              }
            }).asFuture();
          }
          return _list(path, entity);
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
