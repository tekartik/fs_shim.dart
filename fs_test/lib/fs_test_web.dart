import 'package:fs_shim/fs_browser.dart';

import 'test_common.dart';

class FileSystemTestContextIdbWeb extends FileSystemTestContextIdbWithOptions {
  FileSystemTestContextIdbWeb({required super.options});

  @override
  FileSystemIdb get rawFsIdb => fileSystemWeb as FileSystemIdb;
}
