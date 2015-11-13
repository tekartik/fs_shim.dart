library tekartik_fs_shim.test.test_common_io;

// basically same as the io runner but with extra output
export 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_fs_shim/fs_io.dart';
import 'test_common.dart';
import 'dart:mirrors';
import 'package:platform_context/context.dart';
import 'package:platform_context/context_io.dart';

final IoFileSystemTestContext ioFileSystemContext =
    new IoFileSystemTestContext();

class IoFileSystemTestContext extends FileSystemTestContext {
  final PlatformContext platform = ioPlatformContext;
  final IoFileSystem fs = new IoFileSystem();
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
String get testOutTopPath => join(dirname(dirname(testScriptPath)), "test_out");
String get testOutPath => join(testOutTopPath, joinAll(testDescriptions));
