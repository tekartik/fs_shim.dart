library fs_shim.test.test_common_io;

// basically same as the io runner but with extra output
import 'dart:io';

import 'package:fs_shim/src/io/io_file_system.dart';
import 'package:path/path.dart' as p;

import 'multiplatform/platform.dart';
import 'test_common.dart';

export 'package:test/test.dart';

final IoFileSystemTestContext ioFileSystemTestContext =
    IoFileSystemTestContext();

class IoFileSystemTestContext extends FileSystemTestContext {
  @override
  final PlatformContext platform = PlatformContextIo()
    ..isIoMacOS = Platform.isMacOS
    ..isIoWindows = Platform.isWindows;
  @override
  final FileSystemIo fs = FileSystemIo();
  String? outTopPath;

  IoFileSystemTestContext() {
    outTopPath = testOutTopPath;
  }

  @override
  String get outPath => fs.path.join(outTopPath!, super.outPath);
}

String get testOutTopPath => p.join('.dart_tool', 'fs_shim', 'test');

String get testOutPath => p.join(testOutTopPath, p.joinAll(testDescriptions));
