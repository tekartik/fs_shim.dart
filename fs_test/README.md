# fs_shim_test.dart

fs_shim test helper for setting up test context

## Setup

In `pubspec.yaml`:

```yaml
  tekartik_fs_test:
    git:
      url: https://github.com/tekartik/fs_shim.dart
      path: fs_test
      ref: dart3a
    version: '>=0.1.0'
```
## Usage

### any context (io, browser)

```dart
import 'package:tekartik_fs_test/test_common.dart';

FileSystemTestContext ctx = memoryFileSystemTestContext;
```

###  io

See [test/fs_io_test.dart](test/fs_io_test.dart)