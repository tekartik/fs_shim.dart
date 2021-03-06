@TestOn('vm')
import 'package:dev_test/test.dart';
import 'package:path/path.dart';

import 'package:tekartik_fs_io/fs_io.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:tekartik_platform/context.dart';
import 'package:tekartik_platform_io/context_io.dart';

class FileSystemTestContextIo extends FileSystemTestContext {
  @override
  final PlatformContext platform = platformContextIo;

  @override
  String get outPath => join('.dart_tool', 'tekartik_fs_io', super.outPath);

  @override
  FileSystem fs = fileSystem; // Needed for initialization (supportsLink)
  FileSystemTestContextIo();
}

FileSystemTestContextIo fileSystemTestContextIo = FileSystemTestContextIo();

void main() {
  group('io', () {
    defineTests(fileSystemTestContextIo);
  });
}
