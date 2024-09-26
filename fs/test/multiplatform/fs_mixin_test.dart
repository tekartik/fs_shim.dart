library;

import 'package:fs_shim/src/common/fs_mixin.dart';
import 'package:test/test.dart';

class MyFileSystem extends Object with FileSystemMixin {}

class MyFile extends MyFileSystemEntity with FileMixin {}

abstract class MyFileSystemEntity extends Object with FileSystemEntityMixin {}

class MyDirectory extends MyFileSystemEntity with DirectoryMixin {}

void main() {
  group('none', () {
    test('entities', () {
      MyFileSystem();
      MyFile();
      MyDirectory();
    });
  });
}
