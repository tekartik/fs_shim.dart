import 'dart:async';

import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';

Future main() async {
  final fs = ioFileSystem;
  // safe place when running from package root
  final dirPath = join(Directory.current.path, 'test_out', 'example', 'dir');

  // Create a top level directory
  // fs.directory('/dir');
  final dir = Directory(dirPath);
  print('dir: $dir');
  // delete its content
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }

  // and a file in it
  // fs.file(join(dir.path, "file"));
  final file = File(join(dir.path, 'file'));

  // create a file
  await file.create(recursive: true);
  await file.writeAsString('Hello world!');

  // read a file
  print('file: ${await file.readAsString()}');

  // use a file link if supported
  if (fs.supportsFileLink) {
    // fs.newLink(join(dir.path, "link"));
    final link = Link(join(dir.path, 'link'));
    await link.create(file.path);

    print('link: ${await File(link.path).readAsString()}');
  }

  // list dir content
  print(await dir.list(recursive: true, followLinks: true).toList());
}
