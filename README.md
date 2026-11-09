# fs_shim.dart

A portable file system API for Dart and Flutter: `File`, `Directory` and `Link`
(an asynchronous subset of `dart:io`) behind a `FileSystem` object, running on
io (Dart VM, Flutter mobile and desktop), in the browser (IndexedDB or OPFS)
and in memory.

The package is [`fs_shim`](https://pub.dev/packages/fs_shim), in
[`fs/`](fs): see its [README](fs/README.md) to get started.

```sh
dart pub add fs_shim
```

```dart
import 'package:fs_shim/fs_shim.dart';

Future<void> main() async {
  final fs = fileSystemMemory; // or fileSystemDefault: io, IndexedDB on the web
  final file = fs.file('/dir/hello.txt');
  await file.create(recursive: true);
  await file.writeAsString('Hello world!');
  print(await file.readAsString());
}
```

The other folders are support packages of this repository: shared test suites
run against every implementation (`fs_test`), the io and browser test runners
(`fs_io`, `fs_browser`) and a Flutter test app (`packages_flutter`). The node
implementation is `tekartik_fs_node` in
[tekartik/common_node.dart](https://github.com/tekartik/common_node.dart).
