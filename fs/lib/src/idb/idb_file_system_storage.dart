// ignore_for_file: public_member_api_docs

import 'dart:math';
import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/import.dart'; // ignore: unnecessary_import
import 'package:fs_shim/src/common/log_utils.dart';
import 'package:fs_shim/src/idb/idb_file_system_exception.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'package:idb_shim/utils/idb_utils.dart';
import 'package:meta/meta.dart';

import 'idb_fs.dart';
import 'idb_paging.dart';

/// Default page size
const defaultPageSize = 16 * 1024;

/// Max part count, adapt your settings.
const partCountMax = 16777216; // fit on 8 digits

const String treeStoreName = 'tree';
const String fileStoreName = 'file'; // Whole file content
const String partStoreName =
    'part'; // Page based file content, key is $fileId/000000n
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
/// file: `<treeId>` (id in tree)
/// index: `<partIndex>`
/// content: `<blob>`

const partIndexKey = 'index'; // part index
const partFileKey = 'file'; // part index
const String indexKey = partIndexKey; // part index
const String fileKey = partFileKey; // id in tree
const String contentKey = 'content'; // content in part

const String partFilePartIndexName = '${partStoreName}_$indexKey';

List toFilePartIndexKey(int fileId, int index) => [fileId, index];

List _filePartIndexKeyAsList(Object key) => (key as List);

int filePartIndexKeyFileId(Object key) =>
    _filePartIndexKeyAsList(key)[0] as int;

int filePartIndexKeyPartIndex(Object key) =>
    _filePartIndexKeyAsList(key)[1] as int;

int filePartIndexCursorKeyPartIndex(idb.Cursor cursor) =>
    _filePartIndexKeyAsList(cursor.key)[1] as int;

Uint8List filePartIndexCursorPartContent(idb.CursorWithValue cursor) =>
    anyAsUint8List((cursor.value as Map)[contentKey]);

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

  IdbFileSystemStorageWithDelegate({
    required this.delegate,
    required FileSystemIdbOptions options,
  }) : super(delegate.idbFactory, delegate.dbPath, options: options);
}

// not exported
class IdbFileSystemStorage {
  idb.IdbFactory idbFactory;
  String dbPath;
  FileSystemIdbOptions options;

  int get pageSize => options.pageSize ?? 0;

  IdbFileSystemStorage(this.idbFactory, this.dbPath, {required this.options}) {
    // devPrint('idbFactory ${idbFactory.hashCode}');
  }

  /// Use for derived options
  IdbFileSystemStorage withOptions({required FileSystemIdbOptions options}) =>
      IdbFileSystemStorageWithDelegate(delegate: this, options: options);

  idb.Database? db;
  Completer? _readyCompleter;

