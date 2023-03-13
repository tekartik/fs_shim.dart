import 'dart:io'
    hide
        Directory,
        File,
        Link,
        FileSystemEntity,
        FileMode,
        FileStat,
        OSError,
        FileSystemException,
        FileSystemEntityType;

import 'package:fs_shim/fs_shim.dart';

void main() {
  print('    version: ${Platform.version}');
  print('current dir: ${Directory.current}');
}
