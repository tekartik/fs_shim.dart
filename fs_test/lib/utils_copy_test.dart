library fs_shim.test.utils_copy_tests;

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/utils/copy.dart';
import 'package:fs_shim/utils/src/utils_impl.dart'
    show copyFileSystemEntityImpl;
import 'package:path/path.dart';

import 'test_common.dart';

main() {
  defineTests(memoryFileSystemTestContext);
}

FileSystemTestContext _ctx;
FileSystem get fs => _ctx.fs;

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;
  group('copy', () {
    group('copy_options', () {
      test('include_exclude', () {
        CopyOptions options = recursiveLinkOrCopyNewerOptions;
        expect(options.include, isNull);
        expect(options.exclude, isNull);
        options.include = ['test'];
        expect(options.include, ['test']);
        expect(options.includeGlobs, [new Glob('test')]);
        options.exclude = ['test'];
        expect(options.exclude, ['test']);
        expect(options.excludeGlobs, [new Glob('test')]);

        options = recursiveLinkOrCopyNewerOptions;
        expect(options.include, isNull);
        expect(options.exclude, isNull);
      });
    });
    group('create_delete', () {
      test('create_', () async {
        Directory top = await ctx.prepare();
        Directory dir = childDirectory(top, 'dir');
        expect(await createDirectory(dir), dir);
        expect(await dir.exists(), isTrue);
      });

      test('dir_recursive', () async {
        Directory top = await ctx.prepare();
        Directory dir = childDirectory(top, 'dir');
        Directory sub = childDirectory(dir, 'sub');

        // Ok  by default to create recursively
        expect(await createDirectory(sub), sub);
        expect(await sub.exists(), isTrue);

        // and don't delete so (deleting parent here)
        await deleteDirectory(dir);
        expect(await sub.exists(), isFalse);

        // not recursive
        try {
          expect(
              await createDirectory(sub,
                  options: new CreateOptions()..recursive = false),
              sub);
          fail('should fail');
        } on FileSystemException catch (e) {
          expect(e.status, FileSystemException.statusNotFound);
        }
        expect(await sub.exists(), isFalse);

        await createDirectory(sub,
            options: new CreateOptions()..recursive = true);
        expect(await sub.exists(), isTrue);

        // not recursive - not throwing exception
        await deleteDirectory(dir,
            options: new DeleteOptions()..recursive = false);
        expect(await sub.exists(), isTrue);
      });

      test('file', () async {
        Directory top = await ctx.prepare();
        File file = childFile(top, 'file');
        expect(await createFile(file), file);
        expect(await file.exists(), isTrue);
      });
    });
    group('delete', () {
      test('dir', () async {
        // fsCopyDebug = true;
        Directory top = await ctx.prepare();
        Directory src = childDirectory(top, "src");
        File file = childFile(src, 'file');

        // not exists ok
        await deleteDirectory(src);

        await writeString(file, "test");
        await deleteDirectory(src);
        expect(await file.exists(), isFalse);
      });

      test('file_create', () async {
        Directory top = await ctx.prepare();
        File file = childFile(top, 'file');
        expect(await createFile(file), file);
        expect(await file.exists(), isTrue, reason: "file created");
        await deleteFile(file);
        expect(await file.exists(), isFalse, reason: "file deleted");
        expect(await createFile(file), file);
        await deleteFile(file, options: new DeleteOptions());
        expect(await file.exists(), isFalse, reason: "file deleted again");
        expect(await createFile(file), file);
        await deleteFile(file, options: new DeleteOptions()..create = true);
        expect(await file.exists(), isTrue, reason: "file re-created");
      });

      test('dir_with_content', () async {
        //fsDeleteDebug = true;
        Directory top = await ctx.prepare();
        Directory src = childDirectory(top, "src");
        File file1 = await writeString(childFile(src, "file1"), "test");
        File file2 = await writeString(childFile(src, "file2"), "test");
        await deleteDirectory(src,
            options: new DeleteOptions()..recursive = true);
        expect(await entityExists(file1), isFalse);
        expect(await entityExists(file2), isFalse);
      });

      test('file', () async {
        Directory top = await ctx.prepare();
        File srcFile = fs.newFile(join(top.path, "file"));

        // not exists ok
        await deleteFile(srcFile);

        await srcFile.writeAsString("test", flush: true);

        await deleteFile(srcFile);

        expect(await srcFile.exists(), isFalse);
      });
    });
    group('copy', () {
      test('dir', () async {
        // fsCopyDebug = true;
        Directory top = await ctx.prepare();
        Directory src = childDirectory(top, "src");
        Directory dst = childDirectory(top, "dst");
        await writeString(childFile(src, "file"), "test");

        await copyDirectory(src, dst);
        expect(await readString(childFile(dst, "file")), "test");

        List<File> files = await copyDirectoryListFiles(src);
        expect(files, hasLength(1));
        expect(relative(files[0].path, from: src.path), "file");
      });

      test('dir_delete', () async {
        // fsCopyDebug = true;
        Directory top = await ctx.prepare();
        Directory src = childDirectory(top, "src");
        Directory dst = childDirectory(top, "dst");
        await src.create();
        File dstFile = await createFile(childFile(dst, "file"));

        await copyDirectory(src, dst);
        expect(await dstFile.exists(), isTrue);

        // delete existing
        await copyDirectory(src, dst,
            options: defaultCopyOptions.clone..delete = true);
        expect(await dstFile.exists(), isFalse);

        // delete before copying with delete
        await deleteDirectory(dst);
        await copyDirectory(src, dst,
            options: defaultCopyOptions.clone..delete = true);
      });

      test('copy_file', () async {
        Directory top = await ctx.prepare();
        File srcFile = fs.newFile(join(top.path, "file"));
        File dstFile = fs.newFile(join(top.path, "file2"));

        try {
          expect(await copyFile(srcFile, dstFile), dstFile);
          fail('should fail');
        } on ArgumentError catch (_) {}

        await srcFile.writeAsString("test", flush: true);

        expect(await copyFile(srcFile, dstFile), dstFile);

        expect(await dstFile.exists(), isTrue);
        expect(await dstFile.readAsString(), "test");

        // do it again
        expect(await copyFile(srcFile, dstFile), dstFile);

        // again with option
        expect(
            await copyFile(srcFile, dstFile,
                options: new CopyOptions(checkSizeAndModifiedDate: true)),
            dstFile);

        // delete
        await dstFile.delete();

        // again with option
        expect(
            await copyFile(srcFile, dstFile,
                options: new CopyOptions(checkSizeAndModifiedDate: true)),
            dstFile);
      });

      test('sub_file', () async {
        Directory top = await ctx.prepare();
        Directory srcDir = fs.newDirectory(join(top.path, "dir"));
        Directory dstDir = fs.newDirectory(join(top.path, "dir2"));

        CopyOptions options = defaultCopyOptions;

        File srcFile = fs.newFile(join(srcDir.path, "file"));

        //await copyDirectory(srcDir, dstDir, options: options);

        await srcFile.create(recursive: true);
        await srcFile.writeAsString("test", flush: true);

        // copy file and dir
        expect(await copyDirectory(srcDir, dstDir, options: options), dstDir);
        // copy file only
        expect(await copyDirectory(srcDir, dstDir, options: options), dstDir);

        expect(await copyDirectory(srcDir, dstDir, options: copyNewerOptions),
            dstDir);

        // If no file link, nothing changed
        expect(
            await copyDirectory(srcDir, dstDir,
                options: recursiveLinkOrCopyNewerOptions),
            dstDir);

        List<File> files = await copyDirectoryListFiles(srcDir);
        expect(files, hasLength(1));
        expect(relative(files[0].path, from: srcDir.path), "file");
      });

      group('exclude', () {
        Directory top;
        Directory src;
        Directory dst;

        Future _prepare() async {
          top = await ctx.prepare();
          src = childDirectory(top, "src");
          dst = childDirectory(top, "dst");
        }

        test('copy_exclude_file', () async {
          await _prepare();
          await writeString(childFile(src, "file1"), "test");
          await writeString(childFile(src, "file2"), "test");
          CopyOptions options =
              new CopyOptions(recursive: true, exclude: ["file1"]);
          await copyDirectory(src, dst, options: options);
          expect(await entityExists(childFile(dst, "file1")), isFalse);
          expect(await readString(childFile(dst, "file2")), "test");

          List<File> files =
              await copyDirectoryListFiles(src, options: options);
          expect(files, hasLength(1));
          expect(relative(files[0].path, from: src.path), "file2");
        });

        test('copy_exclude_dir', () async {
          await _prepare();
          await writeString(childFile(src, "file1"), "test");
          await writeString(childFile(src, "file2"), "test");
          await copyDirectory(src, dst,
              options: new CopyOptions(recursive: true, exclude: ["file1/"]));
          expect(await entityExists(childFile(dst, "file1")), isTrue);
          expect(await readString(childFile(dst, "file2")), "test");
        });
      });

      group('include', () {
        Directory top;
        Directory src;
        Directory dst;

        Future _prepare() async {
          top = await ctx.prepare();
          src = childDirectory(top, "src");
          dst = childDirectory(top, "dst");
        }

        test('copy_include_file', () async {
          await _prepare();
          await writeString(childFile(src, "file1"), "test");
          await writeString(childFile(src, "file2"), "test");
          var options = new CopyOptions(recursive: true, include: ["file1"]);
          await copyDirectory(src, dst, options: options);
          expect(await readString(childFile(dst, "file1")), "test");
          expect(await entityExists(childFile(dst, "file2")), isFalse);

          List<File> files =
              await copyDirectoryListFiles(src, options: options);
          expect(files, hasLength(1));
          expect(relative(files[0].path, from: src.path), "file1");
        });

        test('copy_include_dir', () async {
          await _prepare();
          Directory dir1 = childDirectory(src, "dir1");
          await writeString(childFile(dir1, "file1"), "test");
          await writeString(childFile(src, "file2"), "test");
          await copyDirectory(src, dst,
              options: new CopyOptions(recursive: true, include: ["dir1"]));
          expect(
              await readString(childFile(childDirectory(dst, "dir1"), "file1")),
              "test");
          expect(await entityExists(childFile(dst, "file2")), isFalse);
        });
      });
    });

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

      // Running
      test('ChildCopy_run', () async {
        // fsCopyDebug = true;
        Directory top = await ctx.prepare();
        Directory src = childDirectory(top, "src");
        Directory dst = childDirectory(top, "dst");

        await writeString(childFile(src, "file"), "test");
        TopCopy copy = new TopCopy(fsTopEntity(src), fsTopEntity(dst));
        ChildCopy childCopy = new ChildCopy(copy, null, "file");
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

        await copy.runChild(null, "file");
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

        expect(await copyFileSystemEntityImpl(srcDir, dstDir), 0);

        await srcDir.create();

        expect(await copyFileSystemEntityImpl(srcDir, dstDir), 1);

        expect(await dstDir.exists(), isTrue);

        expect(await copyFileSystemEntityImpl(srcDir, dstDir), 0);
      });

      test('copy_file', () async {
        Directory top = await ctx.prepare();
        File srcFile = fs.newFile(join(top.path, "file"));
        File dstFile = fs.newFile(join(top.path, "file2"));

        expect(await copyFileSystemEntityImpl(srcFile, dstFile), 0);

        await srcFile.writeAsString("test", flush: true);

        expect(await copyFileSystemEntityImpl(srcFile, dstFile), 1);

        expect(await dstFile.exists(), isTrue);
        expect(await dstFile.readAsString(), "test");

        // do it again
        expect(await copyFileSystemEntityImpl(srcFile, dstFile), 1);

        // again with option
        expect(
            await copyFileSystemEntityImpl(srcFile, dstFile,
                options: new CopyOptions(checkSizeAndModifiedDate: true)),
            0);

        // delete
        await dstFile.delete();

        // again with option
        expect(
            await copyFileSystemEntityImpl(srcFile, dstFile,
                options: new CopyOptions(checkSizeAndModifiedDate: true)),
            1);
        expect(
            await copyFileSystemEntityImpl(srcFile, dstFile,
                options: new CopyOptions(checkSizeAndModifiedDate: true)),
            0);
      });

      test('copy_link_dir', () async {
        Directory top = await ctx.prepare();
        Directory srcDir = fs.newDirectory(join(top.path, "dir"));
        Link srcLink = fs.newLink(join(top.path, 'link'));
        Directory dstDir = fs.newDirectory(join(top.path, "dir2"));

        expect(await copyFileSystemEntityImpl(srcLink, dstDir), 0);

        await srcLink.create(srcDir.path);

        expect(await copyFileSystemEntityImpl(srcLink, dstDir), 0);

        await srcDir.create();

        expect(await copyFileSystemEntityImpl(srcLink, dstDir), 1);

        expect(await dstDir.exists(), isTrue);

        expect(await copyFileSystemEntityImpl(srcLink, dstDir), 0);
      });

      test('copy_link_file', () async {
        if (fs.supportsFileLink) {
          Directory top = await ctx.prepare();
          File srcFile = fs.newFile(join(top.path, "file"));
          Link srcLink = fs.newLink(join(top.path, 'link'));
          File dstFile = fs.newFile(join(top.path, "file2"));

          expect(await copyFileSystemEntityImpl(srcLink, dstFile), 0);

          await srcLink.create(srcFile.path);

          expect(await copyFileSystemEntityImpl(srcLink, dstFile), 0);

          await srcFile.writeAsString("test", flush: true);

          expect(await copyFileSystemEntityImpl(srcLink, dstFile), 1);

          expect(await dstFile.exists(), isTrue);
          expect(await dstFile.readAsString(), "test");

          // do it again
          expect(await copyFileSystemEntityImpl(srcLink, dstFile), 1);
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
            await copyFileSystemEntityImpl(srcDir, dstDir,
                options: new CopyOptions(recursive: true, exclude: ['file1'])),
            2);

        expect(await dstDir.exists(), isTrue);

        expect(await fs.newFile(join(dstDir.path, "file2")).readAsString(),
            "test2");
        expect(await fs.newFile(join(dstDir.path, "file1")).exists(), isFalse);
        expect(
            await copyFileSystemEntityImpl(srcDir, dstDir,
                options: new CopyOptions(recursive: false)),
            0);
        expect(await copyFileSystemEntityImpl(srcDir, dstDir), 2);
      });

      test('copy_dir_exclude_relative', () async {
        //fsCopyDebug = true;
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
            await copyFileSystemEntityImpl(srcDir, dstDir,
                options: new CopyOptions(recursive: true, exclude: ['test'])),
            2);

        expect(await dstDir.exists(), isTrue);

        expect(await fs.newFile(join(dstDir.path, "file2")).readAsString(),
            "test2");
        expect(await fs.newFile(join(dstDir.path, "test")).exists(), isFalse);
        expect(
            await copyFileSystemEntityImpl(srcDir, dstDir,
                options: new CopyOptions(recursive: false)),
            0);
        expect(await copyFileSystemEntityImpl(srcDir, dstDir), 2);
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
            await copyFileSystemEntityImpl(srcDir, dstDir,
                options:
                    new CopyOptions(recursive: true, exclude: ['sub/file1'])),
            3);

        expect(await dstDir.exists(), isTrue);

        expect(
            await fs.newFile(join(dstDir.path, "sub", "file2")).readAsString(),
            "test2");
        expect(await fs.newFile(join(dstDir.path, "sub", "file1")).exists(),
            isFalse);
        expect(
            await copyFileSystemEntityImpl(srcDir, dstDir,
                options: new CopyOptions(recursive: false)),
            0);
        expect(await copyFileSystemEntityImpl(srcDir, dstDir), 2);
      });

      test('link_file', () async {
        if (fs.supportsLink) {
          Directory top = await ctx.prepare();
          File srcFile = fs.newFile(join(top.path, "file"));
          File dstFile = fs.newFile(join(top.path, "file2"));

          CopyOptions options = new CopyOptions(tryToLinkFile: true);

          expect(
              await copyFileSystemEntityImpl(srcFile, dstFile,
                  options: options),
              0);

          await srcFile.writeAsString("test", flush: true);

          expect(
              await copyFileSystemEntityImpl(srcFile, dstFile,
                  options: options),
              1);

          expect(await dstFile.exists(), isTrue);
          expect(await dstFile.readAsString(), "test");

          if (fs.supportsFileLink) {
            expect(await fs.isLink(dstFile.path), isTrue);
          }
          expect(await fs.isFile(dstFile.path), isTrue);

          // do it again if file link supported nothing is done
          expect(
              await copyFileSystemEntityImpl(srcFile, dstFile,
                  options: options),
              fs.supportsFileLink ? 0 : 1);
        }
      });

      test('sub_file', () async {
        Directory top = await ctx.prepare();
        Directory srcDir = fs.newDirectory(join(top.path, "dir"));
        Directory dstDir = fs.newDirectory(join(top.path, "dir2"));

        CopyOptions options = new CopyOptions(recursive: true);

        File srcFile = fs.newFile(join(srcDir.path, "file"));

        expect(await copyFileSystemEntityImpl(srcDir, dstDir, options: options),
            0);

        await srcFile.create(recursive: true);
        await srcFile.writeAsString("test", flush: true);

        // copy file and dir
        expect(await copyFileSystemEntityImpl(srcDir, dstDir, options: options),
            2);
        // copy file only
        expect(await copyFileSystemEntityImpl(srcDir, dstDir, options: options),
            1);
        expect(
            await copyFileSystemEntityImpl(srcDir, dstDir,
                options: copyNewerOptions),
            0);

        // If no file link, nothing changed
        expect(
            await copyFileSystemEntityImpl(srcDir, dstDir,
                options: recursiveLinkOrCopyNewerOptions),
            fs.supportsFileLink ? 1 : 0);
        expect(
            await copyFileSystemEntityImpl(srcDir, dstDir,
                options: recursiveLinkOrCopyNewerOptions),
            0);
      });
    });
  });
}