  Future get ready async {
    if (debugIdbShowLogs) {
      // ignore: avoid_print
      print('ready? $hashCode');
    }
    if (_readyCompleter == null) {
      _readyCompleter = Completer();

      if (debugIdbShowLogs) {
        // ignore: avoid_print
        print('opening $dbPath');
      }
      // version 4: add file store
      // version 7: add part store v2
      // version 8: add part store v3
      db = await idbFactory.open(
        dbPath,
        version: 8,
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
            store.createIndex(
              parentNameIndexName,
              parentNameKey,
              unique: true,
            ); // <id_parent>/<name>
            store.createIndex(parentIndexName, parentKey);

            store = db.createObjectStore(fileStoreName);
          }
          if (e.oldVersion == 7) {
            // Sorry! it was in dev only though
            db.deleteObjectStore(partStoreName);
          }
          if (e.oldVersion < 8) {
            store = db.createObjectStore(
              partStoreName,
              keyPath: [partFileKey, partIndexKey],
            );
          }
        },
        onBlocked: (e) {
          // ignore: avoid_print
          print(e);
          // ignore: avoid_print
          print('#### db format change - reload');
        },
      );
      _readyCompleter!.complete();
    }
    return _readyCompleter!.future;
  }

  Future<Uint8List> txnGetFileDataV1(idb.Transaction txn, int fileId) async {
    final fileStore = txn.objectStore(fileStoreName);
    var content = await fileStore.getObject(fileId);
    if (content is List) {
      if (debugIdbShowLogs) {
        // ignore: avoid_print
        print('read content v1 ${content.length} bytes');
      }
      return anyListAsUint8List(content);
    }
    return Uint8List(0);
  }

  Future<void> txnDeleteFileDataV1(idb.Transaction txn, int fileId) async {
    final fileStore = txn.objectStore(fileStoreName);
    await fileStore.delete(fileId);
  }

  Future<Node> txnUpdateFileMetaSize(
    idb.Transaction txn,
    Node treeEntity, {
    required int size,
  }) async {
    var treeStore = txn.objectStore(treeStoreName);
    return await txnStoreUpdateFileMetaSize(treeStore, treeEntity, size: size);
  }

  Future<Node> txnStoreUpdateFileMetaSize(
    idb.ObjectStore treeStore,
    Node treeEntity, {
    required int size,
  }) async {
    var newTreeEntity = treeEntity.clone(
      pageSize: treeEntity.pageSize,
      size: size,
      modified: DateTime.now().toUtc(),
    );
    if (debugIdbShowLogs) {
      // ignore: avoid_print
      print('put clone ${logTruncateAny(newTreeEntity)}');
    }
    await treeStore.put(newTreeEntity.toMap(), treeEntity.fileId);
    return newTreeEntity;
  }

  /// Set the content of a file and update meta.
  Future<Node> txnSetFileDataV1(
    idb.Transaction txn,
    Node treeEntity,
    Uint8List bytes,
  ) async {
    // devPrint('_txnSetFileData all ${bytes.length}');
    // Content store
    var fileStore = txn.objectStore(fileStoreName);
    if (debugIdbShowLogs) {
      // ignore: avoid_print
      print('put file ${treeEntity.id} content size ${bytes.length}');
    }

    await fileStore.put(bytes, treeEntity.id);
    treeEntity = treeEntity.clone(pageSize: 0);

    return await txnUpdateFileMetaSize(txn, treeEntity, size: bytes.length);
  }

  int _pageCountFromSize(int size) =>
      pageCountFromSizeAndPageSize(size, pageSize);

  Future<Uint8List> txnGetFileDataV2(idb.Transaction txn, int fileId) async {
    var partStore = txn.objectStore(partStoreName);
    var stream = partStore.openCursor(
      range: allPartRange(fileId),
      autoAdvance: true,
    );
    var readIndex = -1;
    var bytesList = <Uint8List>[];
    await stream.listen((idb.CursorWithValue cursor) {
      // devPrint('cursor ${cursor.key}');
      var index = filePartIndexKeyPartIndex(cursor.key);
      if (index != readIndex + 1) {
        throw StateError(
          'Invalid part index $index, ${readIndex + 1} expected',
        );
      }
      readIndex = index;
      var subContent = filePartIndexCursorPartContent(cursor);
      // print('read subContent v2 ${readIndex}: ${subContent.length} bytes');
      bytesList.add(subContent);
    }).asFuture<void>();
    var content = bytesListToBytes(bytesList);
    if (debugIdbShowLogs) {
      // devPrint('content $content, $bytesList');
      // ignore: avoid_print
      print('read content v2 ${content.length} bytes');
    }
    return content;
  }

  Future<void> txnDeleteFileDataV2(idb.Transaction txn, int fileId) async {
    var partStore = txn.objectStore(partStoreName);
    var stream = partStore.openKeyCursor(
      range: allPartRange(fileId),
      autoAdvance: true,
    );
    var keys = await cursorToPrimaryKeyList(stream);
    for (var key in keys) {
      await partStore.delete(key);
    }
  }

  /// Read the content key
  Future<Uint8List> txnStoreGetPartContent(
    idb.ObjectStore partStore,
    FilePartRef ref,
  ) async {
    var partMap = await partStore.getObject(ref.toKey());
    if (partMap is Map) {
      var bytes = anyAsUint8List(partMap[contentKey]);
      if (debugIdbShowLogs) {
        // ignore: avoid_print
        print('read part $ref size ${bytes.length}');
      }
      return bytes;
    } else {
      throw StateError('Missing existing content for part $ref: $partMap');
    }
  }

  /// Set or add a given part
  Future<void> txnStoreSetPart(
    idb.ObjectStore partStore,
    FilePartRef ref,
    Uint8List bytes,
  ) async {
    var partEntry = {
      indexKey: ref.index,
      fileKey: ref.fileId,
      contentKey: bytes,
    };
    if (debugIdbShowLogs) {
      // ignore: avoid_print
      print('put part $ref size ${bytes.length}');
    }
    try {
      await partStore.put(partEntry);
    } catch (e) {
      if (debugIdbShowLogs) {
        // ignore: avoid_print
        print('put part $ref size ${bytes.length} error $e');
      }
    }
  }

  @visibleForTesting
  Future<void> deletePart(FilePartRef ref) async {
    var txn = db!.transaction(partStoreName, idb.idbModeReadWrite);
    var partStore = txn.objectStore(partStoreName);
    await txnStoreDeletePart(partStore, ref);
    await txn.completed;
  }

  /// Delete a given part
  Future<void> txnStoreDeletePart(
    idb.ObjectStore partStore,
    FilePartRef ref,
  ) async {
    if (debugIdbShowLogs) {
      // ignore: avoid_print
      print('delete part $ref');
    }
    await partStore.delete(ref.toKey());
  }

  late var helper = FilePartHelper(pageSize);

  bool needClearRemainingV2(Node initialEntity, Node newEntity) {
    var first = helper.pageCountFromSize(newEntity.fileSize);
    var last = helper.pageCountFromSize(initialEntity.fileSize);
    return last > first;
  }

  bool needClearStoreV2(
    Node initialEntity,
    Node newEntity, {
    int? newEntityMaxFileSize,
  }) {
    var first = helper.pageCountFromSize(newEntity.fileSize);
    var last = getLastPartToClean(
      initialEntity,
      first,
      newEntityMaxFileSize: newEntityMaxFileSize,
    );
    return last > first;
  }

  int getLastPartToClean(
    Node initialEntity,
    int first, {
    int? newEntityMaxFileSize,
  }) {
    var last = first;
    if (initialEntity.hasPageSize) {
      // Max from initial content.
      var initialLast = FilePartHelper(
        initialEntity.filePageSize,
      ).endPageIndexFromPosition(initialEntity.fileSize);
      last = max(last, initialLast);
    }

    if (newEntityMaxFileSize != null) {
      // Max from max access.
      var accessMaxLast = helper.endPageIndexFromPosition(newEntityMaxFileSize);
      last = max(last, accessMaxLast);
    }
    return last;
  }

  /// Set the content of a file and update meta. return the updated node
  ///
  /// if [allAndClearInitialEntity] remaining content is removed.
  Future<void> txnStoreClearRemainingV2(
    idb.ObjectStore partStore,
    Node initialEntity,
    Node newEntity, {
    int? newEntityMaxFileSize,
  }) async {
    var first = helper.pageIndexFromPosition(newEntity.fileSize);
    var last = first;
    if (initialEntity.hasPageSize) {
      // Max from initial content.
      var initialLast = FilePartHelper(
        initialEntity.filePageSize,
      ).endPageIndexFromPosition(initialEntity.fileSize);
      last = max(last, initialLast);
    }

    if (newEntityMaxFileSize != null) {
      // Max from max access.
      var accessMaxLast = helper.endPageIndexFromPosition(newEntityMaxFileSize);
      last = max(last, accessMaxLast);
    }
    for (var i = first; i < last; i++) {
      var ref = FilePartRef(newEntity.fileId, i);
      if (i == first) {
        var endPositionInPage = helper.getPositionInPage(newEntity.fileSize);
        if (endPositionInPage > 0) {
          // Read the first and make sure it is ok
          var content = await txnStoreGetPartContent(partStore, ref);
          if (endPositionInPage < content.length) {
            // truncate
            await txnStoreSetPart(
              partStore,
              ref,
              content.sublist(0, endPositionInPage),
            );
          }
          continue;
        }
      }
      await txnStoreDeletePart(partStore, ref);
    }
  }

  /// Set the content of a file and update meta. return the updated node
  Future<Node> txnUpdateFileDataV2(
    idb.Transaction txn,
    Node treeEntity,
    List<FilePartIdb> parts,
  ) async {
    var fileId = treeEntity.id!;
    var partStore = txn.objectStore(partStoreName);

    /// Calculate the new file size based on the max position
    var posMax = treeEntity.fileSize;
    for (var part in parts) {
      var start = part.start;

      Uint8List bytes;
      //var kcr = map[part.index];
      // devPrint('index ${part.index}: $kcr');
      var pk = FilePartRef(fileId, part.index);

      // Are we appending
      var endPartPosition = helper.getFilePartPosition(part.index, part.end);
      var atEnd = endPartPosition > posMax;

      if (start == 0 && atEnd) {
        // Write full
        bytes = part.bytes;
      } else {
        var existingBytes = await txnStoreGetPartContent(partStore, pk);
        var end = part.end;

        var bytesBuilder = BytesBuilder();
        if (start > 0) {
          bytesBuilder.add(existingBytes.sublist(0, start));
        }
        bytesBuilder.add(part.bytes);
        if (existingBytes.length > end) {
          bytesBuilder.add(existingBytes.sublist(end));
        }
        bytes = bytesBuilder.toBytes();
      }
      await txnStoreSetPart(partStore, pk, bytes);
      var lastPos = (part.index * pageSize) + bytes.length;
      posMax = max(lastPos, posMax);
    }

    var newSize = posMax;

    // update size
    var newTreeEntity = treeEntity.clone(pageSize: pageSize, size: newSize);

    return await txnUpdateFileMetaSize(
      txn,
      newTreeEntity,
      size: newTreeEntity.fileSize,
    );
  }

  /// Set the content of a file and update meta. return the updated node
  Future<Node> txnSetFileDataV2(
    idb.Transaction txn,
    Node treeEntity,
    Uint8List bytes,
  ) async {
    var fileId = treeEntity.id!;
    var partCount = _pageCountFromSize(bytes.length);
    // Ignore existing
    var partStore = txn.objectStore(partStoreName);
    var stream = partStore.openKeyCursor(
      range: allPartRange(fileId),
      autoAdvance: true,
    );
    final list = <KeyCursorRow>[];
    final toDeleteKeys = <List>[];
    await stream.listen((idb.Cursor cursor) {
      var partFileIndex = filePartIndexKeyPartIndex(cursor.key);
      if (partFileIndex >= partCount) {
        // devPrint('delete part ${cursor.key}');
        toDeleteKeys.add(cursor.primaryKey as List);
      } else {
        list.add(KeyCursorRow(cursor.key, cursor.primaryKey));
      }
    }).asFuture<void>();
    var rows = list;
    var rowByPageIndex = rows.asMap().map(
      (index, row) => MapEntry((rows[index].key as List)[1] as int, row),
    );

    // Write the new ones
    var chunks = uint8ListChunk(bytes, pageSize);
    for (var i = 0; i < chunks.length; i++) {
      var ref = FilePartRef(fileId, i);
      var chunk = chunks[i];
      // read and remove
      rowByPageIndex.remove(i);
      await txnStoreSetPart(partStore, ref, chunk);
    }

    /// Safety delete remaining if any, but this should be empty
    for (var existing in rowByPageIndex.values) {
      await partStore.delete(existing.primaryKey as int);
    }
    for (var existingKey in toDeleteKeys) {
      await partStore.delete(existingKey);
    }

    // update size
    var newTreeEntity = treeEntity.clone(
      pageSize: pageSize,
      size: bytes.length,
    );

    return await txnUpdateFileMetaSize(
      txn,
      newTreeEntity,
      size: newTreeEntity.fileSize,
    );
  }

  Node nodeFromMap(Node parent, int id, dynamic map) {
    final entity = Node.fromMap(
      parent,
      (map as Map).cast<String, Object?>(),
      id,
    );
    if (debugIdbShowLogs) {
      // ignore: avoid_print
      print('nodeFromMap($id, $map)');
    }
    return entity;
  }

  Future<Node> nodeFromNode(idb.ObjectStore treeStore, File file, Node node) {
    return treeStore.getObject(node.fileId).then((value) {
      if (value == null) {
        throw idbNotFoundException(file.path, 'node ${node.id} not found');
      }
      return nodeFromMap(node.parent!, node.fileId, value as Map);
    });
  }

  /// For the given [parent] find the child named [name]
  Future<Node?> txnGetChildNode(
    idb.ObjectStore treeStore,
    idb.Index index,
    Node? parent,
    String name,
    bool followLastLink,
  ) {
    final parentName = getParentName(parent, name);

    FutureOr<Node?> nodeFromKey(dynamic id) {
      if (debugIdbShowLogs) {
        // ignore: avoid_print
        print('nodeFromKey($parentName): $id');
      }
      if (id == null) {
        return null;
      }

      FutureOr<Node?> nodeFromMap(dynamic map) {
        final entity = Node.fromMap(
          parent,
          (map as Map).cast<String, Object?>(),
          id as int,
        );
        if (followLastLink && entity.isLink) {
          return txnResolveLinkNode(treeStore, entity);
        }
        if (debugIdbShowLogs) {
          // ignore: avoid_print
          print('nodeFromMap($parentName): $map');
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

    final entity = await txnGetChildNode(
      store,
      index,
      parent,
      name,
      followLink,
    );

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
    idb.ObjectStore store,
    List<String> segments,
    bool followLastLink,
  ) {
    //idb.idbDevPrint('#XX');
    Future<Node?> nodeFromSegments(List<String> segments) {
      return txnSearch(store, segments, followLastLink).then((
        NodeSearchResult result,
      ) {
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
    idb.ObjectStore store,
    List<String> segments,
    bool followLastLink,
  ) {
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
        return txnGetChildNode(
          store,
          index,
          parent,
          segment,
          followLastLink,
        ).then((Node? nodeEntity) {
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
      return txnGetChildNode(store, index, parent, segment, true).then((
        Node? nodeEntity,
      ) {
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
      if (debugIdbShowLogs) {
        // ignore: avoid_print
        print('txnSearch($segments): $result');
      }
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
    List<String> segments,
    bool followLastLink,
  ) async {
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
      if (debugIdbShowLogs) {
        // ignore: avoid_print
        print('txnAddNode(${entity.segments}): $id');
      }
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
    if (debugIdbShowLogs) {
      // ignore: avoid_print
      print('delete database $dbPath');
    }
    try {
      if (isDebug) {
        var dummyDbName = 'LMYPdr902inIeCi3Uk2m.db';
        try {
          await idbFactory.open(dummyDbName);
        } catch (e) {
          // ignore: avoid_print
          print('failed $e opening $dummyDbName');
        }
      }
      await idbFactory.deleteDatabase(
        dbPath,
        onBlocked: (_) {
          // ignore: avoid_print
          print('ignore blocking');
        },
      );
      if (debugIdbShowLogs) {
        // ignore: avoid_print
        print('database deleted $dbPath');
      }
    } catch (e) {
      // ignore: avoid_print
      print('error deleting database $dbPath: $e');
    }
    _readyCompleter = null;
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
    : this.node(
        fs.FileSystemEntityType.file,
        parent,
        name,
        modified: modified,
        pageSize: pageSize,
      );

  Node.directory(Node? parent, String name, {DateTime? modified})
    : this(parent, name, fs.FileSystemEntityType.directory, modified, 0);

  Node.link(
    Node? parent,
    String name, {
    List<String>? targetSegments,
    DateTime? modified,
  }) : this.node(
         fs.FileSystemEntityType.link,
         parent,
         name,
         modified: modified,
         targetSegments: targetSegments,
       );

  Node.node(
    this.type,
    this.parent,
    this.name, {
    this.targetSegments,
    this.id,
    this.modified,
    this.size,
    this.pageSize,
  });

  Node(
    this.parent,
    this.name,
    this.type,
    this.modified,
    this.size, {
    this.id,
    this.pageSize,
  }) {
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
      if ((pageSize ?? 0) != 0) pageSizeKey: pageSize,
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

  Node clone({int? pageSize, int? size, DateTime? modified}) => Node.node(
    type,
    parent,
    name,
    pageSize: pageSize ?? this.pageSize,
    id: id,
    modified: modified ?? this.modified,
    size: size ?? this.size,
    targetSegments: targetSegments,
  );
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
  String toString() => '$depthDiff $highest ($matches)';
}

List<String> getSegments(String path) {
  return idbPathGetSegments(path);
}

List<String> idbPathGetSegments(String path) {
  final segments = List<String>.from(
    idbPathContext.split(idbPathContext.normalize(path)),
  );
  // devPrint('$path => $segments');
  if (!idbPathContext.isAbsolute(path)) {
    segments.insert(0, idbPathContext.separator);
  }
  if (segments.last == '.') {
    segments.removeLast();
  }
  return segments;
}

String segmentsToPath(List<String> segments) {
  return idbPathContext.joinAll(segments);
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

extension DatabaseIdbExt on idb.Database {
  /// Helper to write on all stores
  idb.Transaction writeAllTransactionList() => transactionList([
    treeStoreName,
    fileStoreName,
    partStoreName,
  ], idb.idbModeReadWrite);

  /// Helper to read on all stores
  idb.Transaction readAllTransactionList() => transactionList([
    treeStoreName,
    fileStoreName,
    partStoreName,
  ], idb.idbModeReadOnly);

  /// Helper to read on all stores
  idb.Transaction openNodeTreeTransaction({
    fs.FileMode mode = fs.FileMode.read,
  }) {
    if (mode == fs.FileMode.read) {
      return transaction(treeStoreName, idb.idbModeReadOnly);
    } else {
      // in read/write mode we might have to write right away to convert the content
      return writeAllTransactionList();
    }
  }
}

extension NodeExt on Node {
  /// Safe
  int get fileId => id!;

  /// True if it as page size options
  bool get hasPageSize => (pageSize ?? 0) != 0;

  /// Safe access
  int get fileSize => size ?? 0;

  /// Safe if hasPageSize
  int get filePageSize => pageSize ?? 0;

  /// Safe if hasPageSize
  int get pageCount => pageCountFromSizeAndPageSize(fileSize, filePageSize);
}

/// Convert an openKeyCursor stream to a list of key, must be auto-advance)
Future<List<Object>> cursorToPrimaryKeyList(Stream<idb.Cursor> stream) =>
    stream.map((cursor) => cursor.primaryKey).toList();

/// Convert an openKeyCursor stream to a list (must be auto-advance)
Future<List<Object>> cursorToKeyList(Stream<idb.Cursor> stream) =>
    stream.map((cursor) => cursor.key).toList();

idb.KeyRange allPartRange(int fileId) {
  return idb.KeyRange.bound(
    toFilePartIndexKey(fileId, 0),
    toFilePartIndexKey(fileId + 1, 0),
    false,
    true,
  );
}
