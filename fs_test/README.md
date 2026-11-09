# tekartik_fs_test

The shared test suite of [fs_shim](https://pub.dev/packages/fs_shim): every
`FileSystem` implementation (io, memory, IndexedDB with or without pages,
OPFS, sandboxes, ...) runs the same tests, so they all behave like `dart:io`.
It also holds the test contexts and helpers to write new file system tests.

## Getting started

Not on pub.dev. Add it to the `dev_dependencies` of the package that provides
the file system:

```yaml
dev_dependencies:
  test: ">=1.31.0"
  tekartik_fs_test:
    git:
      url: https://github.com/tekartik/fs_shim.dart
      path: fs_test
```

Then one test file runs the whole suite on your file system:

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

class MyFileSystemTestContext extends FileSystemTestContext
    with FileSystemTestContextMixin {
  // Replace by the file system under test.
  @override
  final FileSystem fs = newFileSystemMemory();
  @override
  PlatformContext? platform;
}

void main() {
  group('my_fs', () {
    defineFsTests(MyFileSystemTestContext());
    // Same suite in a sandbox of that file system.
    defineFsTests(MyFileSystemTestContext().sandbox(path: '/root'));
  });
}
```

`dart test` runs it on the VM; a browser file system goes in a
`@TestOn('browser')` file run with `dart test -p chrome`. Ready made contexts:
`memoryFileSystemTestContext`, `FileSystemTestContextIdbWithOptions` (page
sizes), `FileSystemTestContextIdbWeb` (`fs_test_web.dart`).

## Who runs it

| Implementation | Runner |
|---|---|
| memory (IndexedDB on sembast memory), sandboxes | `fs_test/test` |
| io, idb on sembast io (4 page sizes), sandboxes | `fs_io/test` |
| IndexedDB (default, page size 2), OPFS, sandboxes | `fs_browser/test/web` (Chrome) |
| idb_sqflite | `tekartik/fs_shim_test.dart` `fs_idb_sqflite` |
| node | `tekartik/common_node.dart` `fs_node_test` |

## Writing a shared test

* Call `await ctx.prepare()` at the start of each test: a new empty
  directory.
* A test must be able to fail: never put the expectations in a catch all (it
  catches the `TestFailure` of `expect`); catch only the error you tolerate.
* A broken implementation must fail fast: a link loop or a cycle listing must
  be bounded (`take(20)`, `.timeout(...)` on each call, a `timeout:` per test)
  so that it fails instead of filling the memory.
* Guard platform differences with `isIo(ctx)`, `isIoWindows(ctx)`,
  `fs.supportsLink`, `fs.supportsRandomAccess`, not with `Platform`.

More: the `tekartik-fs-test-setup` skill
(`skills/tekartik-fs-test-setup/SKILL.md`).
