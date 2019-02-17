# fs_shim_test.dart

fs_shim test helper for setting up test context

## Usage

### any context (io, browser)

```dart
import 'package:tekartik_fs_test/test_common.dart';

FileSystemTestContext ctx = memoryFileSystemTestContext;
```

###  io

See [test/fs_io_test.dart](test/fs_io_test.dart)