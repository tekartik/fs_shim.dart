import 'dart:core' hide print;
import 'dart:core' as core;
import 'dart:html' hide FileSystem, File;

import 'package:fs_shim/fs_memory.dart';
import 'package:path/path.dart';

PreElement outElement;

print(msg) {
  if (outElement == null) {
    outElement = querySelector("#output") as PreElement;
  }
  outElement.text += "${msg}\n";
}

main() async {
  FileSystem fs = newMemoryFileSystem();
  // Create a top level directory
  Directory dir = fs.newDirectory('/dir');

  // delete its content
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }

  // and a file in it
  File file = fs.file(join(dir.path, "file"));

  // create a file
  await file.create(recursive: true);
  await file.writeAsString("Hello world!");

  // read a file
  print('file: ${file}');
  print('content: ${await file.readAsString()}');

  // use a file link if supported
  if (fs.supportsFileLink) {
    Link link = fs.newLink(join(dir.path, "link"));
    await link.create(file.path);

    print('link: ${link} target ${await link.target()}');
    print('content: ${await fs.newFile(link.path).readAsString()}');
  }

  // list dir content
  print('Listing dir: $dir');
  (await dir.list(recursive: true, followLinks: true).toList())
      .forEach((FileSystemEntity fse) {
    print('  found: $fse');
  });
}
