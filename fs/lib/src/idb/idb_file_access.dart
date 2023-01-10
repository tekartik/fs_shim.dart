// ignore_for_file: public_member_api_docs

import 'package:fs_shim/fs_shim.dart' as fs;
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/src/idb/idb_paging.dart';
import 'package:idb_shim/idb.dart' as idb;
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

import 'idb_file_system.dart';
import 'idb_file_system_storage.dart';
import 'idb_stat.dart';

/// Common helper.
abstract class FileAccessIdb {
  fs.FileMode get mode;

  Node get fileEntity;

  Node get initialFileEntity;

  FileSystemIdb get fsIdb;
}

mixin FileAccessIdbMixin implements FileAccessIdb {
  final stat = AccessStatIdb();
  final flushLock = Lock();
  final positionLock = Lock();
  @protected
  bool noAsyncFlush = false;

  /// initial position (0 or length for append), then updated
  late int accessPosition;
  late int accessFileSize;
  late int accessMaxFileSize;
  @override
  late final fs.FileMode mode;
  late final filePartHelper = FilePartHelper(fileEntity.filePageSize);

  @override
  FileSystemIdb get fsIdb => file.fs as FileSystemIdb;

  /// The opened file
  late final File file;

  /// Only valid once open
  /// Updated on flush and writes.
  @override
  late Node fileEntity;

  @override
  late Node initialFileEntity;

  int get fileId => fileEntity.fileId;

  idb.Database get database => storage.db!;

  /// Internal storage
  IdbFileSystemStorage get storage => fsIdb.storage;

  Timer? _asyncTimer;

  /// Asynchronous flush
  /// Always postpone
  void asyncAction(Future<void> Function() action) {
    _asyncTimer?.cancel();
    late Timer newTimer;
    newTimer = Timer(Duration.zero, () async {
      try {
        await action();
      } catch (e) {
        print('async action failed $e');
      }
      //}
    });
    _asyncTimer = newTimer;
  }
}
