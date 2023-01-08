library fs_shim.test.test_common;

// ignore_for_file: implementation_imports
// basically same as the io runner but with extra output
import 'dart:convert';

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:fs_shim/src/platform/platform.dart'
    show PlatformContext, PlatformContextIo;
import 'package:test/test.dart';

import 'src/import_common.dart';

export 'dart:async';
export 'dart:convert';

export 'package:fs_shim/src/idb/idb_fs.dart' show FileSystemIdb;
export 'package:fs_shim/src/platform/platform.dart'
    show
        PlatformContext,
        PlatformContextBrowser,
        PlatformContextIo,
        platformContextBrowser,
        platformContextIo;
export 'package:fs_shim/src/platform/platform.dart';
export 'package:fs_shim/utils/copy.dart';
export 'package:fs_shim/utils/entity.dart';
export 'package:fs_shim/utils/glob.dart';
export 'package:fs_shim/utils/part.dart';
export 'package:fs_shim/utils/path.dart';
export 'package:fs_shim/utils/read_write.dart';
export 'package:test/test.dart';

export 'src/import_common.dart';

/// FileSystem test context
abstract class FileSystemTestContext {
  PlatformContext? get platform;

  // The file system used
  FileSystem get fs;

  /// Base path
  String? basePath;

  static int _id = 0;

  Directory _prepareNewDirectory() => fs.directory(fs.path
      .joinAll(<String>[if (basePath != null) basePath!, 'out', '${++_id}']));

  Future<Directory> prepare() async {
    var outPath = _prepareNewDirectory().path;
    final dir = fs.directory(outPath);
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

typedef FileSystemTestContextIdb = IdbFileSystemTestContext;

abstract class IdbFileSystemTestContext extends FileSystemTestContext {
  @override
  PlatformContext? platform;
  @override
  FileSystemIdb get fs;
}

abstract class FileSystemTestContextIdbWithOptions
    extends IdbFileSystemTestContext {
  final FileSystemIdbOptions options;

  FileSystemTestContextIdbWithOptions({required this.options});
}

final MemoryFileSystemTestContext memoryFileSystemTestContext =
    MemoryFileSystemTestContext();

class MemoryFileSystemTestContext extends IdbFileSystemTestContext {
  MemoryFileSystemTestContext();

  @override
  final IdbFileSystem fs = newFileSystemMemory() as IdbFileSystem;
}

class MemoryFileSystemTestContextWithOptions
    extends FileSystemTestContextIdbWithOptions {
  MemoryFileSystemTestContextWithOptions({required super.options});

  @override
  final IdbFileSystem fs = newFileSystemMemory() as IdbFileSystem;
}

void devPrintJson(Map json) {
  print(const JsonEncoder.withIndent('  ').convert(json));
}

String jsonPretty(dynamic json) {
  if (json is String) {
    json = jsonDecode(json);
  }
  return const JsonEncoder.withIndent('  ').convert(json);
}

bool isIoWindows(FileSystemTestContext ctx) {
  return isIo(ctx) && (ctx.platform as PlatformContextIo).isIoWindows == true;
}

bool isIoMac(FileSystemTestContext ctx) {
  return isIo(ctx) && (ctx.platform as PlatformContextIo).isIoMacOS == true;
}

bool isIoLinux(FileSystemTestContext ctx) {
  return isIo(ctx) && (ctx.platform as PlatformContextIo).isIoLinux == true;
}

bool isIo(FileSystemTestContext ctx) {
  return ctx.platform?.isIo == true;
}
