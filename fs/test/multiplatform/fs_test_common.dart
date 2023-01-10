// ignore_for_file: implementation_imports

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:fs_shim/src/idb/idb_fs.dart';
import 'package:fs_shim/src/platform/platform.dart';
import 'package:test/test.dart';

int _testId = 0;

List<String> get testDescriptions => ['test${++_testId}'];

// FileSystem context
abstract class FileSystemTestContext {
  PlatformContext? get platform;

  // The file system used
  FileSystem get fs;

  // The path to use for testing
  String get outPath => fs.path.joinAll(testDescriptions);

  Future<Directory> prepare() async {
    final dir = fs.directory(outPath);
    try {
      await dir.delete(recursive: true);
    } on FileSystemException catch (e) {
      //print(e);
      try {
        expect(e.status, FileSystemException.statusNotFound);
      } catch (te) {
        // devPrint('delete exception $e');
        expect(e.status, FileSystemException.statusAccessError);
      }
    }
    await dir.create(recursive: true);
    return dir.absolute;
  }
}

abstract class IdbFileSystemTestContext extends FileSystemTestContext {
  @override
  PlatformContext? platform;

  FileSystemIdb get rawFsIdb;

  @override
  IdbFileSystem get fs => rawFsIdb;

  @override
  String toString() => 'IdbFsTestContext($fs)';
}

final MemoryFileSystemTestContext memoryFileSystemTestContext =
    MemoryFileSystemTestContext();

class MemoryFileSystemTestContext extends IdbFileSystemTestContext {
  @override
  FileSystemIdb rawFsIdb = newFileSystemMemory() as FileSystemIdb;

  MemoryFileSystemTestContext();
}

class MemoryFileSystemTestContextWithOptions
    extends FileSystemTestContextIdbWithOptions {
  MemoryFileSystemTestContextWithOptions({required super.options});

  @override
  final IdbFileSystem rawFsIdb = newFileSystemMemory() as IdbFileSystem;
}

abstract class FileSystemTestContextIdbWithOptions
    extends IdbFileSystemTestContext {
  final FileSystemIdbOptions options;

  FileSystemTestContextIdbWithOptions({required this.options});

  @override
  IdbFileSystem get fs =>
      rawFsIdb.withIdbOptions(options: options) as FileSystemIdb;
}

void devPrintJson(Map json) {
  print(const JsonEncoder.withIndent('  ').convert(json));
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

String jsonPretty(dynamic json) {
  if (json is String) {
    json = jsonDecode(json);
  }
  return const JsonEncoder.withIndent('  ').convert(json);
}
