import 'dart:core' hide print;
import 'dart:core' as core;
import 'dart:html' hide FileSystem, File;

import 'package:fs_shim/fs_browser.dart';
import 'package:fs_shim/fs_idb.dart';
import 'package:path/path.dart';

FileSystem fs = fileSystemIdb;

PreElement? outElement;

void print(msg) {
  outElement = (outElement ?? querySelector('#output') as PreElement);
  outElement!.text = '${outElement!.text}$msg\n';
}

Future main() async {
  // Create a top level directory
  final dir = fs.directory('/dir');

  // delete its content
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }

  // and a file in it
  final file = fs.file(join(dir.path, 'file'));

  // create a file
  await file.create(recursive: true);
  await file.writeAsString('Hello world!');

  // read a file
  print('file: $file');
  print('content: ${await file.readAsString()}');

  // use a file link if supported
  if (fs.supportsFileLink) {
    final link = fs.link(join(dir.path, 'link'));
    await link.create(file.path);

    print('link: $link target ${await link.target()}');
    print('content: ${await fs.file(link.path).readAsString()}');
  }

  // list dir content
  print('Listing dir: $dir');
  for (var fse in await dir.list(recursive: true, followLinks: true).toList()) {
    print('  found: $fse');
  }
}
