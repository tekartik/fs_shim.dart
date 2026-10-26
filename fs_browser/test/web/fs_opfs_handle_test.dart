@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:fs_shim/fs_opfs_web.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

/// Directory (in the OPFS) holding the test files.
const _dirName = 'handle_test';

void main() {
  group('opfs_handle', () {
    setUp(() async {
      final dir = fileSystemOpfsWeb.directory('/$_dirName');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await fileSystemOpfsWeb
          .file('/$_dirName/file.txt')
          .create(recursive: true);
      await fileSystemOpfsWeb
          .file('/$_dirName/file.txt')
          .writeAsString('hello');
    });

    test('jsObject and fromJsObject', () async {
      final root = await FileSystemOpfsWeb.storageGetDirectory();
      final rootCopy = FileSystemOpfsWebDirectoryHandle.fromJsObject(
        root.jsObject,
      );
      expect(rootCopy.jsObject, same(root.jsObject));
      final fs = FileSystemOpfsWeb.withRootHandle(rootCopy);
      expect(await fs.file('/$_dirName/file.txt').readAsString(), 'hello');
    });

    test('name', () async {
      final root = await FileSystemOpfsWeb.storageGetDirectory();
      expect(root.name, '');

      // A file handle from another interop binding (package:web).
      final webRoot = await web.window.navigator.storage.getDirectory().toDart;
      final webDir = await webRoot.getDirectoryHandle(_dirName).toDart;
      final webFile = await webDir.getFileHandle('file.txt').toDart;
      final file = FileSystemOpfsWebFileHandle.fromJsObject(webFile);
      expect(file.name, 'file.txt');
      final fs = FileSystemOpfsWeb.withFileHandles([file]);
      expect(await fs.file('/${file.name}').readAsString(), 'hello');
    });

    test('permission', () async {
      final root = await FileSystemOpfsWeb.storageGetDirectory();
      // OPFS handles are always granted.
      expect(
        await FileSystemOpfsWeb.queryPermission(root),
        FileSystemOpfsWeb.permissionGranted,
      );
      expect(
        await FileSystemOpfsWeb.queryPermission(
          root,
          mode: FileSystemOpfsWeb.permissionModeReadWrite,
        ),
        FileSystemOpfsWeb.permissionGranted,
      );
      expect(
        await FileSystemOpfsWeb.requestPermission(
          root,
          mode: FileSystemOpfsWeb.permissionModeReadWrite,
        ),
        FileSystemOpfsWeb.permissionGranted,
      );
      expect(await FileSystemOpfsWeb.requestWritePermission(root), isTrue);
    });
  });
}
