@TestOn("vm")
import 'test_common_io.dart';
import 'package:path/path.dart';

/// io_example_test.dart
/// io_example_fs_shim_test.dart
/// This file must be the same besides the import above
import 'dart:io';
import 'package:dart2_constant/io.dart' as constant;

const String groupName = "io_example";

main() {
  group(groupName, () {
    //testOutTopPath
    test('sample1', () async {
      Directory dir = new Directory(testOutPath);
      try {
        await dir.delete(recursive: true);
      } on FileSystemException catch (_) {}
      await dir.create(recursive: true);
      expect(await dir.exists(), isTrue);
      expect(await FileSystemEntity.isDirectory(dir.path), isTrue);

      expect(dir.absolute.isAbsolute, isTrue);

      String filePath = join(dir.path, "file");
      File file = new File(filePath);
      expect(await FileSystemEntity.isFile(file.path), isFalse);
      expect(file.absolute.isAbsolute, isTrue);

      // file mode
      var sink = file.openWrite(mode: constant.FileMode.write);
      sink.add('test'.codeUnits);
      await sink.close();
      expect(await FileSystemEntity.isFile(file.path), isTrue);

      var stream = file.openRead();
      List<int> content = [];
      await stream.listen((List<int> data) {
        content.addAll(data);
      }).asFuture();
      expect(content, 'test'.codeUnits);

      await dir.list().listen((FileSystemEntity entity) {
        expect(entity.path, filePath);
        expect(entity, const TypeMatcher<File>());
      }).asFuture();

      File file2 = await file.copy(join(dir.path, "file2"));
      expect(await file2.readAsString(), "test");

      // stat
      FileStat stat = await file.stat();
      expect(stat.size, greaterThan(3));

      // error
      try {
        await new File(join(dir.path, 't', 'o', 'o', 'deep'))
            .create(recursive: false);
        fail('should fail');
      } on FileSystemException catch (e) {
        OSError osError = e.osError;
        expect(osError.errorCode, isNotNull);
      }

      // file entity type
      expect(await FileSystemEntity.type(file2.path),
          constant.FileSystemEntityType.file);
    });
  });
}
