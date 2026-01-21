// ignore_for_file: implementation_imports

import 'package:dev_test/test.dart';
import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:fs_shim/src/idb/idb_fs.dart';
import 'package:path/path.dart' as p;
import 'package:tekartik_fs_test/test_common.dart';

int _testId = 0;

List<String> get testDescriptions => ['test${++_testId}'];

extension FsShimFileSystemTestContextExtension on FileSystemTestContext {
  /// Create a sandboxed context
  FileSystemTestContext sandbox({required String path}) {
    return _SandboxedFileSystemTestContext(delegate: this, sandboxPath: path);
  }
}

mixin FileSystemTestContextMixin implements FileSystemTestContext {
  @override
  String? basePath;

  // The path to use for testing
  String get outPath {
    var dir = fs.path.joinAll(testDescriptions);
    if (basePath != null) {
      dir = fs.path.join(basePath!, dir);
    }
    return dir;
  }

  /// Support openRead/openWrite
  /// True by default.
  @override
  bool get supportsFileContentStream => true;

  @override
  p.Context get path => fs.path;

  @override
  Directory get baseDir => fs.directoryWith(path: basePath);
  @override
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

/// FileSystem context
abstract class FileSystemTestContext {
  PlatformContext? get platform;

  /// The file system used
  FileSystem get fs;

  Directory get baseDir;

  String? get basePath;
  p.Context get path;
  Future<Directory> prepare();
  bool get supportsFileContentStream;
}

class _SandboxedFileSystemTestContext with FileSystemTestContextMixin {
  final FileSystemTestContext delegate;
  final String sandboxPath;

  _SandboxedFileSystemTestContext({
    required this.delegate,
    required this.sandboxPath,
  });

  @override
  late final fs = delegate.fs.sandbox(path: sandboxPath);

  @override
  PlatformContext? get platform => delegate.platform;

  @override
  bool get supportsFileContentStream => delegate.supportsFileContentStream;
}

abstract class IdbFileSystemTestContext with FileSystemTestContextMixin {
  @override
  PlatformContext? platform;

  FileSystemIdb get rawFsIdb;

  @override
  IdbFileSystem get fs => rawFsIdb;

  @override
  bool get supportsFileContentStream => true;
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
  // ignore: avoid_print
  print(const JsonEncoder.withIndent('  ').convert(json));
}

bool isIoWindows(FileSystemTestContext ctx) {
  return isIo(ctx) && (ctx.platform as PlatformContextIo).isIoWindows;
}

bool isIoNode(FileSystemTestContext ctx) {
  return isIo(ctx) && (ctx.platform as PlatformContextIo).isIoNode;
}

bool isIoMac(FileSystemTestContext ctx) {
  return isIo(ctx) && (ctx.platform as PlatformContextIo).isIoMacOS;
}

bool isIoLinux(FileSystemTestContext ctx) {
  return isIo(ctx) && (ctx.platform as PlatformContextIo).isIoLinux;
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
