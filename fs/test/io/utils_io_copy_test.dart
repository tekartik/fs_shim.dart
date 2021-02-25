@TestOn('vm')
import 'dart:io';
import 'dart:io' as io;

import 'package:test/test.dart';
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
      final top = unwrapIoDirectory(await ctx.prepare());
      final src = childDirectory(top, 'src');
      final dst = childDirectory(top, 'dst');
      await writeString(childFile(src, 'file'), 'test');

      await copyDirectory(src, dst);
      expect(await readString(childFile(dst, 'file')), 'test');

      final files = await copyDirectoryListFiles(src);
      expect(files, hasLength(1));
      expect(relative(files[0].path, from: src.path), 'file');
    });

    test('file', () async {
      final top = unwrapIoDirectory(await ctx.prepare());
      final srcFile = childFile(top, 'file');
      final dstFile = childFile(top, 'file2');

      try {
        expect(await copyFile(srcFile, dstFile), dstFile);
        fail('should fail');
      } on ArgumentError catch (_) {}

      await srcFile.writeAsString('test', flush: true);

      expect(await copyFile(srcFile, dstFile), dstFile);

      expect(await dstFile.exists(), isTrue);
      expect(await dstFile.readAsString(), 'test');
    });

    String formatModeInt(int mode) {
      return mode.toRadixString(8);
    }

    var fileStatModeOtherExecute = 0x01;
    var fileStatModeGroupExecute = 0x08;
    var fileStatModeUserExecute = 0x40;
    bool isExecutable(int mode) {
      return ((fileStatModeGroupExecute |
                  fileStatModeOtherExecute |
                  fileStatModeUserExecute) &
              mode) !=
          0;
    }

    test('unix executable', () async {
      expect(1.toRadixString(8), '1');
      expect(fileStatModeOtherExecute.toRadixString(8), '1');

      expect(8.toRadixString(8), '10');
      expect(fileStatModeGroupExecute.toRadixString(8), '10');
      expect(64.toRadixString(8), '100');
      expect(fileStatModeUserExecute.toRadixString(8), '100');
      if (Platform.isLinux) {
        final top = unwrapIoDirectory(await ctx.prepare());
        final srcFile = childFile(top, 'file');
        final dstFile = childFile(top, 'file2');

        var file = io.File('test/io/src/current_dir');
        print(file.statSync());
        var stat = file.statSync();
        var mode = stat.mode;
        expect(isExecutable(mode), isTrue);
        print('mode: ${formatModeInt(mode)} 0x${mode.toRadixString(16)}');
        await file.copy(srcFile.path);
        expect(await copyFile(srcFile, dstFile), dstFile);

        print(srcFile);
        stat = srcFile.statSync();
        mode = stat.mode;
        expect(isExecutable(mode), isTrue);
        print('mode: ${formatModeInt(mode)}');
        print(dstFile);
        stat = dstFile.statSync();
        mode = stat.mode;
        print('mode: ${formatModeInt(mode)}');
        expect(isExecutable(mode), isTrue);
      }
    });

    test('top_source_node', () {
      // just check the export
      // ignore: unnecessary_statements
      TopSourceNode;
    });

    test('delete', () async {
      final top = unwrapIoDirectory(await ctx.prepare());
      final file = childFile(top, 'file');
      await writeString(file, 'test');
      expect(await file.exists(), isTrue);
      await deleteFile(file);
      expect(await file.exists(), isFalse);
    });
  });
}
