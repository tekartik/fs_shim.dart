# tekartik_fs_io

The `dart:io` [fs_shim](https://pub.dev/packages/fs_shim) file system as one
variable, `fileSystem` (`fileSystemIo` of fs_shim), for the Dart VM and
Flutter mobile and desktop. It also runs the shared fs_shim suite
(`tekartik_fs_test`) on io and on the IndexedDB file system over sembast io.

## Getting started

Not on pub.dev. The types come from fs_shim:

```yaml
dependencies:
  fs_shim: ">=2.7.1"
  tekartik_fs_io:
    git:
      url: https://github.com/tekartik/fs_shim.dart
      path: fs_io
```

```dart
import 'package:tekartik_fs_io/fs_io.dart';

Future<void> main() async {
  final dir = fileSystem.directory(
    fileSystem.path.join('.dart_tool', 'fs_io_example'),
  );
  final file = fileSystem.file(fileSystem.path.join(dir.path, 'hello.txt'));
  await file.create(recursive: true);
  await file.writeAsString('Hello');
  print('${file.path}: ${await file.readAsString()}');
}
```

VM and Flutter native only: the import reaches `dart:io`, a web build does
not compile. Shared code takes a `FileSystem` parameter, or uses fs_shim's
`fileSystemDefault` (io on the VM, IndexedDB on the web); tests can use
`newFileSystemMemory()` (`package:fs_shim/fs_memory.dart`).

Example: [example/example.dart](example/example.dart). Tests: `dart test`.
More: the `tekartik-fs-io-setup` skill.
