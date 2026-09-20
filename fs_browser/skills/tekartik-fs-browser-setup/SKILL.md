---
name: tekartik-fs-browser-setup
description: >-
  Use when a web app needs an fs_shim FileSystem in the browser through
  tekartik_fs_browser: package:tekartik_fs_browser/fs_browser.dart
  (fileSystemWeb, getFileSystemWeb, newFileSystemWeb, FileSystemIdbOptions
  page size, IndexedDB) and package:tekartik_fs_browser/fs_opfs_web.dart
  (fileSystemOpfsWeb, FileSystemOpfsWeb.withRootHandle / withFileHandles,
  showDirectoryPicker, showOpenFilePicker, showSaveFilePicker,
  requestWritePermission), the git dependency block on fs_shim.dart/fs_browser,
  and browser tests with tekartik_fs_test (FileSystemTestContextIdbWeb,
  platformContextBrowser, defineFsTests, build_runner test -p chrome).
---

# tekartik_fs_browser: fs_shim in the browser (tekartik_fs_browser)

`tekartik_fs_browser` is the browser counterpart of `tekartik_fs_io`: two
libraries that re-export the web file systems of `fs_shim`, an IndexedDB one
(`fs_browser.dart`) and an OPFS one (`fs_opfs_web.dart`). It adds no API of
its own, so anything true of `package:fs_shim/fs_browser.dart` is true here.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_fs_browser:
      git:
        url: https://github.com/tekartik/fs_shim.dart
        path: fs_browser
  ```
  Both libraries re-export `package:fs_shim/fs.dart`, so `FileSystem`, `File`,
  `Directory`, `FileSystemException` and friends come with the import; a
  separate `fs_shim` dependency is only needed for the other entry points
  (`fs_memory.dart`, `utils/...`).
* Imports:
  * `package:tekartik_fs_browser/fs_browser.dart` = `fileSystemWeb`,
    `getFileSystemWeb({options})`, `newFileSystemWeb({required name, options})`
    plus `fs_idb.dart` (`FileSystemIdbOptions`, `newFileSystemIdb`).
  * `package:tekartik_fs_browser/fs_opfs_web.dart` = `fileSystemOpfsWeb`,
    `FileSystemOpfsWeb` and the File System Access picker types.
  Both are safe to *import* anywhere (the implementation is behind a
  conditional import); only *using* an instance off the browser throws.
* IndexedDB (`fs_browser.dart`): `fileSystemWeb` is the shared `lfs.db`
  database with no paging — best for whole file `readAsString`/`writeAsString`,
  poor for random access. `getFileSystemWeb(options:
  FileSystemIdbOptions.pageDefault)` gives the same database with 16 KiB pages;
  `newFileSystemWeb(name: 'other.db', options: ...)` opens a separate database.
  `FileSystemIdbOptions(pageSize:)`, `.noPage` and `.pageDefault` are the
  available options. Storage is bounded by the browser IndexedDB quota; links
  and random access are supported.
* OPFS (`fs_opfs_web.dart`): `fileSystemOpfsWeb` is the per origin Origin
  Private File System (`fs.name == 'opfs'`), better for large or binary files,
  but `supportsLink` and `supportsRandomAccess` are `false`.
  `FileSystemOpfsWeb.withRootHandle(handle)` roots a file system at a
  directory handle from `FileSystemOpfsWeb.showDirectoryPicker([options])` or
  `storageGetDirectory()`; `FileSystemOpfsWeb.withFileHandles(handles)`
  exposes files picked with `showOpenFilePicker`/`showSaveFilePicker` at
  `/<name>` (fixed tree: no create, delete or rename). The pickers are
  Chromium-only, must run from a user gesture and throw when cancelled;
  `FileSystemOpfsWeb.requestWritePermission(handle)` upgrades a read-only
  handle, and `FileSystemOpfsWebShowDirectoryPickerOptions.modeReadWrite`
  asks for a writable directory upfront.
* Write application code against `FileSystem` and choose the instance in one
  place. For a single code base that also runs on the VM, take the file system
  as a parameter (or use `fileSystemDefault` from `package:fs_shim/fs_shim.dart`,
  which is the IndexedDB one on the web) and depend on `tekartik_fs_io` for
  the io side. The `fs-shim-platforms` skill of `fs_shim` compares all the
  implementations.
* Testing: browser tests are `@TestOn('browser')` and run with
  `dart test -p chrome`, or `dart run build_runner test -- -p chrome test/web`
  when the package also needs `build_web_compilers`/`build_test` (add them and
  `test` to `dev_dependencies`). The shared conformance suite lives in
  `tekartik_fs_test` (same repo, `path: fs_test`): `defineFsTests(ctx)` from
  `package:tekartik_fs_test/fs_test.dart` with a `FileSystemTestContext`.
  `FileSystemTestContextIdbWeb(options: ...)` from
  `package:tekartik_fs_test/fs_test_web.dart` is the ready made IndexedDB
  context; for OPFS, mix `FileSystemTestContextMixin` over `fileSystemOpfsWeb`
  and set `platform = platformContextBrowser`
  (`package:tekartik_fs_test/test_common.dart`). `ctx.sandbox(path: '/root')`
  reruns the suite in a sub-directory.
* Demo pages (pickers) are built with `dart run build_runner serve example:8080`
  with a `build.yaml` listing `example/**.dart` and `test/web/**.dart` in
  `build_web_compilers|entrypoint`.

## Examples

### IndexedDB file system, default and paged

```dart
import 'package:tekartik_fs_browser/fs_browser.dart';

/// Shared `lfs.db`, no paging: fast whole file read/write.
final FileSystem fs = fileSystemWeb;

/// Same database, 16 KiB pages: better for openRead/openWrite.
final FileSystem pagedFs = getFileSystemWeb(
  options: FileSystemIdbOptions.pageDefault,
);

/// A separate database with a custom page size.
final FileSystem cacheFs = newFileSystemWeb(
  name: 'cache.db',
  options: const FileSystemIdbOptions(pageSize: 64 * 1024),
);

Future<void> saveNote(String name, String content) async {
  final file = fs.file('/notes/$name');
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}
```

### OPFS for bigger files

```dart
import 'dart:typed_data';

import 'package:tekartik_fs_browser/fs_opfs_web.dart';

Future<void> main() async {
  final fs = fileSystemOpfsWeb;
  final file = fs.file('/downloads/data.bin');
  await file.parent.create(recursive: true);
  final data = Uint8List.fromList(List<int>.generate(1024, (i) => i % 256));
  await file.writeAsBytes(data);
  print('${fs.name} ${await file.stat()}');
  await for (final entity in fs.directory('/downloads').list()) {
    print(entity.path);
  }
}
```

### Pick a local directory and browse it (Chromium, user gesture)

```dart
import 'package:tekartik_fs_browser/fs_opfs_web.dart';
import 'package:web/web.dart' as web;

void main() {
  final button = web.document.querySelector('#pick') as web.HTMLButtonElement;
  button.onClick.listen((_) async {
    final FileSystemOpfsWebDirectoryHandle handle;
    try {
      handle = await FileSystemOpfsWeb.showDirectoryPicker(
        const FileSystemOpfsWebShowDirectoryPickerOptions(
          id: 'project',
          mode: FileSystemOpfsWebShowDirectoryPickerOptions.modeReadWrite,
        ),
      );
    } catch (e) {
      print('cancelled or unsupported ($e)');
      return;
    }
    final fs = FileSystemOpfsWeb.withRootHandle(handle);
    for (final entity in await fs.directory('/').list().toList()) {
      print('${entity.path} ${await entity.stat()}');
    }
  });
}
```

### Read files picked with the open file picker

```dart
import 'package:tekartik_fs_browser/fs_opfs_web.dart';

Future<List<String>> readPickedTextFiles() async {
  final handles = await FileSystemOpfsWeb.showOpenFilePicker(
    const FileSystemOpfsWebShowOpenFilePickerOptions(
      multiple: true,
      types: [
        FileSystemOpfsWebFilePickerAcceptType(
          description: 'Text files',
          accept: {
            'text/plain': ['.txt', '.md'],
          },
        ),
      ],
    ),
  );
  final fs = FileSystemOpfsWeb.withFileHandles(handles);
  final contents = <String>[];
  await for (final entity in fs.directory('/').list()) {
    contents.add(await fs.file(entity.path).readAsString());
  }
  return contents;
}
```

### Run the shared fs_shim suite in the browser

```dart
@TestOn('browser')
library;

import 'package:tekartik_fs_browser/fs_browser.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/fs_test_web.dart';
import 'package:test/test.dart';

void main() {
  for (final options in [
    FileSystemIdbOptions.noPage,
    FileSystemIdbOptions.pageDefault,
  ]) {
    group('web_${options.pageSize}', () {
      final ctx = FileSystemTestContextIdbWeb(options: options);
      defineFsTests(ctx);
      group('sandbox', () => defineFsTests(ctx.sandbox(path: '/root')));
    });
  }
}
```

### OPFS test context

```dart
@TestOn('browser')
library;

import 'package:tekartik_fs_browser/fs_opfs_web.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

class FileSystemTestContextOpfs with FileSystemTestContextMixin {
  @override
  final FileSystem fs = fileSystemOpfsWeb;
  @override
  PlatformContext? platform;

  FileSystemTestContextOpfs() {
    platform = platformContextBrowser;
  }
}

void main() {
  group('opfs', () {
    test('capabilities', () {
      expect(fileSystemOpfsWeb.name, 'opfs');
      expect(fileSystemOpfsWeb.supportsRandomAccess, isFalse);
    });
    defineFsTests(FileSystemTestContextOpfs());
  });
}
```

## Common mistakes

* Touching `fileSystemWeb` or `fileSystemOpfsWeb` in a VM test: they throw;
  use `newFileSystemMemory()` from `package:fs_shim/fs_memory.dart` instead,
  which runs the same IndexedDB implementation in memory.
* Calling a picker outside a click handler, or on a non-Chromium browser.
* Expecting links or `file.open()` random access on OPFS.
* Streaming large files from `fileSystemWeb` without asking for
  `FileSystemIdbOptions.pageDefault`.
* Writing browser tests without `@TestOn('browser')` or without a chrome
  platform in `dart_test.yaml`.
