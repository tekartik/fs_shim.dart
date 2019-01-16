// basically same as the io runner but with extra output
import 'package:fs_shim/src/io/io_file_system.dart';
import 'package:path/path.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:tekartik_platform/context.dart';
import 'package:tekartik_platform_io/context_io.dart';

export 'package:dev_test/test.dart';

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
  String outTopPath;

  @override
  String get outPath => join(outTopPath, super.outPath);
}

String get testOutTopPath => join(".dart_tool", "fs_shim", "test_out");

String get testOutPath => join(testOutTopPath, joinAll(testDescriptions));
