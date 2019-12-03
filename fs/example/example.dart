import 'dart:async';

import 'package:fs_shim/fs_memory.dart';
import 'package:path/path.dart';

Future main() async {
  final fs = newMemoryFileSystem();

  // Create a top level directory
  final dir = fs.directory('/dir');

  // and a file in it
  final file = fs.file(join(dir.path, 'file'));

  // create a file
  await file.create(recursive: true);
  await file.writeAsString('Hello world!');

  // read a file
  print('file: ${await file.readAsString()}');

  // use a file link if supported
  if (fs.supportsFileLink) {
    final link = fs.link(join(dir.path, 'link'));
    await link.create(file.path);

    print('link: ${await fs.file(link.path).readAsString()}');
  }

  // list dir content
  print(await dir.list(recursive: true, followLinks: true).toList());
}
