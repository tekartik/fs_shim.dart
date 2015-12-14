library fs_shim.test.utils_copy_tests;

import 'package:fs_shim/utils/copy.dart';
import 'package:path/path.dart';
import 'package:fs_shim/fs.dart';
import 'test_common.dart';
import 'package:path/path.dart';

main() {
  defineTests(memoryFileSystemTestContext);
}

FileSystemTestContext _ctx;
FileSystem get fs => _ctx.fs;

final bool _doPrintErr = false;
_printErr(e) {
  if (_doPrintErr) {
    print("${e} ${[e.runtimeType]}");
  }
}

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;
  group('copy_file', () {
    test('copy_dir', () async {
      Directory top = await ctx.prepare();
      Directory srcDir = fs.newDirectory(join(top.path, "dir"));
      Directory dstDir = fs.newDirectory(join(top.path, "dir2"));

      expect(await copyFileSystemEntity(srcDir, dstDir), 0);

      await srcDir.create();

      expect(await copyFileSystemEntity(srcDir, dstDir), 1);

      expect(await dstDir.exists(), isTrue);

      expect(await copyFileSystemEntity(srcDir, dstDir), 0);
    });

    test('copy_file', () async {
      Directory top = await ctx.prepare();
      File srcFile = fs.newFile(join(top.path, "file"));
      File dstFile = fs.newFile(join(top.path, "file2"));

      expect(await copyFileSystemEntity(srcFile, dstFile), 0);

      await srcFile.writeAsString("test", flush: true);

      expect(await copyFileSystemEntity(srcFile, dstFile), 1);

      expect(await dstFile.exists(), isTrue);
      expect(await dstFile.readAsString(), "test");

      // do it again
      expect(await copyFileSystemEntity(srcFile, dstFile), 1);

      // again with option
      expect(
          await copyFileSystemEntity(srcFile, dstFile,
              options: new CopyOptions(checkSizeAndModifiedDate: true)),
          0);

      // delete
      await dstFile.delete();

      // again with option
      expect(
          await copyFileSystemEntity(srcFile, dstFile,
              options: new CopyOptions(checkSizeAndModifiedDate: true)),
          1);
      expect(
          await copyFileSystemEntity(srcFile, dstFile,
              options: new CopyOptions(checkSizeAndModifiedDate: true)),
          0);
    });

    test('copy_link_dir', () async {
      Directory top = await ctx.prepare();
      Directory srcDir = fs.newDirectory(join(top.path, "dir"));
      Link srcLink = fs.newLink(join(top.path, 'link'));
      Directory dstDir = fs.newDirectory(join(top.path, "dir2"));

      expect(await copyFileSystemEntity(srcLink, dstDir), 0);

      await srcLink.create(srcDir.path);

      expect(await copyFileSystemEntity(srcLink, dstDir), 0);

      await srcDir.create();

      expect(await copyFileSystemEntity(srcLink, dstDir), 1);

      expect(await dstDir.exists(), isTrue);

      expect(await copyFileSystemEntity(srcLink, dstDir), 0);
    });

    test('copy_link_file', () async {
      if (fs.supportsFileLink) {
        Directory top = await ctx.prepare();
        File srcFile = fs.newFile(join(top.path, "file"));
        Link srcLink = fs.newLink(join(top.path, 'link'));
        File dstFile = fs.newFile(join(top.path, "file2"));

        expect(await copyFileSystemEntity(srcLink, dstFile), 0);

        await srcLink.create(srcFile.path);

        expect(await copyFileSystemEntity(srcLink, dstFile), 0);

        await srcFile.writeAsString("test", flush: true);

        expect(await copyFileSystemEntity(srcLink, dstFile), 1);

        expect(await dstFile.exists(), isTrue);
        expect(await dstFile.readAsString(), "test");

        // do it again
        expect(await copyFileSystemEntity(srcLink, dstFile), 1);
      }
    });

    test('link_file', () async {
      if (fs.supportsLink) {
        Directory top = await ctx.prepare();
        File srcFile = fs.newFile(join(top.path, "file"));
        File dstFile = fs.newFile(join(top.path, "file2"));

        CopyOptions options = new CopyOptions(tryToLinkFile: true);

        expect(
            await copyFileSystemEntity(srcFile, dstFile, options: options), 0);

        await srcFile.writeAsString("test", flush: true);

        expect(
            await copyFileSystemEntity(srcFile, dstFile, options: options), 1);

        expect(await dstFile.exists(), isTrue);
        expect(await dstFile.readAsString(), "test");

        if (fs.supportsFileLink) {
          expect(await fs.isLink(dstFile.path), isTrue);
        }
        expect(await fs.isFile(dstFile.path), isTrue);

        // do it again
        expect(
            await copyFileSystemEntity(srcFile, dstFile, options: options), 0);
      }
    });

    /*

    test('copy_file_if_newer', () async {
      Directory dir = await ctx.prepare();
      //clearTestOutPath();
      String path1 = join(dir.path, simpleFileName);
      String path2 = join(dir.path, simpleFileName2);
      await fs.newFile(path1).writeAsString(simpleContent, flush: true);

      return copyFileIfNewer(path1, path2).then((int copied) {
        expect(new File(path2).readAsStringSync(), equals(simpleContent));
        expect(copied, equals(1));
        return copyFileIfNewer(path1, path2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('link_or_copy_file_if_newer', () {
      clearTestOutPath();
      String path1 = outDataFilenamePath(simpleFileName);
      String path2 = outDataFilenamePath(simpleFileName2);

      writeStringContentSync(path1, simpleContent);

      return linkOrCopyFileIfNewer(path1, path2).then((int copied) {
        if (!Platform.isWindows) {
          expect(FileSystemEntity.isFileSync(path2), isTrue);
        }
        expect(new File(path2).readAsStringSync(), equals(simpleContent));
        expect(copied, equals(1));
        return linkOrCopyFileIfNewer(path1, path2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('copy_files_if_newer', () {
      clearTestOutPath();
      String sub1 = outDataFilenamePath('sub1');
      String file1 = join(sub1, simpleFileName);
      writeStringContentSync(file1, simpleContent + "1");
      String file2 = join(sub1, simpleFileName2);
      writeStringContentSync(file2, simpleContent + "2");
      String subSub1 = outDataFilenamePath(join('sub1', 'sub1'));
      String file3 = join(subSub1, simpleFileName);
      writeStringContentSync(file3, simpleContent + "3");

      String sub2 = outDataFilenamePath('sub2');

      return copyFilesIfNewer(sub1, sub2).then((int copied) {
        // check sub
        expect(new File(join(sub2, simpleFileName)).readAsStringSync(),
            equals(simpleContent + "1"));
        expect(new File(join(sub2, simpleFileName2)).readAsStringSync(),
            equals(simpleContent + "2"));

        // and subSub
        expect(new File(join(sub2, 'sub1', simpleFileName)).readAsStringSync(),
            equals(simpleContent + "3"));
        return copyFilesIfNewer(sub1, sub2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('link_or_copy_if_newer_file', () {
      clearTestOutPath();
      String path1 = outDataFilenamePath(simpleFileName);
      String path2 = outDataFilenamePath(simpleFileName2);
      writeStringContentSync(path1, simpleContent);

      return linkOrCopyIfNewer(path1, path2).then((int copied) {
        expect(new File(path2).readAsStringSync(), equals(simpleContent));
        expect(copied, equals(1));
        return linkOrCopyIfNewer(path1, path2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('link_or_copy_if_newer_dir', () {
      clearTestOutPath();
      String sub1 = outDataFilenamePath('sub1');
      String file1 = join(sub1, simpleFileName);
      writeStringContentSync(file1, simpleContent + "1");

      String sub2 = outDataFilenamePath('sub2');

      return linkOrCopyIfNewer(sub1, sub2).then((int copied) {
        expect(copied, equals(1));
        // check sub
        expect(new File(join(sub2, simpleFileName)).readAsStringSync(),
            equals(simpleContent + "1"));

        return linkOrCopyIfNewer(sub1, sub2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('deployEntityIfNewer', () async {
      clearTestOutPath();
      String sub1 = outDataFilenamePath('sub1');
      String file1 = join(sub1, simpleFileName);
      writeStringContentSync(file1, simpleContent + "1");
      String file2 = join(sub1, simpleFileName2);
      writeStringContentSync(file2, simpleContent + "2");

      String sub2 = outDataFilenamePath('sub2');

      await deployEntitiesIfNewer(
          sub1, sub2, [simpleFileName, simpleFileName2]);
      expect(new File(join(sub2, simpleFileName)).readAsStringSync(),
          equals(simpleContent + "1"));

      int copied = await deployEntitiesIfNewer(
          sub1, sub2, [simpleFileName, simpleFileName2]);
      expect(copied, equals(0));
    });
  });

  group('symlink', () {
    // new way to link a dir (work on linux/windows
    test('link_dir', () async {
      clearTestOutPath();
      String sub1 = outDataFilenamePath('sub1');
      String file1 = join(sub1, simpleFileName);
      writeStringContentSync(file1, simpleContent);

      String sub2 = outDataFilenamePath('sub2');
      await linkDir(sub1, sub2).then((count) async {
        expect(FileSystemEntity.isLinkSync(sub2), isTrue);
        if (!Platform.isWindows) {
          expect(FileSystemEntity.isDirectorySync(sub2), isTrue);
        }
        expect(count, equals(1));

        // 2nd time nothing is done
        await linkDir(sub1, sub2).then((count) {
          expect(count, equals(0));
        });
      });
    });

    test('create file symlink', () async {
      clearTestOutPath();
      // file symlink not supported on windows
      if (Platform.isWindows) {
        return null;
      }
      String path1 = outDataFilenamePath(simpleFileName);
      String path2 = outDataFilenamePath(simpleFileName2);
      writeStringContentSync(path1, simpleContent);

      await linkFile(path1, path2).then((int result) {
        expect(result, 1);
        expect(new File(path2).readAsStringSync(), equals(simpleContent));
      });
    });
//
//    test('create dir symlink', () {
//      if (Platform.isWindows) {
//        return null;
//      }
//
//      Directory inDir = new Directory(scriptDirPath).parent;
//      Directory outDir = outDataDir;
//
//      return fu.createSymlink(inDir, outDir, 'packages').then((int result) {
//        expect(fu.file(outDir, 'packages/browser/dart.js').existsSync(), isTrue);
//
//      });
//    });
//
//
//
//
//    });
*/
  });
}
