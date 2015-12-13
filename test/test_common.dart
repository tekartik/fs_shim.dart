library fs_shim.test.test_common;

// basically same as the io runner but with extra output
import 'dart:async';
import 'package:dev_test/test.dart';
export 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:fs_shim/fs.dart';
import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_memory.dart';
import 'dart:convert';
import 'package:platform_context/context.dart';

// FileSystem context
abstract class FileSystemTestContext {
  PlatformContext get platform;
  // The file system used
  FileSystem get fs;
  // The path to use for testing
  String get outPath => joinAll(testDescriptions);

  Future<Directory> prepare() async {
    Directory dir = fs.newDirectory(outPath);
    try {
      await dir.delete(recursive: true);
    } on FileSystemException catch (e) {
      expect(e.status, FileSystemException.statusNotFound);
    }
    await dir.create(recursive: true);
    return dir.absolute;
  }
}

abstract class IdbFileSystemTestContext extends FileSystemTestContext {
  IdbFileSystem get fs;
}

final MemoryFileSystemTestContext memoryFileSystemTestContext =
    new MemoryFileSystemTestContext();

class MemoryFileSystemTestContext extends IdbFileSystemTestContext {
  final PlatformContext platform = null;
  final MemoryFileSystem fs = new MemoryFileSystem();
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
