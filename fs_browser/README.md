# tekartik_fs_browser

The [fs_shim](https://pub.dev/packages/fs_shim) file systems of the browser
in one package: `fs_browser.dart` (IndexedDB) and `fs_opfs_web.dart` (Origin
Private File System and the File System Access pickers). It adds no API: the
two libraries re-export `package:fs_shim/fs_browser.dart` and
`package:fs_shim/fs_opfs_web.dart`. It also runs the shared fs_shim suite
(`tekartik_fs_test`) in Chrome.

## Getting started

Not on pub.dev:

```yaml
dependencies:
  tekartik_fs_browser:
    git:
      url: https://github.com/tekartik/fs_shim.dart
      path: fs_browser
```

```dart
import 'package:tekartik_fs_browser/fs_browser.dart';

Future<void> main() async {
  // IndexedDB database `lfs.db`, 256 KiB pages.
  final fs = fileSystemWeb;
  final file = fs.file('/notes/hello.txt');
  await file.parent.create(recursive: true);
  await file.writeAsString('Hello');
  print(await file.readAsString());
}
```

Web only (dart2js and dart2wasm): importing is safe everywhere, using
`fileSystemWeb` or `fileSystemOpfsWeb` on the VM throws. On the VM use
`fileSystemIo` (`tekartik_fs_io`) or `newFileSystemMemory()`.

## What to use

* `fileSystemWeb`: IndexedDB, links supported, 256 KiB pages (whole file
  reads and writes, streams, random access).
* `fileSystemWebNoPaging`: the same database, one record per file (the
  default up to fs_shim 2.7, whole file reads and writes only);
  `getFileSystemWeb(options: ...)` another page size;
  `newFileSystemWeb(name: 'other.db')`: another database.
* `fileSystemOpfsWeb` (`fs_opfs_web.dart`): the OPFS, faster for big files, no
  links, no random access. `FileSystemOpfsWeb.withRootHandle(handle)` on a
  directory picked with `FileSystemOpfsWeb.showDirectoryPicker()` (Chromium,
  from a user gesture).

Examples (pickers, handle saved in sdb): [example/README.md](example/README.md).
Tests: `dart test -p chrome` (see `test/web`). More: the
`tekartik-fs-browser-setup` skill.
