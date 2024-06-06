library;

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_memory.dart';

import 'fs_idb_test.dart';
import 'test_common.dart';

void main() {
  group('memory', () {
    void defineAllIdbTests(IdbFileSystemTestContext ctx) {
      group('options: ${ctx.fs.idbOptions} ', () {
        defineIdbTests(ctx);
      });
    }

    group('pageSize: null twice', () {
      defineAllIdbTests(MemoryFileSystemTestContext());
      /*
      defineAllIdbTests(MemoryFileSystemTestContext(
          options: const FileSystemIdbOptions(pageSize: 16 * 1024)));
      defineAllIdbTests(MemoryFileSystemTestContext(
          options: const FileSystemIdbOptions(pageSize: 2)));
      defineAllIdbTests(MemoryFileSystemTestContext(
          options: const FileSystemIdbOptions(pageSize: 4)));
      defineAllIdbTests(MemoryFileSystemTestContext(
          options: const FileSystemIdbOptions(pageSize: 1024)));*/
    });

    group('fs', () {
      var fs = memoryFileSystemTestContext.fs;
      test('supportRandomAccess', () {
        expect(fs.supportsRandomAccess, true);
      });
    });
    group('top', () {
      test('writeAsString', () async {
        // direct file write, no preparation
        var fs = newFileSystemMemory();
        await fs.file('file.tmp').writeAsString('context');
      }, skip: false);

      test('createDirectory', () async {
        // direct file write, no preparation
        var fs = newFileSystemMemory();
        await fs.directory('dir.tmp').create();
      }, skip: false);

      test('createDirectoryRecursive', () async {
        // direct file write, no preparation
        var fs = newFileSystemMemory();
        var path = fs.path;
        await fs.directory(path.join('dir.tmp', 'sub')).create(recursive: true);
      }, skip: false);

      test('new', () async {
        var fs = newFileSystemMemory();
        await fs.file('test').writeAsString('test');
        expect(await fs.file('test').readAsString(), 'test');
        fs = newFileSystemMemory();
        try {
          await fs.file('test').readAsString();
          fail('should fail');
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }
      });
    });

    test('new', () async {
      var fs = newFileSystemMemory();
      await fs.file('test').writeAsString('test');
      expect(await fs.file('test').readAsString(), 'test');
      fs = newFileSystemMemory();
      try {
        await fs.file('test').readAsString();
        fail('should fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }
    });
  });
}
