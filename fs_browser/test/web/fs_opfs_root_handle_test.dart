@TestOn('browser')
// ignore_for_file: implementation_imports
library;

import 'dart:js_interop';

import 'package:fs_shim/fs_opfs_web.dart';
import 'package:fs_shim/src/opfs/fs_opfs_web.dart' as web;
import 'package:fs_shim/src/opfs/opfs_file_system.dart';
import 'package:fs_shim/src/opfs/opfs_interop.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

/// Directory (in the OPFS) used as the custom root.
const _rootDirName = 'custom_root';

/// Get a `FileSystemDirectoryHandle` on a sub directory of the OPFS root,
/// simulating a handle obtained from `window.showDirectoryPicker()`.
Future<OpfsDirectoryHandle> getTestRootHandle() async {
  final opfsRoot = await opfsNavigator.storage.getDirectory().toDart;
  return (await opfsRoot
      .getDirectoryHandle(_rootDirName, OpfsGetDirectoryOptions(create: true))
      .toDart);
}

/// Test context for a file system rooted at a custom directory handle.
class FileSystemTestContextOpfsRootHandle with FileSystemTestContextMixin {
  @override
  final FileSystem fs = FileSystemOpfsImpl(
    rootHandleProvider: getTestRootHandle,
  );

  FileSystemTestContextOpfsRootHandle() {
    platform = platformContextBrowser;
  }

  @override
  PlatformContext? platform;

  @override
  String toString() => 'OpfsRootHandleFsTestContext($fs)';
}

final fileSystemTestContextOpfsRootHandle =
    FileSystemTestContextOpfsRootHandle();

void main() {
  group('opfs_root_handle', () {
    test('FileSystemOpfsWeb.withRootHandle', () async {
      final fs = FileSystemOpfsWeb.withRootHandle(
        web.FileSystemOpfsWebDirectoryHandleWeb(await getTestRootHandle()),
      );
      expect(fs.name, 'opfs');
      expect(fs, isNot(fileSystemOpfsWeb));
      expect(fileSystemOpfsWeb, fileSystemOpfsWeb);
      expect(fs, fs);

      // Written at the custom root, visible under [_rootDirName] in the OPFS.
      final file = fs.file('/file.txt');
      await file.writeAsString('hello');
      expect(await file.readAsString(), 'hello');
      expect(
        await fileSystemOpfsWeb.file('/$_rootDirName/file.txt').readAsString(),
        'hello',
      );
      await file.delete();
      expect(
        await fileSystemOpfsWeb.file('/$_rootDirName/file.txt').exists(),
        isFalse,
      );
    });
    defineTests(fileSystemTestContextOpfsRootHandle);
  });
}
