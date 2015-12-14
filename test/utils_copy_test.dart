library fs_shim.test.utils_copy_tests;

import 'package:fs_shim/utils/copy.dart';
import 'package:path/path.dart';
import 'package:fs_shim/fs.dart';
import 'test_common.dart';

main() {
  defineTests(memoryFileSystemTestContext);
}

FileSystemTestContext _ctx;
FileSystem get fs => _ctx.fs;

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;
  group('copy', () {
    test('options', () {
      CopyOptions options = recursiveLinkOrCopyNewerOptions;
      expect(options.tryToLinkFile, isTrue);
      expect(options.checkSizeAndModifiedDate, isTrue);
      expect(options.recursive, isTrue);
    });
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

    test('sub_file', () async {
      Directory top = await ctx.prepare();
      Directory srcDir = fs.newDirectory(join(top.path, "dir"));
      Directory dstDir = fs.newDirectory(join(top.path, "dir2"));

      CopyOptions options = new CopyOptions(recursive: true);

      File srcFile = fs.newFile(join(srcDir.path, "file"));

      expect(await copyFileSystemEntity(srcDir, dstDir, options: options), 0);

      await srcFile.create(recursive: true);
      await srcFile.writeAsString("test", flush: true);

      expect(await copyFileSystemEntity(srcDir, dstDir, options: options), 2);
      expect(await copyFileSystemEntity(srcDir, dstDir, options: options), 1);
      expect(
          await copyFileSystemEntity(srcDir, dstDir, options: copyNewerOptions),
          0);

      expect(
          await copyFileSystemEntity(srcDir, dstDir,
              options: recursiveLinkOrCopyNewerOptions),
          1);
      expect(
          await copyFileSystemEntity(srcDir, dstDir,
              options: recursiveLinkOrCopyNewerOptions),
          0);
    });
  });
}
