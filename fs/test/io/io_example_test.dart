@TestOn('vm')
library tekartik_fs.test.io_example_test;

/// io_example_test.dart
/// io_example_fs_shim_test.dart
/// This file must be the same besides the import above
import 'dart:io';

import 'package:path/path.dart';

import '../test_common_io.dart';

/// io_example_fs_shim_test.dart
/// This file must be the same besides the import above

/// io_example_test.dart
/// io_example_fs_shim_test.dart
/// This file must be the same besides the import above
// ignore_for_file: avoid_slow_async_io

const String groupName = 'io_example';

void main() {
  group(groupName, () {
    //testOutTopPath
    test('sample1', () async {
      final dir = Directory(testOutPath);
      try {
        await dir.delete(recursive: true);
      } on FileSystemException catch (_) {}
      await dir.create(recursive: true);
      expect(await dir.exists(), isTrue);
      expect(await FileSystemEntity.isDirectory(dir.path), isTrue);

      expect(dir.absolute.isAbsolute, isTrue);

      final filePath = join(dir.path, 'file');
      final file = File(filePath);
      expect(await FileSystemEntity.isFile(file.path), isFalse);
      expect(file.absolute.isAbsolute, isTrue);

      // file mode
      var sink = file.openWrite(mode: FileMode.write);
      sink.add('test'.codeUnits);
      await sink.close();
      expect(await FileSystemEntity.isFile(file.path), isTrue);

      var stream = file.openRead();
      final content = <int>[];
      await stream.listen((List<int> data) {
        content.addAll(data);
      }).asFuture<void>();
      expect(content, 'test'.codeUnits);

      await dir.list().listen((FileSystemEntity entity) {
        expect(entity.path, filePath);
        expect(entity, const TypeMatcher<File>());
      }).asFuture<void>();

      final file2 = await file.copy(join(dir.path, 'file2'));
      expect(await file2.readAsString(), 'test');

      // stat
      final stat = await file.stat();
      expect(stat.size, greaterThan(3));

      // error
      try {
        await File(join(dir.path, 't', 'o', 'o', 'deep'))
            .create(recursive: false);
        fail('should fail');
      } on FileSystemException catch (e) {
        final osError = e.osError!;
        expect(osError.errorCode, isNotNull);
      }

      // file entity type
      expect(
          await FileSystemEntity.type(file2.path), FileSystemEntityType.file);
    });
  });
}
