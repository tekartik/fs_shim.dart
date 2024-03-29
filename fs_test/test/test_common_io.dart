// basically same as the io runner but with extra output
import 'package:fs_shim/src/io/io_file_system.dart';
import 'package:path/path.dart';
import 'package:tekartik_fs_test/test_common.dart';

export 'package:test/test.dart';

final FileSystemTestContextIo fileSystemTestContextIo =
    FileSystemTestContextIo();

class FileSystemTestContextIo extends FileSystemTestContext {
  FileSystemTestContextIo() {
    outTopPath = testOutTopPath;
  }

  @override
  final PlatformContext platform = platformContextIo;
  @override
  final FileSystemIo fs = FileSystemIo();
  late String outTopPath;

  // @override
  // @deprecated
  // String get outPath => join(outTopPath, super.outPath);
}

String get testOutTopPath => join('.dart_tool', 'fs_shim', 'test_out');

@Deprecated('No longer used')
String get testOutPath => join(testOutTopPath, joinAll(['out']));
//String get testOutPath => join(testOutTopPath, joinAll(testDescriptions));
