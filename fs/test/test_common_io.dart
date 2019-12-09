library fs_shim.test.test_common_io;

// basically same as the io runner but with extra output
import 'dart:io';

import 'package:fs_shim/src/io/io_file_system.dart';
import 'package:path/path.dart';

import 'multiplatform/platform.dart';
import 'test_common.dart';

export 'package:dev_test/test.dart';

final IoFileSystemTestContext ioFileSystemTestContext =
    IoFileSystemTestContext();

class IoFileSystemTestContext extends FileSystemTestContext {
  @override
  final PlatformContext platform = PlatformContextIo()
    ..isIoMacOS = Platform.isMacOS
    ..isIoWindows = Platform.isWindows;
  @override
  final FileSystemIo fs = FileSystemIo();
  String outTopPath;

  IoFileSystemTestContext() {
    outTopPath = testOutTopPath;
  }

  @override
  String get outPath => join(outTopPath, super.outPath);
}

String get testOutTopPath => join('.dart_tool', 'fs_shim', 'test');

String get testOutPath => join(testOutTopPath, joinAll(testDescriptions));
