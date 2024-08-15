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
  stdout.writeln('    version: ${Platform.version}');
  stdout.writeln('current dir: ${Directory.current}');
}
