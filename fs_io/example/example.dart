// ignore_for_file: avoid_print

import 'package:tekartik_fs_io/fs_io.dart';

/// Writes then reads a file through the io file system of tekartik_fs_io.
Future<void> main() async {
  final dir = fileSystem.directory(
    fileSystem.path.join('.dart_tool', 'fs_io_example'),
  );
  final file = fileSystem.file(fileSystem.path.join(dir.path, 'hello.txt'));
  await file.create(recursive: true);
  await file.writeAsString('Hello');
  print('${file.path}: ${await file.readAsString()}');
  await for (final entity in dir.list()) {
    print('${entity.path} ${(await entity.stat()).type}');
  }
}
