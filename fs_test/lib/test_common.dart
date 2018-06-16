library fs_shim.test.test_common;

// basically same as the io runner but with extra output
import 'dart:convert';

import 'package:dev_test/test.dart';
import 'package:fs_shim/fs.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:path/path.dart';
import 'package:platform_context/context.dart';
import 'src/import_common.dart';

export 'dart:async';
export 'dart:convert';

export 'package:dev_test/test.dart';
export 'package:fs_shim/utils/copy.dart';
export 'package:fs_shim/utils/entity.dart';
export 'package:fs_shim/utils/glob.dart';
export 'package:fs_shim/utils/part.dart';
export 'package:fs_shim/utils/path.dart';
export 'package:fs_shim/utils/read_write.dart';
export 'src/import_common.dart';

// FileSystem context
abstract class FileSystemTestContext {
  PlatformContext get platform;
  // The file system used
  FileSystem get fs;
  // The path to use for testing
  String get outPath => joinAll(testDescriptions);

  Future<Directory> prepare() async {
    Directory dir = fs.directory(outPath);
    try {
      await dir.delete(recursive: true);
    } on FileSystemException catch (e) {
      expect(e.status, FileSystemException.statusNotFound);
    }
    await dir.create(recursive: true);
    var abs = dir.absolute;
    return abs;
  }
}

abstract class IdbFileSystemTestContext extends FileSystemTestContext {
  IdbFileSystem get fs;
}

final MemoryFileSystemTestContext memoryFileSystemTestContext =
    new MemoryFileSystemTestContext();

class MemoryFileSystemTestContext extends IdbFileSystemTestContext {
  final PlatformContext platform = null;
  final IdbFileSystem fs = newMemoryFileSystem() as IdbFileSystem;
  MemoryFileSystemTestContext();
}

devPrintJson(Map json) {
  print(const JsonEncoder.withIndent("  ").convert(json));
}

bool isIoWindows(FileSystemTestContext ctx) {
  return (isIo(ctx) && ctx.platform.io.isWindows);
}

bool isIoMac(FileSystemTestContext ctx) {
  return (isIo(ctx) && ctx.platform.io.isMac);
}

bool isIo(FileSystemTestContext ctx) {
  return (ctx.platform != null && ctx.platform.io != null);
}
