library fs_shim.test.test_common_io;

// basically same as the io runner but with extra output
import 'dart:mirrors';

import 'package:fs_shim/src/io/io_file_system.dart';
import 'package:path/path.dart';
import 'package:platform_context/context.dart';
import 'package:platform_context/context_io.dart';

import 'test_common.dart';

export 'package:dev_test/test.dart';

final IoFileSystemTestContext ioFileSystemTestContext =
    new IoFileSystemTestContext();

class IoFileSystemTestContext extends FileSystemTestContext {
  final PlatformContext platform = ioPlatformContext;
  final FileSystemIo fs = new FileSystemIo();
  String outTopPath;

  IoFileSystemTestContext() {
    outTopPath = testOutTopPath;
  }

  String get outPath => join(outTopPath, super.outPath);
}

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;

String get testOutTopPath =>
    join(dirname(dirname(testScriptPath)), ".dart_tool", "fs_shim", "test_out");

String get testOutPath => join(testOutTopPath, joinAll(testDescriptions));
