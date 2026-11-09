// ignore_for_file: avoid_print

import 'package:fs_shim/fs_shim.dart';

/// Works on any file system: io, memory, IndexedDB or OPFS.
Future<void> demo(FileSystem fs) async {
  // Paths are built with the file system's own path context.
  final dir = fs.directory(fs.path.join(fs.currentDirectory.path, 'demo'));
  final file = dir.file('file.txt');

  // Create the file and its parent directory, write then read it.
  await file.create(recursive: true);
  await file.writeAsString('Hello world!');
  print('   file: $file');
  print('content: ${await file.readAsString()}');
  print('   stat: ${await file.stat()}');

  // Use a file link if supported (not on Windows io, not on OPFS).
  if (fs.supportsFileLink) {
    final link = dir.link('link');
    await link.create(file.path);
    print('   link: ${await fs.file(link.path).readAsString()}');
  }

  // List the directory content.
  print(await dir.list(recursive: true, followLinks: true).toList());

  await dir.delete(recursive: true);
}

Future<void> main() async {
  // In memory here; fileSystemDefault would use io (or IndexedDB on the web).
  await demo(fileSystemMemory);
}
