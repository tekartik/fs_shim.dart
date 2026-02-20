library;

import 'package:dev_test/test.dart';
// ignore_for_file: unnecessary_import
import 'package:fs_shim/fs.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:fs_shim/utils/src/utils_impl.dart'
    show copyFileSystemEntityImpl;

import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

void defineTests(FileSystemTestContext ctx) {
  var fs = ctx.fs;
  group('copy', () {
    group('api', () {
      // ignore: unnecessary_statements
      TopCopy;
      TopCopy? topCopy;
      // ignore: dead_code
      topCopy?.options;
      // ignore: dead_code
      topCopy?.dst;
      // ignore: dead_code
      topCopy?.src;
      // ignore: dead_code
      topCopy?.id;
      // ignore: unnecessary_statements, dead_code
      topCopy?.run;
      // ignore: unnecessary_statements, dead_code
      topCopy?.runChild;
    });
    group('copy_options', () {
      test('include_exclude', () {
        var options = recursiveLinkOrCopyNewerOptions;
        expect(options.include, isNull);
        expect(options.exclude, isNull);
        options.include = ['test'];
        expect(options.include, ['test']);
        expect(options.includeGlobs, [Glob('test')]);
        options.exclude = ['test'];
        expect(options.exclude, ['test']);
        expect(options.excludeGlobs, [Glob('test')]);

        options = recursiveLinkOrCopyNewerOptions;
        expect(options.include, isNull);
        expect(options.exclude, isNull);
      });
    });
    group('create_delete', () {
      test('create_', () async {
        final top = await ctx.prepare();
        final dir = childDirectory(top, 'dir');
        expect(await createDirectory(dir), dir);
        expect(await dir.exists(), isTrue);
      });

      test('dir_recursive', () async {
        final top = await ctx.prepare();
        final dir = childDirectory(top, 'dir');
        final sub = childDirectory(dir, 'sub');

        // Ok  by default to create recursively
        expect(await createDirectory(sub), sub);
        expect(await sub.exists(), isTrue);

        // and don't delete so (deleting parent here)
        await deleteDirectory(dir);
        expect(await sub.exists(), isFalse);

        // not recursive
        try {
          expect(
            await createDirectory(
              sub,
              options: CreateOptions()..recursive = false,
            ),
            sub,
          );
          fail('should fail');
        } on FileSystemException catch (e) {
          expect(e.status, FileSystemException.statusNotFound);
        }
        expect(await sub.exists(), isFalse);

        await createDirectory(sub, options: CreateOptions()..recursive = true);
        expect(await sub.exists(), isTrue);

        // not recursive - not throwing exception
        await deleteDirectory(dir, options: DeleteOptions()..recursive = false);
        expect(await sub.exists(), isTrue);
      });

      test('file', () async {
        final top = await ctx.prepare();
        final file = childFile(top, 'file');
        expect(await createFile(file), file);
        expect(await file.exists(), isTrue);
      });
    });
    group('delete', () {
      test('dir', () async {
        // fsCopyDebug = true;
        final top = await ctx.prepare();
        final src = childDirectory(top, 'src');
        final file = childFile(src, 'file');

        // not exists ok
        await deleteDirectory(src);

        await writeString(file, 'test');
        await deleteDirectory(src);
        expect(await file.exists(), isFalse);
      });

      test('file_create', () async {
        final top = await ctx.prepare();
        final file = childFile(top, 'file');
        expect(await createFile(file), file);
        expect(await file.exists(), isTrue);
        await deleteFile(file);
        expect(await file.exists(), isFalse);
        expect(await createFile(file), file);
        await deleteFile(file, options: DeleteOptions());
        expect(await file.exists(), isFalse);
        expect(await createFile(file), file);
        await deleteFile(file, options: DeleteOptions()..create = true);
        expect(await file.exists(), isTrue);
      });

      test('dir_with_content', () async {
        //fsDeleteDebug = true;
        final top = await ctx.prepare();
        final src = childDirectory(top, 'src');
        final file1 = await writeString(childFile(src, 'file1'), 'test');

        final file2 = await writeString(childFile(src, 'file2'), 'test');
        await deleteDirectory(src, options: DeleteOptions()..recursive = true);
        expect(await entityExists(file1), isFalse);
        expect(await entityExists(file2), isFalse);
      });

      test('file', () async {
        final top = await ctx.prepare();
        final srcFile = fs.file(fs.path.join(top.path, 'file'));

        // not exists ok
        await deleteFile(srcFile);

        await srcFile.writeAsString('test', flush: true);

        await deleteFile(srcFile);

        expect(await srcFile.exists(), isFalse);
      });
    });
    group('copy', () {
      test('dir', () async {
        // fsCopyDebug = true;
        final top = await ctx.prepare();
        final src = childDirectory(top, 'src');
        final dst = childDirectory(top, 'dst');
        await writeString(childFile(src, 'file'), 'test');

        await copyDirectory(src, dst);
        expect(await readString(childFile(dst, 'file')), 'test');
        final files = await copyDirectoryListFiles(src);
        expect(files, hasLength(1));
        expect(fs.path.relative(files[0].path, from: src.path), 'file');
      });

      test('dir_delete', () async {
        // fsCopyDebug = true;
        final top = await ctx.prepare();
        final src = childDirectory(top, 'src');
        final dst = childDirectory(top, 'dst');
        await src.create();
        final dstFile = await createFile(childFile(dst, 'file'));

        await copyDirectory(src, dst);
        expect(await dstFile.exists(), isTrue);

        // delete existing
        await copyDirectory(
          src,
          dst,
          options: defaultCopyOptions.clone..delete = true,
        );
        expect(await dstFile.exists(), isFalse);

        // delete before copying with delete
        await deleteDirectory(dst);
        await copyDirectory(
          src,
          dst,
          options: defaultCopyOptions.clone..delete = true,
        );
      });

      test('file', () async {
        final top = await ctx.prepare();
        final srcFile = fs.file(fs.path.join(top.path, 'file'));
        final dstFile = fs.file(fs.path.join(top.path, 'file2'));

        try {
          expect(await copyFile(srcFile, dstFile), dstFile);
          fail('should fail');
        } on ArgumentError catch (_) {}

        await srcFile.writeAsString('test', flush: true);

        expect(await copyFile(srcFile, dstFile), dstFile);

        expect(await dstFile.exists(), isTrue);
        expect(await dstFile.readAsString(), 'test');

        // do it again
        expect(await copyFile(srcFile, dstFile), dstFile);

        // again with option
        expect(
          await copyFile(
            srcFile,
            dstFile,
            options: CopyOptions(checkSizeAndModifiedDate: true),
          ),
          dstFile,
        );

        // delete
        await dstFile.delete();

        // again with option
        expect(
          await copyFile(
            srcFile,
            dstFile,
            options: CopyOptions(checkSizeAndModifiedDate: true),
          ),
          dstFile,
        );
      });

      test('sub_file', () async {
        final top = await ctx.prepare();
        final srcDir = fs.directory(fs.path.join(top.path, 'dir'));
        final dstDir = fs.directory(fs.path.join(top.path, 'dir2'));

        final options = defaultCopyOptions;

        final srcFile = fs.file(fs.path.join(srcDir.path, 'file'));

        //await copyDirectory(srcDir, dstDir, options: options);

        await srcFile.create(recursive: true);
        await srcFile.writeAsString('test', flush: true);

        // copy file and dir
        expect(await copyDirectory(srcDir, dstDir, options: options), dstDir);
        // copy file only
        expect(await copyDirectory(srcDir, dstDir, options: options), dstDir);

        expect(
          await copyDirectory(srcDir, dstDir, options: copyNewerOptions),
          dstDir,
        );

        // If no file link, nothing changed
        expect(
          await copyDirectory(
            srcDir,
            dstDir,
            options: recursiveLinkOrCopyNewerOptions,
          ),
          dstDir,
        );
        final files = await copyDirectoryListFiles(srcDir);
        expect(files, hasLength(1));
        expect(fs.path.relative(files[0].path, from: srcDir.path), 'file');
      });

      group('exclude', () {
        Directory top;
        late Directory src;
        Directory? dst;

        Future prepare() async {
          top = await ctx.prepare();
          src = childDirectory(top, 'src');
          dst = childDirectory(top, 'dst');
        }

        test('copy_exclude_file', () async {
          await prepare();
          await writeString(childFile(src, 'file1'), 'test');
          await writeString(childFile(src, 'file2'), 'test');
          final options = CopyOptions(recursive: true, exclude: ['file1']);
          await copyDirectory(src, dst, options: options);
          expect(await entityExists(childFile(dst!, 'file1')), isFalse);
          expect(await readString(childFile(dst!, 'file2')), 'test');

          final files = await copyDirectoryListFiles(src, options: options);
          expect(files, hasLength(1));
          expect(fs.path.relative(files[0].path, from: src.path), 'file2');
        });

        test('copy_exclude_dir', () async {
          await prepare();
          await writeString(childFile(src, 'file1'), 'test');
          await writeString(childFile(src, 'file2'), 'test');
          await copyDirectory(
            src,
            dst,
            options: CopyOptions(recursive: true, exclude: ['file1/']),
          );
          expect(await entityExists(childFile(dst!, 'file1')), isTrue);
          expect(await readString(childFile(dst!, 'file2')), 'test');
        });
      });

      group('include', () {
        Directory top;
        late Directory src;
        Directory? dst;

        Future prepare() async {
          top = await ctx.prepare();
          src = childDirectory(top, 'src');
          dst = childDirectory(top, 'dst');
        }

        test('copy_include_file', () async {
          await prepare();
          await writeString(childFile(src, 'file1'), 'test');
          await writeString(childFile(src, 'file2'), 'test');
          var options = CopyOptions(recursive: true, include: ['file1']);
          await copyDirectory(src, dst, options: options);
          expect(await readString(childFile(dst!, 'file1')), 'test');
          expect(await entityExists(childFile(dst!, 'file2')), isFalse);

          final files = await copyDirectoryListFiles(src, options: options);
          expect(files, hasLength(1));
          expect(fs.path.relative(files[0].path, from: src.path), 'file1');
        });

        test('copy_include_dir', () async {
          await prepare();
          final dir1 = childDirectory(src, 'dir1');
          await writeString(childFile(dir1, 'file1'), 'test');
          await writeString(childFile(src, 'file2'), 'test');
          await copyDirectory(
            src,
            dst,
            options: CopyOptions(recursive: true, include: ['dir1']),
          );
          expect(
            await readString(childFile(childDirectory(dst!, 'dir1'), 'file1')),
            'test',
          );
          expect(await entityExists(childFile(dst!, 'file2')), isFalse);
        });
      });
    });

    group('copy_class', () {
      test('TopEntity', () async {
        // fsCopyDebug = true;
        final top = await ctx.prepare();
        final entity = topEntityPath(fs, top.path);
        expect(entity.parts, isEmpty);
        expect(entity.basename, '');
        expect(entity.sub, '');
        expect(entity.top, top.path);
        expect(entity.path, top.path);
      });

      test('CopyEntity', () async {
        // fsCopyDebug = true;
        final top = await ctx.prepare();
        final topEntity = topEntityPath(fs, top.path);
        final entity = CopyEntity(topEntity, 'entity');
        expect(entity.parent, topEntity);
        expect(entity.basename, 'entity');
        expect(entity.parts, ['entity']);
        expect(entity.sub, 'entity');
        expect(entity.top, top.path);
        expect(entity.path, fs.path.join(top.path, 'entity'));
      });

      test('CopyEntity_sub', () async {
        // fsCopyDebug = true;
        final top = await ctx.prepare();
        final topEntity = topEntityPath(fs, top.path);
        final entity = CopyEntity(topEntity, fs.path.join('entity', 'sub'));
        expect(entity.parent, topEntity);
        expect(entity.basename, 'sub');
        expect(entity.parts, ['entity', 'sub']);
        expect(entity.sub, fs.path.join('entity', 'sub'));
        expect(entity.top, top.path);
        expect(entity.path, fs.path.join(top.path, 'entity', 'sub'));
      });

      test('CopyEntity_child', () async {
        // fsCopyDebug = true;
        final top = await ctx.prepare();
        final topEntity = fsTopEntity(top);
        final entity = CopyEntity(topEntity, 'entity');
        final subEntity = CopyEntity(entity, 'sub');
        expect(subEntity.parent, entity);
        expect(subEntity.basename, 'sub');
        expect(subEntity.parts, ['entity', 'sub']);
        expect(subEntity.sub, fs.path.join('entity', 'sub'));
        expect(subEntity.top, top.path);
        expect(subEntity.path, fs.path.join(top.path, 'entity', 'sub'));
      });

      test('TopCopy', () async {
        // fsCopyDebug = true;
        final top = await ctx.prepare();
        final src = childDirectory(top, 'src');
        final dst = childDirectory(top, 'dst');
        await writeString(childFile(src, 'file'), 'test');

        final copy = TopCopy(fsTopEntity(src), fsTopEntity(dst));
        expect(copy.src.path, src.path);
        expect(copy.dst!.path, dst.path);
        expect(copy.options, isNotNull);
        //await copy.run();
      });

      // Running
      test('ChildCopy_run', () async {
        final top = await ctx.prepare();
        final src = childDirectory(top, 'src');
        final dst = childDirectory(top, 'dst');

        await writeString(childFile(src, 'file'), 'test');
        final copy = TopCopy(fsTopEntity(src), fsTopEntity(dst));
        final childCopy = ChildCopy(copy, defaultCopyOptions, 'file');
        await childCopy.run();
        expect(await readString(childFile(dst, 'file')), 'test');
      });

      test('CopyNode_runChild', () async {
        // fsCopyDebug = true;
        final top = await ctx.prepare();
        final src = childDirectory(top, 'src');
        final dst = childDirectory(top, 'dst');

        await writeString(childFile(src, 'file'), 'test');
        final copy = TopCopy(fsTopEntity(src), fsTopEntity(dst));

        await copy.runChild(defaultCopyOptions, 'file');
        expect(await readString(childFile(dst, 'file')), 'test');
      });

      test('TopCopy_run', () async {
        // fsCopyDebug = true;
        final top = await ctx.prepare();
        final src = childDirectory(top, 'src');
        final dst = childDirectory(top, 'dst');

        await writeString(childFile(src, 'file'), 'test');
        final copy = TopCopy(fsTopEntity(src), fsTopEntity(dst));

        await copy.run();
        expect(await readString(childFile(dst, 'file')), 'test');
      });
    });
    group('copy_scenarii', () {
      Directory top;
      late Directory src;
      late Directory dst;

      Future prepare() async {
        top = await ctx.prepare();
        src = childDirectory(top, 'src');
        dst = childDirectory(top, 'dst');
      }

      test('exclude', () async {
        await prepare();
        await writeString(childFile(src, 'file1'), 'test');
        await writeString(childFile(src, 'file2'), 'test');
        final copy = TopCopy(
          fsTopEntity(src),
          fsTopEntity(dst),
          options: CopyOptions(recursive: true, exclude: ['file1']),
        );
        await copy.run();
        expect(await entityExists(childFile(dst, 'file1')), isFalse);
        expect(await readString(childFile(dst, 'file2')), 'test');
      });
    });
    group('copy', () {
      test('options', () {
        final options = recursiveLinkOrCopyNewerOptions;
        expect(options.tryToLinkFile, isTrue);
        expect(options.checkSizeAndModifiedDate, isTrue);
        expect(options.recursive, isTrue);
      });
      test('copy_dir', () async {
        final top = await ctx.prepare();
        final srcDir = fs.directory(fs.path.join(top.path, 'dir'));
        final dstDir = fs.directory(fs.path.join(top.path, 'dir2'));

        expect(await copyFileSystemEntityImpl(srcDir, dstDir), 0);

        await srcDir.create();

        expect(await copyFileSystemEntityImpl(srcDir, dstDir), 1);

        expect(await dstDir.exists(), isTrue);

        expect(await copyFileSystemEntityImpl(srcDir, dstDir), 0);
      });

      test('copy_file', () async {
        final top = await ctx.prepare();
        final srcFile = fs.file(fs.path.join(top.path, 'file'));
        final dstFile = fs.file(fs.path.join(top.path, 'file2'));

        expect(await copyFileSystemEntityImpl(srcFile, dstFile), 0);

        await srcFile.writeAsString('test', flush: true);

        expect(await copyFileSystemEntityImpl(srcFile, dstFile), 1);

        expect(await dstFile.exists(), isTrue);
        expect(await dstFile.readAsString(), 'test');

        // do it again
        expect(await copyFileSystemEntityImpl(srcFile, dstFile), 1);

        // again with option
        expect(
          await copyFileSystemEntityImpl(
            srcFile,
            dstFile,
            options: CopyOptions(checkSizeAndModifiedDate: true),
          ),
          0,
        );

        // delete
        await dstFile.delete();

        // again with option
        expect(
          await copyFileSystemEntityImpl(
            srcFile,
            dstFile,
            options: CopyOptions(checkSizeAndModifiedDate: true),
          ),
          1,
        );
        expect(
          await copyFileSystemEntityImpl(
            srcFile,
            dstFile,
            options: CopyOptions(checkSizeAndModifiedDate: true),
          ),
          0,
        );
      });

      test('copy_link_dir', () async {
        if (fs.supportsLink) {
          final top = await ctx.prepare();
          final srcDir = fs.directory(fs.path.join(top.path, 'dir'));
          final srcLink = fs.link(fs.path.join(top.path, 'link'));
          final dstDir = fs.directory(fs.path.join(top.path, 'dir2'));

          expect(await copyFileSystemEntityImpl(srcLink, dstDir), 0);

          await srcLink.create(srcDir.path);

          expect(await copyFileSystemEntityImpl(srcLink, dstDir), 0);

          await srcDir.create();

          if (isIoWindows(ctx)) {
            expect(await copyFileSystemEntityImpl(srcLink, dstDir), 0);
            expect(await dstDir.exists(), isFalse);
          } else {
            expect(await copyFileSystemEntityImpl(srcLink, dstDir), 1);
            expect(await dstDir.exists(), isTrue);
          }

          expect(await copyFileSystemEntityImpl(srcLink, dstDir), 0);
        }
      });

      test('copy_link_file', () async {
        if (fs.supportsFileLink) {
          final top = await ctx.prepare();
          final srcFile = fs.file(fs.path.join(top.path, 'file'));
          final srcLink = fs.link(fs.path.join(top.path, 'link'));
          final dstFile = fs.file(fs.path.join(top.path, 'file2'));

          expect(await copyFileSystemEntityImpl(srcLink, dstFile), 0);

          await srcLink.create(srcFile.path);

          expect(await copyFileSystemEntityImpl(srcLink, dstFile), 0);

          await srcFile.writeAsString('test', flush: true);

          expect(await copyFileSystemEntityImpl(srcLink, dstFile), 1);

          expect(await dstFile.exists(), isTrue);
          expect(await dstFile.readAsString(), 'test');

          // do it again
          expect(await copyFileSystemEntityImpl(srcLink, dstFile), 1);
        }
      });

      test('copy_dir_exclude', () async {
        final top = await ctx.prepare();
        final srcDir = fs.directory(fs.path.join(top.path, 'dir'));
        final srcFile1 = fs.file(fs.path.join(srcDir.path, 'file1'));
        final srcFile2 = fs.file(fs.path.join(srcDir.path, 'file2'));
        final dstDir = fs.directory(fs.path.join(top.path, 'dst'));

        await srcDir.create();
        await srcFile1.writeAsString('test1', flush: true);
        await srcFile2.writeAsString('test2', flush: true);
        expect(
          await copyFileSystemEntityImpl(
            srcDir,
            dstDir,
            options: CopyOptions(recursive: true, exclude: ['file1']),
          ),
          2,
        );

        expect(await dstDir.exists(), isTrue);

        expect(
          await fs.file(fs.path.join(dstDir.path, 'file2')).readAsString(),
          'test2',
        );
        expect(
          await fs.file(fs.path.join(dstDir.path, 'file1')).exists(),
          isFalse,
        );
        expect(
          await copyFileSystemEntityImpl(
            srcDir,
            dstDir,
            options: CopyOptions(recursive: false),
          ),
          0,
        );
        expect(await copyFileSystemEntityImpl(srcDir, dstDir), 2);
      });

      test('copy_dir_exclude_relative', () async {
        //fsCopyDebug = true;
        // exclude test on purpose to see if it get ejected as it is part of the while file
        final top = await ctx.prepare();
        final srcDir = fs.directory(fs.path.join(top.path, 'dir'));
        final srcFile1 = fs.file(fs.path.join(srcDir.path, 'test'));
        final srcFile2 = fs.file(fs.path.join(srcDir.path, 'file2'));
        final dstDir = fs.directory(fs.path.join(top.path, 'dst'));

        await srcDir.create();
        await srcFile1.writeAsString('test1', flush: true);
        await srcFile2.writeAsString('test2', flush: true);
        expect(
          await copyFileSystemEntityImpl(
            srcDir,
            dstDir,
            options: CopyOptions(recursive: true, exclude: ['test']),
          ),
          2,
        );

        expect(await dstDir.exists(), isTrue);

        expect(
          await fs.file(fs.path.join(dstDir.path, 'file2')).readAsString(),
          'test2',
        );
        expect(
          await fs.file(fs.path.join(dstDir.path, 'test')).exists(),
          isFalse,
        );
        expect(
          await copyFileSystemEntityImpl(
            srcDir,
            dstDir,
            options: CopyOptions(recursive: false),
          ),
          0,
        );
        expect(await copyFileSystemEntityImpl(srcDir, dstDir), 2);
      });

      test('copy_sub_dir_exclude', () async {
        final top = await ctx.prepare();
        final srcDir = fs.directory(fs.path.join(top.path, 'dir'));
        final subDir = fs.directory(fs.path.join(srcDir.path, 'sub'));
        final srcFile1 = fs.file(fs.path.join(subDir.path, 'file1'));
        final srcFile2 = fs.file(fs.path.join(subDir.path, 'file2'));
        final dstDir = fs.directory(fs.path.join(top.path, 'dst'));

        await subDir.create(recursive: true);
        await srcFile1.writeAsString('test1', flush: true);
        await srcFile2.writeAsString('test2', flush: true);
        expect(
          await copyFileSystemEntityImpl(
            srcDir,
            dstDir,
            options: CopyOptions(recursive: true, exclude: ['sub/file1']),
          ),
          3,
        );

        expect(await dstDir.exists(), isTrue);

        expect(
          await fs
              .file(fs.path.join(dstDir.path, 'sub', 'file2'))
              .readAsString(),
          'test2',
        );
        expect(
          await fs.file(fs.path.join(dstDir.path, 'sub', 'file1')).exists(),
          isFalse,
        );
        expect(
          await copyFileSystemEntityImpl(
            srcDir,
            dstDir,
            options: CopyOptions(recursive: false),
          ),
          0,
        );
        expect(await copyFileSystemEntityImpl(srcDir, dstDir), 2);
      });

      test('link_file', () async {
        if (fs.supportsLink) {
          final top = await ctx.prepare();
          final srcFile = fs.file(fs.path.join(top.path, 'file'));
          final dstFile = fs.file(fs.path.join(top.path, 'file2'));

          final options = CopyOptions(tryToLinkFile: true);

          expect(
            await copyFileSystemEntityImpl(srcFile, dstFile, options: options),
            0,
          );

          await srcFile.writeAsString('test', flush: true);

          expect(
            await copyFileSystemEntityImpl(srcFile, dstFile, options: options),
            1,
          );

          expect(await dstFile.exists(), isTrue);
          expect(await dstFile.readAsString(), 'test');

          if (fs.supportsFileLink) {
            expect(await fs.isLink(dstFile.path), isTrue);
          }
          expect(await fs.isFile(dstFile.path), isTrue);

          // do it again if file link supported nothing is done
          expect(
            await copyFileSystemEntityImpl(srcFile, dstFile, options: options),
            fs.supportsFileLink ? 0 : 1,
          );
        }
      });

      test('sub_file', () async {
        final top = await ctx.prepare();
        final srcDir = fs.directory(fs.path.join(top.path, 'dir'));
        final dstDir = fs.directory(fs.path.join(top.path, 'dir2'));

        final options = CopyOptions(recursive: true);

        final srcFile = fs.file(fs.path.join(srcDir.path, 'file'));

        expect(
          await copyFileSystemEntityImpl(srcDir, dstDir, options: options),
          0,
        );

        await srcFile.create(recursive: true);
        await srcFile.writeAsString('test', flush: true);

        // copy file and dir
        expect(
          await copyFileSystemEntityImpl(srcDir, dstDir, options: options),
          2,
        );
        // copy file only
        expect(
          await copyFileSystemEntityImpl(srcDir, dstDir, options: options),
          1,
        );
        expect(
          await copyFileSystemEntityImpl(
            srcDir,
            dstDir,
            options: copyNewerOptions,
          ),
          0,
        );

        // If no file link, nothing changed
        expect(
          await copyFileSystemEntityImpl(
            srcDir,
            dstDir,
            options: recursiveLinkOrCopyNewerOptions,
          ),
          fs.supportsFileLink ? 1 : 0,
        );
        expect(
          await copyFileSystemEntityImpl(
            srcDir,
            dstDir,
            options: recursiveLinkOrCopyNewerOptions,
          ),
          0,
        );
      });
    });
  });
  group('cross_fs_copy', () async {
    Future<void> testCopyFile(File file1, File file2) async {
      expect(await file1.exists(), isFalse);
      expect(await file2.exists(), isFalse);
      await expectLater(
        () => copyFile(
          file1,
          file2,
          options: defaultCopyOptions.copyWith(verbose: false),
        ),
        throwsArgumentError,
      );
      expect(await file2.exists(), isFalse);
      await file1.create(recursive: true);
      await file1.writeAsString('hello');
      await copyFile(file1, file2);
      expect(await file2.exists(), isTrue);
      expect(await file2.readAsString(), 'hello');
    }

    test('file to memory', () async {
      var dir = await ctx.prepare();
      var fsMem = newFileSystemMemory();
      var dir1 = dir.directory('dir1');
      var dir2 = fsMem.currentDirectory;
      var src = childFile(dir1, 'src');
      var dst = childFile(dir2, 'dst');
      await testCopyFile(src, dst);
    });

    test('memory to file', () async {
      var dir = await ctx.prepare();
      var fsMem = newFileSystemMemory();
      var dir1 = dir.directory('dir1');
      var dir2 = fsMem.currentDirectory;
      var src = childFile(dir2, 'src');
      var dst = childFile(dir1, 'dst');
      await testCopyFile(src, dst);
    });

    Future<void> testCopyDir(Directory dir1, Directory dir2) async {
      expect(await dir2.exists(), isFalse);
      await expectLater(() => copyDirectory(dir1, dir2), throwsArgumentError);
      expect(await dir2.exists(), isFalse);
      await dir1.create(recursive: true);
      await copyDirectory(dir1, dir2);
      expect(await dir2.exists(), isTrue);
    }

    test('dir to memory', () async {
      var dir = await ctx.prepare();
      var fsMem = newFileSystemMemory();
      var dir1 = dir.directory('src');
      var dir2 = fsMem.currentDirectory;
      await testCopyDir(dir1, dir2);
    });
    test('dir from memory', () async {
      var dir = await ctx.prepare();
      var fsMem = newFileSystemMemory();

      var dir1 = fsMem.currentDirectory;
      var dir2 = dir.directory('dst');

      await testCopyDir(dir1, dir2);
    });

    Future<void> testCopyDirWithLinks(Directory src, Directory dst) async {
      if (src.fs.supportsLink && src.fs.supportsLink) {
        var p1 = src.fs.path;
        var fs1 = src.fs;
        var dir = src.directory(p1.join('sub1', 'dir'));
        var file = dir.file('file1');
        var linkDir = src.link(p1.join('sub2', 'link_dir1'));

        await file.create(recursive: true);
        await file.writeAsString('linked_content');
        await linkDir.create(dir.path, recursive: true);

        expect(await src.directory(dir.path).list().toList(), hasLength(1));
        expect(await src.directory(linkDir.path).list().toList(), hasLength(1));
        expect(
          await src.file(p1.join(linkDir.path, 'file1')).readAsString(),
          'linked_content',
        );
        expect(await fs1.isDirectory(linkDir.path), isTrue);
        expect(await fs1.isLink(linkDir.path), isTrue);
        if (src.fs.supportsFileLink && src.fs.supportsFileLink) {
          var file = src.file(p1.join('sub1', 'file1'));
          var linkFile = src.link(p1.join('sub2', 'link_file1'));
          await file.create(recursive: true);
          await file.writeAsString('linked');
          await linkFile.create(file.path, recursive: true);

          expect(await fs1.isFile(linkFile.path), isTrue);
          expect(await fs1.isLink(linkFile.path), isTrue);
        }
        await copyDirectory(
          src,
          dst,
          options: CopyOptions(verbose: true, recursive: true),
        );

        var p2 = dst.fs.path;
        var fs2 = dst.fs;
        var dstLinkDir = dst.directory(p2.join('sub2', 'link_dir1'));
        expect(await dstLinkDir.file('file1').readAsString(), 'linked_content');
        expect(await fs2.isDirectory(dstLinkDir.path), isTrue);
        expect(await fs2.isLink(dstLinkDir.path), isFalse);
        if (src.fs.supportsFileLink && src.fs.supportsFileLink) {
          var dstLinkFile = dst.file(p2.join('sub2', 'link_file1'));
          expect(await dstLinkFile.readAsString(), 'linked');
          expect(await fs2.isFile(dstLinkFile.path), isTrue);
          expect(await fs2.isLink(dstLinkFile.path), isFalse);
        }
      }
    }

    test('various to memory', () async {
      var dir = await ctx.prepare();
      var fsMem = newFileSystemMemory();
      var dir1 = dir.directory('src');
      var dir2 = fsMem.currentDirectory;
      await testCopyDirWithLinks(dir1, dir2);
    });
    test('various from memory', () async {
      var dir = await ctx.prepare();
      var fsMem = newFileSystemMemory();

      var dir1 = fsMem.currentDirectory;
      var dir2 = dir.directory('dst');

      await testCopyDirWithLinks(dir1, dir2);
    });
  });
}
