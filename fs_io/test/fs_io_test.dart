@TestOn('vm')
import 'package:path/path.dart';
import 'package:tekartik_fs_io/fs_io.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';

class FileSystemTestContextIo extends FileSystemTestContext {
  @override
  final PlatformContext platform = platformContextIo;

  @override
  FileSystem fs = fileSystem; // Needed for initialization (supportsLink)
  FileSystemTestContextIo();

  var basePath = join('.dart_tool', 'tekartik_fs_io', 'test');
  // The path to use for testing
  @override
  String get outPath => fs.path.joinAll([basePath, ...testDescriptions]);
}

FileSystemTestContextIo fileSystemTestContextIo = FileSystemTestContextIo();

void main() {
  group('io', () {
    defineTests(fileSystemTestContextIo);
  });
}
