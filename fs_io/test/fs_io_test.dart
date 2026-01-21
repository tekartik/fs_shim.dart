@TestOn('vm')
library;

import 'package:path/path.dart';
import 'package:tekartik_fs_io/fs_io.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

class FileSystemTestContextIo extends FileSystemTestContext
    with FileSystemTestContextMixin {
  @override
  final PlatformContext platform = platformContextIo;

  @override
  bool get supportsFileContentStream => true;
  @override
  FileSystem fs = fileSystem; // Needed for initialization (supportsLink)
  FileSystemTestContextIo() {
    basePath = join('.dart_tool', 'tekartik_fs_io', 'test');
  }
}

FileSystemTestContextIo fileSystemTestContextIo = FileSystemTestContextIo();

void main() {
  group('io', () {
    defineTests(fileSystemTestContextIo);
  });
}
