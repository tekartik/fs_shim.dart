library fs_shim.test.test_common;

// ignore_for_file: deprecated_member_use
// basically same as the io runner but with extra output

import 'dart:convert';

import 'package:fs_shim/fs_browser.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:test/test.dart';

import 'multiplatform/platform.dart';

export 'dart:async';
export 'dart:convert';

export 'package:fs_shim/src/common/import.dart'
    show devPrint, devWarning, isRunningAsJavascript;
export 'package:fs_shim/utils/copy.dart';
export 'package:fs_shim/utils/entity.dart';
export 'package:fs_shim/utils/glob.dart';
export 'package:fs_shim/utils/part.dart';
export 'package:fs_shim/utils/path.dart';
export 'package:fs_shim/utils/read_write.dart';
export 'package:test/test.dart';

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
  IdbFileSystem get fs;
}

final MemoryFileSystemTestContext memoryFileSystemTestContext =
    MemoryFileSystemTestContext();

class MemoryFileSystemTestContext extends IdbFileSystemTestContext {
  final FileSystemIdbOptions? options;
  @override
  final PlatformContext? platform = null;
  @override
  late final IdbFileSystem fs = () {
    if (debugShowLogs) {
      print('Creating file system $hashCode');
    }
    // IdbFactoryLogger.debugMaxLogCount = devWarning(256);
    var fs = newFileSystemMemory();
    //  if (options != null) {
    //  fs = fs.withWebOptions(options: options!);
    // }
    return fs as IdbFileSystem;
  }();

  MemoryFileSystemTestContext({this.options});
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

bool isIo(FileSystemTestContext ctx) {
  return ctx.platform?.isIo == true;
}

String jsonPretty(dynamic json) {
  if (json is String) {
    json = jsonDecode(json);
  }
  return const JsonEncoder.withIndent('  ').convert(json);
}
