@TestOn('browser')
// ignore_for_file: implementation_imports
library;

import 'dart:js_interop';

import 'package:fs_shim/fs_opfs_web.dart';
import 'package:fs_shim/src/opfs/fs_opfs_web.dart';
import 'package:fs_shim/src/opfs/opfs_interop.dart';
import 'package:test/test.dart';

/// Directory (in the OPFS) holding the test files.
const _dirName = 'file_handles_test';

/// Get a `FileSystemFileHandle` on a file of the OPFS (created if needed),
/// simulating a handle obtained from `window.showOpenFilePicker()` or
/// `window.showSaveFilePicker()`.
Future<FileSystemOpfsWebFileHandle> getTestFileHandle(
  String dirName,
  String fileName,
) async {
  final opfsRoot = await opfsNavigator.storage.getDirectory().toDart;
  final dir = await opfsRoot
      .getDirectoryHandle(dirName, OpfsGetDirectoryOptions(create: true))
      .toDart;
  final handle = await dir
      .getFileHandle(fileName, OpfsGetFileOptions(create: true))
      .toDart;
  return FileSystemOpfsWebFileHandleWeb(handle);
}

void main() {
  group('opfs_file_handles', () {
    setUp(() async {
      final dir = fileSystemOpfsWeb.directory('/$_dirName');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('read/write/stat through the File interface', () async {
      final fs = FileSystemOpfsWeb.withFileHandles([
        await getTestFileHandle(_dirName, 'file.txt'),
      ]);
      expect(fs.name, 'opfs');
      expect(fs, isNot(fileSystemOpfsWeb));
      expect(fileSystemOpfsWeb, isNot(fs));
      expect(fs, fs);

      final file = fs.file('/file.txt');
      expect(await file.exists(), isTrue);
      expect(await fs.type('/file.txt'), FileSystemEntityType.file);
      expect(await fs.type('/other.txt'), FileSystemEntityType.notFound);
      expect(await fs.type('/'), FileSystemEntityType.directory);

      await file.writeAsString('hello');
      expect(await file.readAsString(), 'hello');
      // Written through the handle, visible at the real OPFS location.
      expect(
        await fileSystemOpfsWeb.file('/$_dirName/file.txt').readAsString(),
        'hello',
      );

      await file.writeAsString(' world', mode: FileMode.append);
      expect(await file.readAsString(), 'hello world');

      final stat = await file.stat();
      expect(stat.type, FileSystemEntityType.file);
      expect(stat.size, 'hello world'.length);
      expect(
        (await fs.file('/other.txt').stat()).type,
        FileSystemEntityType.notFound,
      );
      expect(
        (await fs.directory('/').stat()).type,
        FileSystemEntityType.directory,
      );
    });

    test('list and name deduplication', () async {
      // Two handles with the same name (as picked from different directories).
      final fs = FileSystemOpfsWeb.withFileHandles([
        await getTestFileHandle(_dirName, 'dup.txt'),
        await getTestFileHandle('${_dirName}_other', 'dup.txt'),
        await getTestFileHandle(_dirName, 'file.txt'),
      ]);
      addTearDown(() async {
        await fileSystemOpfsWeb
            .directory('/${_dirName}_other')
            .delete(recursive: true);
      });
      final paths =
          (await fs.directory('/').list().toList())
              .map((entity) => entity.path)
              .toList()
            ..sort();
      expect(paths, ['/dup (1).txt', '/dup.txt', '/file.txt']);

      // The deduplicated name maps to the second handle.
      await fs.file('/dup (1).txt').writeAsString('second');
      expect(
        await fileSystemOpfsWeb
            .file('/${_dirName}_other/dup.txt')
            .readAsString(),
        'second',
      );
      expect(
        await fileSystemOpfsWeb.file('/$_dirName/dup.txt').readAsString(),
        '',
      );
    });

    test('copy between file handles', () async {
      final fs = FileSystemOpfsWeb.withFileHandles([
        await getTestFileHandle(_dirName, 'src.txt'),
        await getTestFileHandle(_dirName, 'dst.txt'),
      ]);
      await fs.file('/src.txt').writeAsString('content');
      await fs.file('/src.txt').copy('/dst.txt');
      expect(await fs.file('/dst.txt').readAsString(), 'content');
    });

    test('unsupported operations', () async {
      final fs = FileSystemOpfsWeb.withFileHandles([
        await getTestFileHandle(_dirName, 'file.txt'),
      ]);
      final file = fs.file('/file.txt');
      await expectLater(file.delete(), throwsUnsupportedError);
      await expectLater(file.rename('/other.txt'), throwsUnsupportedError);
      await expectLater(file.copy('/other.txt'), throwsUnsupportedError);
      await expectLater(fs.file('/other.txt').create(), throwsUnsupportedError);
      await expectLater(fs.directory('/sub').create(), throwsUnsupportedError);
      // Existing entries are left untouched, the root always exists.
      await file.create();
      await fs.directory('/').create();
      // Missing files and sub paths.
      await expectLater(
        fs.file('/other.txt').readAsString(),
        throwsA(isA<FileSystemException>()),
      );
      await expectLater(
        fs.file('/sub/other.txt').writeAsString('test'),
        throwsA(isA<FileSystemException>()),
      );
      await expectLater(
        fs.directory('/sub').list().toList(),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('fileSystemOpfsWebRequestWritePermission', () async {
      final handle = await getTestFileHandle(_dirName, 'file.txt');
      // OPFS handles are always granted.
      expect(await FileSystemOpfsWeb.requestWritePermission(handle), isTrue);
    });
  });
}
