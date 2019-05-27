@TestOn("vm")
import 'dart:io';

import 'package:dev_test/test.dart';
import 'package:fs_shim/fs_io.dart' show unwrapIoDirectory;
import 'package:fs_shim/utils/copy.dart' show TopSourceNode;
import 'package:fs_shim/utils/io/copy.dart';
import 'package:fs_shim/utils/io/entity.dart';
import 'package:fs_shim/utils/io/read_write.dart';
import 'package:path/path.dart';

import '../test_common_io.dart' show ioFileSystemTestContext;

// ignore_for_file: avoid_slow_async_io
String get outPath => ioFileSystemTestContext.outPath;

void main() {
  var ctx = ioFileSystemTestContext;
  group('io_copy', () {
    test('dir', () async {
      // fsCopyDebug = true;
      Directory top = unwrapIoDirectory(await ctx.prepare());
      Directory src = childDirectory(top, "src");
      Directory dst = childDirectory(top, "dst");
      await writeString(childFile(src, "file"), "test");

      await copyDirectory(src, dst);
      expect(await readString(childFile(dst, "file")), "test");

      List<File> files = await copyDirectoryListFiles(src);
      expect(files, hasLength(1));
      expect(relative(files[0].path, from: src.path), "file");
    });

    test('file', () async {
      Directory top = unwrapIoDirectory(await ctx.prepare());
      File srcFile = childFile(top, "file");
      File dstFile = childFile(top, "file2");

      try {
        expect(await copyFile(srcFile, dstFile), dstFile);
        fail('should fail');
      } on ArgumentError catch (_) {}

      await srcFile.writeAsString("test", flush: true);

      expect(await copyFile(srcFile, dstFile), dstFile);

      expect(await dstFile.exists(), isTrue);
      expect(await dstFile.readAsString(), "test");
    });

    test('top_source_node', () {
      // just check the export
      TopSourceNode topSourceNode = TopSourceNode(null);
      expect(topSourceNode, isNotNull);
    });

    test('delete', () async {
      Directory top = unwrapIoDirectory(await ctx.prepare());
      File file = childFile(top, "file");
      await writeString(file, "test");
      expect(await file.exists(), isTrue);
      await deleteFile(file);
      expect(await file.exists(), isFalse);
    });
  });
}
