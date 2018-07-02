library fs_shim.test.test_common_io;

// basically same as the io runner but with extra output
import 'package:fs_shim/src/io/io_file_system.dart';
import 'package:path/path.dart';
import 'package:platform_context/context.dart';
import 'package:platform_context/context_io.dart';

import 'test_common.dart';

export 'package:dev_test/test.dart';

final IoFileSystemTestContext ioFileSystemTestContext =
    new IoFileSystemTestContext();

class IoFileSystemTestContext extends FileSystemTestContext {
  @override
  final PlatformContext platform = ioPlatformContext;
  @override
  final FileSystemIo fs = new FileSystemIo();
  String outTopPath;

  IoFileSystemTestContext() {
    outTopPath = testOutTopPath;
  }

  @override
  String get outPath => join(outTopPath, super.outPath);
}

String get testOutTopPath => join(".dart_tool", "fs_shim", "test");

String get testOutPath => join(testOutTopPath, joinAll(testDescriptions));
