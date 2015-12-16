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
  group('copy_class', () {
    test('TopEntity', () async {
      // fsCopyDebug = true;
      Directory top = await ctx.prepare();
      TopEntity entity = topEntityPath(fs, top.path);
      expect(entity.parts, []);
      expect(entity.basename, '');
      expect(entity.sub, '');
      expect(entity.top, top.path);
      expect(entity.path, top.path);
    });

    test('CopyEntity', () async {
      // fsCopyDebug = true;
      Directory top = await ctx.prepare();
      TopEntity topEntity = topEntityPath(fs, top.path);
      CopyEntity entity = new CopyEntity(topEntity, "entity");
      expect(entity.parent, topEntity);
      expect(entity.basename, "entity");
      expect(entity.parts, ["entity"]);
      expect(entity.sub, "entity");
      expect(entity.top, top.path);
      expect(entity.path, join(top.path, "entity"));
    });

    test('CopyEntity_sub', () async {
      // fsCopyDebug = true;
      Directory top = await ctx.prepare();
      TopEntity topEntity = topEntityPath(fs, top.path);
      CopyEntity entity = new CopyEntity(topEntity, join("entity", "sub"));
      expect(entity.parent, topEntity);
      expect(entity.basename, "sub");
      expect(entity.parts, ["entity", "sub"]);
      expect(entity.sub, join("entity", "sub"));
      expect(entity.top, top.path);
      expect(entity.path, join(top.path, "entity", "sub"));
    });

    test('CopyEntity_child', () async {
      // fsCopyDebug = true;
      Directory top = await ctx.prepare();
      TopEntity topEntity = fsTopEntity(top);
      CopyEntity entity = new CopyEntity(topEntity, "entity");
      CopyEntity subEntity = new CopyEntity(entity, "sub");
      expect(subEntity.parent, entity);
      expect(subEntity.basename, "sub");
      expect(subEntity.parts, ["entity", "sub"]);
      expect(subEntity.sub, join("entity", "sub"));
      expect(subEntity.top, top.path);
      expect(subEntity.path, join(top.path, "entity", "sub"));
    });

    test('TopCopy', () async {
      // fsCopyDebug = true;
      Directory top = await ctx.prepare();
      Directory src = childDirectory(top, "src");
      Directory dst = childDirectory(top, "dst");
      await writeString(childFile(src, "file"), "test");

      TopCopy copy = new TopCopy(fsTopEntity(src), fsTopEntity(dst));
      expect(copy.src.path, src.path);
      expect(copy.dst.path, dst.path);
      expect(copy.options, isNotNull);
      //await copy.run();
    });

    test('ChildCopy', () async {
      // fsCopyDebug = true;
      Directory top = await ctx.prepare();
      Directory src = childDirectory(top, "src");
      Directory dst = childDirectory(top, "dst");
      await writeString(childFile(src, "file"), "test");

      TopCopy copy = new TopCopy(fsTopEntity(src), fsTopEntity(dst));
      ChildCopy childCopy = new ChildCopy(copy, "file");
      await childCopy.run();
    });

    test('ChildCopy_run', () async {
      // fsCopyDebug = true;
      Directory top = await ctx.prepare();
      Directory src = childDirectory(top, "src");
      Directory dst = childDirectory(top, "dst");

      await writeString(childFile(src, "file"), "test");
      TopCopy copy = new TopCopy(fsTopEntity(src), fsTopEntity(dst));
      ChildCopy childCopy = new ChildCopy(copy, "file");
      await childCopy.run();
      expect(await readString(childFile(dst, "file")), "test");
    });

    test('CopyNode_runChilde', () async {
      // fsCopyDebug = true;
      Directory top = await ctx.prepare();
      Directory src = childDirectory(top, "src");
      Directory dst = childDirectory(top, "dst");

      await writeString(childFile(src, "file"), "test");
      TopCopy copy = new TopCopy(fsTopEntity(src), fsTopEntity(dst));

      await copy.runChild("file");
      expect(await readString(childFile(dst, "file")), "test");
    });

    test('TopCopy_run', () async {
      // fsCopyDebug = true;
      Directory top = await ctx.prepare();
      Directory src = childDirectory(top, "src");
      Directory dst = childDirectory(top, "dst");

      await writeString(childFile(src, "file"), "test");
      TopCopy copy = new TopCopy(fsTopEntity(src), fsTopEntity(dst));

      await copy.run();
      expect(await readString(childFile(dst, "file")), "test");
    });
  });
  group('copy_scenarii', () {
    Directory top;
    Directory src;
    Directory dst;

    Future _prepare() async {
      top = await ctx.prepare();
      src = childDirectory(top, "src");
      dst = childDirectory(top, "dst");
    }

    test('exclude', () async {
      await _prepare();
      await writeString(childFile(src, "file1"), "test");
      await writeString(childFile(src, "file2"), "test");
      TopCopy copy = new TopCopy(fsTopEntity(src), fsTopEntity(dst),
          options: new CopyOptions(recursive: true, exclude: ["file1"]));
      await copy.run();
      expect(await entityExists(childFile(dst, "file1")), isFalse);
      expect(await readString(childFile(dst, "file2")), "test");
    });
  });
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

    test('copy_dir_exclude', () async {
      Directory top = await ctx.prepare();
      Directory srcDir = fs.newDirectory(join(top.path, "dir"));
      File srcFile1 = fs.newFile(join(srcDir.path, "file1"));
      File srcFile2 = fs.newFile(join(srcDir.path, "file2"));
      Directory dstDir = fs.newDirectory(join(top.path, "dst"));

      await srcDir.create();
      await srcFile1.writeAsString("test1", flush: true);
      await srcFile2.writeAsString("test2", flush: true);
      expect(
          await copyFileSystemEntity(srcDir, dstDir,
              options: new CopyOptions(recursive: true, exclude: ['file1'])),
          2);

      expect(await dstDir.exists(), isTrue);

      expect(
          await fs.newFile(join(dstDir.path, "file2")).readAsString(), "test2");
      expect(await fs.newFile(join(dstDir.path, "file1")).exists(), isFalse);
      expect(await copyFileSystemEntity(srcDir, dstDir), 0);
    });

    test('copy_dir_exclude_relative', () async {
      // exclude test on purpose to see if it get ejected as it is part of the while file
      Directory top = await ctx.prepare();
      Directory srcDir = fs.newDirectory(join(top.path, "dir"));
      File srcFile1 = fs.newFile(join(srcDir.path, "test"));
      File srcFile2 = fs.newFile(join(srcDir.path, "file2"));
      Directory dstDir = fs.newDirectory(join(top.path, "dst"));

      await srcDir.create();
      await srcFile1.writeAsString("test1", flush: true);
      await srcFile2.writeAsString("test2", flush: true);
      expect(
          await copyFileSystemEntity(srcDir, dstDir,
              options: new CopyOptions(recursive: true, exclude: ['test'])),
          2);

      expect(await dstDir.exists(), isTrue);

      expect(
          await fs.newFile(join(dstDir.path, "file2")).readAsString(), "test2");
      expect(await fs.newFile(join(dstDir.path, "test")).exists(), isFalse);
      expect(await copyFileSystemEntity(srcDir, dstDir), 0);
    });

    test('copy_sub_dir_exclude', () async {
      Directory top = await ctx.prepare();
      Directory srcDir = fs.newDirectory(join(top.path, "dir"));
      Directory subDir = fs.newDirectory(join(srcDir.path, "sub"));
      File srcFile1 = fs.newFile(join(subDir.path, "file1"));
      File srcFile2 = fs.newFile(join(subDir.path, "file2"));
      Directory dstDir = fs.newDirectory(join(top.path, "dst"));

      await subDir.create(recursive: true);
      await srcFile1.writeAsString("test1", flush: true);
      await srcFile2.writeAsString("test2", flush: true);
      expect(
          await copyFileSystemEntity(srcDir, dstDir,
              options:
                  new CopyOptions(recursive: true, exclude: ['sub/file1'])),
          3);

      expect(await dstDir.exists(), isTrue);

      expect(await fs.newFile(join(dstDir.path, "sub", "file2")).readAsString(),
          "test2");
      expect(await fs.newFile(join(dstDir.path, "sub", "file1")).exists(),
          isFalse);
      expect(await copyFileSystemEntity(srcDir, dstDir), 0);
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

        // do it again if file link supported nothing is done
        expect(await copyFileSystemEntity(srcFile, dstFile, options: options),
            fs.supportsFileLink ? 0 : 1);
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

      // copy file and dir
      expect(await copyFileSystemEntity(srcDir, dstDir, options: options), 2);
      // copy file only
      expect(await copyFileSystemEntity(srcDir, dstDir, options: options), 1);
      expect(
          await copyFileSystemEntity(srcDir, dstDir, options: copyNewerOptions),
          0);

      // If no file link, nothing changed
      expect(
          await copyFileSystemEntity(srcDir, dstDir,
              options: recursiveLinkOrCopyNewerOptions),
          fs.supportsFileLink ? 1 : 0);
      expect(
          await copyFileSystemEntity(srcDir, dstDir,
              options: recursiveLinkOrCopyNewerOptions),
          0);
    });
  });
}
