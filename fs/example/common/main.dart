import 'dart:core' hide print;
import 'dart:core' as core;

import 'package:fs_shim/fs_browser.dart';
import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:fs_shim/src/common/import.dart';

import 'package:idb_shim/idb_client_sembast.dart';
import 'package:path/path.dart' as global_path;
import 'package:sembast/sembast_io.dart';

import 'setup.dart';

var _index = 0;
List<FileSystem> fsList = isRunningAsJavascript
    ? [
        fileSystemWeb,
        getFileSystemWeb(
            options: const FileSystemIdbOptions(pageSize: 16 * 1024)),
        newFileSystemWeb(
            name: 'lfs_options.db',
            options: const FileSystemIdbOptions(pageSize: 16 * 1024)),
        newFileSystemWeb(
            name: 'lfs_options_2.db',
            options: const FileSystemIdbOptions(pageSize: 2))
      ]
    : [
        fileSystemIo,
        newFileSystemIdb(IdbFactorySembast(
            databaseFactoryIo,
            global_path.join(
                '.dart_tool', 'fs_shim_example', 'idb_io_${++_index}'))),
        newFileSystemIdb(IdbFactorySembast(
                databaseFactoryIo,
                global_path.join(
                    '.dart_tool', 'fs_shim_example', 'idb_io_${++_index}')))
            .withIdbOptions(
                options: const FileSystemIdbOptions(pageSize: 16 * 1024))
      ];

Future main() async {
  print('Universal running${isRunningAsJavascript ? ' as javascript' : ''}');
  await exampleInit();
  for (var fs in fsList) {
    print('Using file system: $fs');
    var p = fs.path;
    var topPath = p.separator;

    if (!isRunningAsJavascript) {
      if (fs == fileSystemIo) {
        topPath = p.absolute(
            p.normalize(p.join(p.current, '.dart_tool', 'fs_shim_example')));
      }
    }
    topPath = p.join(topPath, 'example_${++_index}');

    // Create a top level directory
    final dir = fs.directory(fs.path.join(topPath, 'dir'));

    print('dir: $dir');

    // delete its content
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    // Create it
    // await dir.create(recursive: true);

    // and a file in it
    final file = fs.file(p.join(dir.path, 'file'));

    // create a file
    await file.create(recursive: true);
    await file.writeAsString('Hello world!');

    // read a file
    print('file: $file');
    print('content: ${await file.readAsString()}');

    // use a file link if supported
    if (fs.supportsFileLink) {
      final link = fs.link(p.join(dir.path, 'link'));
      await link.create(file.path);
      print('link: $link target ${await link.target()}');
      print('content: ${await fs.file(link.path).readAsString()}');
    }

    // list dir content
    print('Listing dir: $dir');
    for (var fse
        in await dir.list(recursive: true, followLinks: true).toList()) {
      print('  found: $fse');
    }
  }
}
