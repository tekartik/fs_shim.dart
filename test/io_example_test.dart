@TestOn("vm")
import 'test_common_io.dart';
import 'package:path/path.dart';

/// io_example_test.dart
/// io_example_fs_shim_test.dart
/// This file must be the same besides the import above
import 'dart:io';

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

      var sink = file.openWrite();
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
        expect(entity, new isInstanceOf<File>());
      }).asFuture();

      File file2 = await file.copy(join(dir.path, "file2"));
      expect(await file2.readAsString(), "test");
    });
  });
}
