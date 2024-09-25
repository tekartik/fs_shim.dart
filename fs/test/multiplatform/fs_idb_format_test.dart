library;

import 'dart:typed_data';

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_read.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:fs_shim/src/idb/idb_file_write.dart';
import 'package:fs_shim/src/idb/idb_random_access_file.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'package:idb_shim/utils/idb_import_export.dart';
import 'package:idb_shim/utils/idb_utils.dart';

import 'fs_idb_format_v1_test.dart';
import 'fs_idb_format_v3_test.dart';
import 'fs_src_idb_file_system_storage_test.dart';
import 'test_common.dart';

//import 'test_common.dart';

void main() {
  // if (devWarning(false)) {
  fsIdbMultiFormatGroup(idbFactoryMemory);
  fsIdbFormatGroup(idbFactoryMemory);
  fsIdbFormatGroup(idbFactoryMemory,
      options: const FileSystemIdbOptions(pageSize: 2));
  fsIdbFormatGroup(idbFactoryMemory,
      options: const FileSystemIdbOptions(pageSize: 1024));
  //}
}

var _dbNameIndex = 0;
void fsIdbMultiFormatGroup(idb.IdbFactory idbFactory) {
  group('2 bytes', () {
    late IdbFileSystem fs;
    setUp(() async {
      var dbName = 'idb_format_2_bytes_${_dbNameIndex++}.db';
      await idbFactory.deleteDatabase(dbName);
      fs = IdbFileSystem(idbFactory, dbName,
          options: const FileSystemIdbOptions(pageSize: 2));
    });

    tearDown(() async {
      fs.close();
    });
    test('write pageSize 2 bytes', () async {
      var file = fs.file('write_string.txt');
      var raf = await file.open(mode: FileMode.write) as RandomAccessFileIdb;
      // ignore: invalid_use_of_protected_member
      raf.noAsyncFlush = true;
      await raf.writeString('h');
      expect(raf.accessPosition, 1);
      // expect(await raf.position(), 1);
      expect(await file.readAsString(), '');
      expect(await getPartEntries(fs.database), isEmpty);
      // position does flush...
      expect(await raf.position(), 1);
      expect(await file.readAsString(), 'h');
      //expect(await getPartEntries(fs.database), [{'index': 0, 'file': 2, 'content': [104]}]);
      //await raf.flush();
      expect(await getPartEntries(fs.database), [
        {
          'index': 0,
          'file': 2,
          'content': [104]
        }
      ]);
      expect(await file.readAsString(), 'h');
      await raf.writeString('ello');
      await raf.setPosition(1);

      await raf.close();
    });

    test('writeByte multiple no flush', () async {
      var file = fs.file('write_byte_no_flush.bin');
      var raf = await file.open(mode: FileMode.write) as RandomAccessFileIdb;
      // ignore: invalid_use_of_protected_member
      raf.noAsyncFlush = true;
      await raf.writeByte(1);
      await raf.writeByte(2);
      await raf.writeByte(3);
      await raf.writeByte(4);
      expect(await getPartEntries(fs.database), isEmpty);
      await raf.flush();
      expect(await getPartEntries(fs.database), [
        {
          'index': 0,
          'file': 2,
          'content': [1, 2]
        },
        {
          'index': 1,
          'file': 2,
          'content': [3, 4]
        }
      ]);
      await raf.close();
    });
    test('writeByte multiple auto flush', () async {
      // debugIdbShowLogs = devWarning(true);
      var file = fs.file('write_byte_auto_flush.bin');
      var raf = await file.open(mode: FileMode.write) as RandomAccessFileIdb;
      await raf.writeByte(1);
      await raf.writeByte(2);
      await raf.writeByte(3);
      expect(raf.fileEntity.fileSize, 0);
      while (raf.fileEntity.fileSize == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(await getPartEntries(fs.database), [
        {
          'index': 0,
          'file': 2,
          'content': [1, 2]
        },
        {
          'index': 1,
          'file': 2,
          'content': [3]
        }
      ]);
      await raf.close();
    });

    test('truncate short no flush', () async {
      // debugIdbShowLogs = devWarning(true);
      var file = fs.file('test.txt');
      var raf = await file.open(mode: FileMode.write) as RandomAccessFileIdb;
      // ignore: invalid_use_of_protected_member
      raf.noAsyncFlush = true;
      await raf.doWriteBuffer([1, 2, 3, 4, 5]);
      await raf.truncate(3);
      expect(await getPartEntries(fs.database), [
        {
          'index': 0,
          'file': 2,
          'content': [1, 2]
        },
        {
          'index': 1,
          'file': 2,
          'content': [3, 4]
        },
        {
          'index': 2,
          'file': 2,
          'content': [5]
        }
      ]);
      await raf.close();
      expect(await getPartEntries(fs.database), [
        {
          'index': 0,
          'file': 2,
          'content': [1, 2]
        },
        {
          'index': 1,
          'file': 2,
          'content': [3]
        },
      ]);
    });

    test('read pageSize 2 bytes', () async {
      var file = fs.file('test.txt');
      var raf = await file.open(mode: FileMode.write) as RandomAccessFileIdb;
      await raf.writeString('hello');
      await raf.setPosition(1);

      var stat = raf.stat.clone();
      var buffer = Uint8List(4);
      expect(await raf.readInto(buffer, 1, 3), 2);
      // should read 2 parts
      expect(raf.stat.getCount, stat.getCount + 2);

      await raf.close();
    });
  });
  group('multi format', () {
    test(
        'random access open no page, append pageSize 2 bytes then 4 bytes then 2 bytes',
        () async {
      // debugIdbShowLogs = devWarning(true);
      var dbName = 'multi_format.db';
      await idbFactory.deleteDatabase(dbName);
      var fs = IdbFileSystem(idbFactory, dbName,
          options: FileSystemIdbOptions.noPage);
      var file = fs.file('test.txt');
      var raf = await file.open(mode: FileMode.write) as RandomAccessFileIdb;
      await raf.writeString('hello');
      await raf.close();
      fs.close();
      var db = await idbFactory.open(dbName);
      expect(await getPartEntries(db), isEmpty);
      expect(await getFileEntries(db), [
        {
          'key': 2,
          'value': [104, 101, 108, 108, 111]
        }
      ]);

      fs = IdbFileSystem(idbFactory, dbName,
          options: const FileSystemIdbOptions(pageSize: 2));
      file = fs.file('test.txt');
      raf = await file.open(mode: FileMode.append) as RandomAccessFileIdb;
      await raf.close();
      fs.close();
      db = await idbFactory.open(dbName);
      expect(await getPartEntries(db), [
        {
          'index': 0,
          'file': 2,
          'content': [104, 101]
        },
        {
          'index': 1,
          'file': 2,
          'content': [108, 108]
        },
        {
          'index': 2,
          'file': 2,
          'content': [111]
        },
      ]);

      expect(await getFileEntries(db), isEmpty);
      fs = IdbFileSystem(idbFactory, dbName,
          options: const FileSystemIdbOptions(pageSize: 2));
      file = fs.file('test.txt');
      raf = (await file.open(mode: FileMode.append)) as RandomAccessFileIdb;
      // ignore: invalid_use_of_protected_member
      raf.noAsyncFlush = true;
      await raf.writeString('world');
      expect(await file.readAsString(), 'hello');
      await raf.flush();
      expect(await file.readAsString(), 'helloworld');

      await raf.close();
      expect(await file.readAsString(), 'helloworld');
      fs.close();
      db = await idbFactory.open(dbName);
      expect(await getPartEntries(db), [
        {
          'index': 0,
          'file': 2,
          'content': [104, 101]
        },
        {
          'index': 1,
          'file': 2,
          'content': [108, 108]
        },
        {
          'index': 2,
          'file': 2,
          'content': [111, 119]
        },
        {
          'index': 3,
          'file': 2,
          'content': [111, 114]
        },
        {
          'index': 4,
          'file': 2,
          'content': [108, 100]
        }
      ]);
      fs = IdbFileSystem(idbFactory, dbName,
          options: FileSystemIdbOptions.noPage);
      file = fs.file('test.txt');
      raf = await file.open(mode: FileMode.append) as RandomAccessFileIdb;
      await raf.close();
      expect(await file.readAsString(), 'helloworld');
      fs.close();
      db = await idbFactory.open(dbName);
      expect(await getPartEntries(db), isEmpty);
      expect(await getFileEntries(db), [
        {
          'key': 2,
          'value': [104, 101, 108, 108, 111, 119, 111, 114, 108, 100]
        }
      ]);
    });
    test('stream access open no page, append pageSize 2 bytes', () async {
      // debugIdbShowLogs = devWarning(true);
      var dbName = 'multi_format_stream.db';
      await idbFactory.deleteDatabase(dbName);
      var fs = IdbFileSystem(idbFactory, dbName,
          options: FileSystemIdbOptions.noPage);
      var file = fs.file('test.txt');
      var raf = file.openWrite(mode: FileMode.write);
      raf.add(utf8.encode('hello'));
      await raf.close();
      fs.close();
      var db = await idbFactory.open(dbName);
      expect(await getPartEntries(db), isEmpty);
      expect(await getFileEntries(db), [
        {
          'key': 2,
          'value': [104, 101, 108, 108, 111]
        }
      ]);

      fs = IdbFileSystem(idbFactory, dbName,
          options: const FileSystemIdbOptions(pageSize: 2));
      file = fs.file('test.txt');
      raf = file.openWrite(mode: FileMode.append);
      await raf.close();
      fs.close();
      db = await idbFactory.open(dbName);
      expect(await getPartEntries(db), [
        {
          'index': 0,
          'file': 2,
          'content': [104, 101]
        },
        {
          'index': 1,
          'file': 2,
          'content': [108, 108]
        },
        {
          'index': 2,
          'file': 2,
          'content': [111]
        },
      ]);

      expect(await getFileEntries(db), isEmpty);
      fs = IdbFileSystem(idbFactory, dbName,
          options: const FileSystemIdbOptions(pageSize: 2));
      file = fs.file('test.txt');
      raf = file.openWrite(mode: FileMode.append);
      raf.add(utf8.encode('world'));
      await raf.close();
      expect(await file.readAsString(), 'helloworld');
      fs.close();
      db = await idbFactory.open(dbName);
      expect(await getPartEntries(db), [
        {
          'index': 0,
          'file': 2,
          'content': [104, 101]
        },
        {
          'index': 1,
          'file': 2,
          'content': [108, 108]
        },
        {
          'index': 2,
          'file': 2,
          'content': [111, 119]
        },
        {
          'index': 3,
          'file': 2,
          'content': [111, 114]
        },
        {
          'index': 4,
          'file': 2,
          'content': [108, 100]
        }
      ]);
      fs = IdbFileSystem(idbFactory, dbName,
          options: FileSystemIdbOptions.noPage);
      file = fs.file('test.txt');
      raf = file.openWrite(mode: FileMode.append);
      await raf.close();
      expect(await file.readAsString(), 'helloworld');
      fs.close();
      db = await idbFactory.open(dbName);
      expect(await getPartEntries(db), isEmpty);
      expect(await getFileEntries(db), [
        {
          'key': 2,
          'value': [104, 101, 108, 108, 111, 119, 111, 114, 108, 100]
        }
      ]);
    });
    test('sink access writeBytes', () async {
      // debugIdbShowLogs = devWarning(true);
      var dbName = 'stream_access_write_bytes.db';
      await idbFactory.deleteDatabase(dbName);
      var fs = IdbFileSystem(idbFactory, dbName,
          options: const FileSystemIdbOptions(pageSize: 2));
      var file = fs.file('test.');

      final ctlr = IdbWriteStreamSink(file, FileMode.write);
      ctlr.add([1]);
      ctlr.add([2]);
      ctlr.add([3]);
      ctlr.add([4]);
      ctlr.add([5]);
      expect(ctlr.opened, false);
      while (!ctlr.opened) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      while (ctlr.fileEntity.fileSize == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(await getPartEntries(fs.database), [
        {
          'index': 0,
          'file': 2,
          'content': [1, 2]
        },
        {
          'index': 1,
          'file': 2,
          'content': [3, 4]
        }
      ]);
    });
    test('stream access 2 bytes', () async {
      // debugIdbShowLogs = devWarning(true);
      var dbName = 'stream_access_2.db';
      await idbFactory.deleteDatabase(dbName);
      var fs = IdbFileSystem(idbFactory, dbName,
          options: const FileSystemIdbOptions(pageSize: 2));
      var file = fs.file('test.txt');
      await file.writeAsString('helloworld');

      final ctlr = IdbReadStreamCtlr(file, 1, 5);
      expect(await ctlr.stream.toList(), [
        [101],
        [108, 108],
        [111]
      ]);
    });
    test('stream access 1024 bytes', () async {
      // debugIdbShowLogs = devWarning(true);
      var dbName = 'stream_access_2.db';
      await idbFactory.deleteDatabase(dbName);
      var fs = IdbFileSystem(idbFactory, dbName,
          options: const FileSystemIdbOptions(pageSize: 1024));
      var file = fs.file('test.txt');
      await file.writeAsString('helloworld');

      final ctlr = IdbReadStreamCtlr(file, 1, 5);
      expect(await ctlr.stream.toList(), [
        [101, 108, 108, 111]
      ]);
    }, timeout: const Timeout(Duration(minutes: 2)));
    test('sink access 2 bytes', () async {
      // debugIdbShowLogs = devWarning(true);
      var dbName = 'sink_access_2.db';
      await idbFactory.deleteDatabase(dbName);
      var fs = IdbFileSystem(idbFactory, dbName,
          options: const FileSystemIdbOptions(pageSize: 2));
      var file = fs.file('test.txt');
      var sink = file.openWrite(mode: FileMode.write) as IdbWriteStreamSink;
      var bytes = utf8.encode('hello');
      sink.add(bytes.sublist(0, 1));
      await sink.flushPending();

      var db = fs.db!;
      expect(await file.readAsString(), '');
      expect(await getPartEntries(db), isEmpty);

      sink.add(bytes.sublist(1, 2));
      await sink.flushPending();
      expect(await file.readAsString(), 'he');

      sink.add(bytes.sublist(2, 5));
      await sink.flushPending();
      expect(await file.readAsString(), 'hell');
      await sink.flush();
      expect(await file.readAsString(), 'hello');
      await sink.close();
      expect(await getPartEntries(db), [
        {
          'index': 0,
          'file': 2,
          'content': [104, 101]
        },
        {
          'index': 1,
          'file': 2,
          'content': [108, 108]
        },
        {
          'index': 2,
          'file': 2,
          'content': [111]
        }
      ]);
      // overwrite
      sink = file.openWrite(mode: FileMode.write) as IdbWriteStreamSink;
      expect(await file.readAsString(), 'hello');
      sink.add(utf8.encode('s'));
      await sink.flushPending();
      expect(await file.readAsString(), 'hello');
      expect(await getPartEntries(db), [
        {
          'index': 0,
          'file': 2,
          'content': [104, 101]
        },
        {
          'index': 1,
          'file': 2,
          'content': [108, 108]
        },
        {
          'index': 2,
          'file': 2,
          'content': [111]
        }
      ]);

      sink.add(utf8.encode('o'));
      await sink.flushPending();
      expect(await file.readAsString(), 'so');
      expect(await getPartEntries(db), [
        {
          'index': 0,
          'file': 2,
          'content': [115, 111]
        },
        {
          'index': 1,
          'file': 2,
          'content': [108, 108]
        },
        {
          'index': 2,
          'file': 2,
          'content': [111]
        }
      ]);
      sink.add(utf8.encode('t'));
      await sink.flush();
      expect(await getPartEntries(db), [
        {
          'index': 0,
          'file': 2,
          'content': [115, 111]
        },
        {
          'index': 1,
          'file': 2,
          'content': [116]
        },
        {
          'index': 2,
          'file': 2,
          'content': [111]
        }
      ]);
      await sink.close();
      expect(await getPartEntries(db), [
        {
          'index': 0,
          'file': 2,
          'content': [115, 111]
        },
        {
          'index': 1,
          'file': 2,
          'content': [116]
        },
      ]);

      // append nothing.
      sink = file.openWrite(mode: FileMode.append) as IdbWriteStreamSink;
      await sink.close();
      var text = await file.readAsString();
      expect(text, 'sot');
      // Write nothing.
      sink = file.openWrite(mode: FileMode.write) as IdbWriteStreamSink;
      await sink.close();
      text = await file.readAsString();
      expect(text, '');
    });
  });
}

void fsIdbFormatGroup(idb.IdbFactory idbFactory,
    {FileSystemIdbOptions? options}) {
  group('idb_format', () {
    test('absolute text file', () async {
      // debugIdbShowLogs = devWarning(true);
      var dbName = 'absolute_text_file.db';
      await idbFactory.deleteDatabase(dbName);
      var fs = IdbFileSystem(idbFactory, dbName, options: options);
      var filePath = '${fs.path.separator}file.txt';

      var file = fs.file(filePath);
      await file.writeAsString('test');
      var fileStat = await file.stat();
      var dirStat = await fs.directory(fs.path.separator).stat();
      fs.close();

      var db = await idbFactory.open(dbName);
      expect(db.objectStoreNames.toSet(), {'file', 'part', 'tree'});

      if (!idbSupportsV2Format || !(options?.hasPageSize ?? false)) {
        expect(await getFileEntries(db), [
          {
            'key': 2,
            'value': [116, 101, 115, 116]
          }
        ]);

        expect(await getPartEntries(db), isEmpty);

        var exportMap = {
          'sembast_export': 1,
          'version': 1,
          'stores': [
            mainStoreExportV3,
            {
              'name': 'file',
              'keys': [2],
              'values': [
                {'@Blob': 'dGVzdA=='}
              ]
            },
            {
              'name': 'tree',
              'keys': [1, 2],
              'values': [
                {
                  'name': fs.path.separator,
                  'type': 'dir',
                  'modified': dirStat.modified.toUtc().toIso8601String(),
                  'size': 0,
                  'pn': fs.path.separator
                },
                {
                  'name': 'file.txt',
                  'type': 'file',
                  'parent': 1,
                  'modified': fileStat.modified.toUtc().toIso8601String(),
                  'size': 4,
                  'pn': fs.path.join('1', 'file.txt'),
                }
              ]
            }
          ]
        };
        expect(await getTreeEntries(db), [
          {
            'key': 1,
            'value': {
              'name': fs.path.separator,
              'type': 'dir',
              'modified': dirStat.modified.toIso8601String(),
              'size': 0,
              'pn': fs.path.separator,
            }
          },
          {
            'key': 2,
            'value': {
              'name': 'file.txt',
              'type': 'file',
              'parent': 1,
              'modified': fileStat.modified.toIso8601String(),
              'size': 4,
              'pn': fs.path.join('1', 'file.txt')
            }
          }
        ]);

        // devPrint(jsonPretty(exportMap));
        expect(await sdbExportDatabase(db), exportMap);
      } else {
        expect(await getFileEntries(db), isEmpty);
        if (options?.pageSize == 2) {
          expect(await getPartEntries(db), [
            {
              'index': 0,
              'file': 2,
              'content': [116, 101]
            },
            {
              'index': 1,
              'file': 2,
              'content': [115, 116]
            }
          ]);
        } else {
          expect(await getPartEntries(db), [
            {
              'index': 0,
              'file': 2,
              'content': [116, 101, 115, 116]
            }
          ]);
        }

        var exportMap = {
          'sembast_export': 1,
          'version': 1,
          'stores': [
            mainStoreExportV3,
            if (options?.pageSize == 2)
              {
                'name': 'part',
                'keys': [1, 2],
                'values': [
                  {
                    'index': 0,
                    'file': 2,
                    'content': {'@Blob': 'dGU='}
                  },
                  {
                    'index': 1,
                    'file': 2,
                    'content': {'@Blob': 'c3Q='}
                  }
                ]
              }
            else
              {
                'name': 'part',
                'keys': [1],
                'values': [
                  {
                    'index': 0,
                    'file': 2,
                    'content': {'@Blob': 'dGVzdA=='}
                  }
                ]
              },
            {
              'name': 'tree',
              'keys': [1, 2],
              'values': [
                {
                  'name': fs.path.separator,
                  'type': 'dir',
                  'modified': dirStat.modified.toUtc().toIso8601String(),
                  'size': 0,
                  'pn': fs.path.separator
                },
                {
                  'name': 'file.txt',
                  'type': 'file',
                  'parent': 1,
                  'modified': fileStat.modified.toUtc().toIso8601String(),
                  'size': 4,
                  if (options?.hasPageSize ?? false) 'ps': options?.pageSize,
                  'pn': fs.path.join('1', 'file.txt'),
                }
              ]
            }
          ]
        };
        expect(await getTreeEntries(db), [
          {
            'key': 1,
            'value': {
              'name': fs.path.separator,
              'type': 'dir',
              'modified': dirStat.modified.toIso8601String(),
              'size': 0,
              'pn': fs.path.separator,
            }
          },
          {
            'key': 2,
            'value': {
              'name': 'file.txt',
              'type': 'file',
              'parent': 1,
              'modified': fileStat.modified.toIso8601String(),
              'size': 4,
              if (options?.hasPageSize ?? false) 'ps': options?.pageSize,
              'pn': fs.path.join('1', 'file.txt')
            }
          }
        ]);

        // devPrint(jsonPretty(exportMap));
        expect(await sdbExportDatabase(db), exportMap);
      }
      db.close();
    });
    test('v_current_format', () async {
      var dbName = 'import_v_current.sdb';
      // devPrint('ds_idb_format_v1_test: idbFactory: $idbFactory');
      await idbFactory.deleteDatabase(dbName);
      var db =
          await sdbImportDatabase(exportMapOneFileCurrent, idbFactory, dbName);
      expect(await sdbExportDatabase(db), exportMapOneFileCurrent);
      db.close();

      var fs = IdbFileSystem(idbFactory, dbName);
      var filePath = 'file.txt';

      var file = fs.file(filePath);
      expect(await file.readAsString(), 'test');

      fs.close();
    });
    test('v1_import_current_format', () async {
      var dbName = 'import_v1_current.sdb';
      // devPrint('ds_idb_format_v1_test: idbFactory: $idbFactory');
      await idbFactory.deleteDatabase(dbName);
      var db = await sdbImportDatabase(exportMapOneFileV1, idbFactory, dbName);
      // Untouch not changed
      expect(await sdbExportDatabase(db), exportMapOneFileV1);
      db.close();

      var fs = IdbFileSystem(idbFactory, dbName);
      var filePath = 'file.txt';

      var file = fs.file(filePath);
      expect(await file.readAsString(), 'test');
      // Force update
      await file.writeAsString('test2');
      await file.writeAsString('test');
      expect(await file.readAsString(), 'test');
      var modified = (await file.stat()).modified;

      expect(await getTreeEntries(fs.db!), [
        {
          'key': 1,
          'value': {
            'name': fs.path.separator,
            'type': 'DIRECTORY',
            'modified': '2020-10-31T23:27:05.073',
            'size': 0,
            'pn': fs.path.separator,
          }
        },
        {
          'key': 2,
          'value': {
            'name': 'file.txt',
            'type': 'file',
            'parent': 1,
            'modified': modified.toUtc().toIso8601String(),
            'size': 4,
            'pn': fs.path.join('1', 'file.txt')
          }
        }
      ]);

      fs.close();
    });
    test(
      'v1_format',
      () async {
        var dbName = 'v1_format.db';
        await idbFactory.deleteDatabase(dbName);
        var fs = IdbFileSystem(idbFactory, dbName);
        var filePath = '${fs.path.separator}file.txt';

        var file = fs.file(filePath);
        await file.writeAsString('test');
        var fileStat = await file.stat();
        var dirStat = await fs.directory(fs.path.separator).stat();
        fs.close();

        // Reopen file system
        fs = IdbFileSystem(idbFactory, dbName);
        //devPrint(await fs.list('/', recursive: true).toList());
        file = fs.file(filePath);

        expect(await file.readAsString(), 'test');
        fs.close();

        var db = await idbFactory.open(dbName);
        //expect(db.objectStoreNames.toSet(), {'file', 'tree'});
        var txn = db.transaction(['file', 'tree'], idbModeReadOnly);
        var treeObjectStore = txn.objectStore('tree');
        var list =
            await cursorToList(treeObjectStore.openCursor(autoAdvance: true));
        expect(list.map((row) => {'key': row.key, 'value': row.value}), [
          {
            'key': 1,
            'value': {
              'name': fs.path.separator,
              'type': 'dir',
              'modified': dirStat.modified.toIso8601String(),
              'size': 0,
              'pn': fs.path.separator,
            }
          },
          {
            'key': 2,
            'value': {
              'name': 'file.txt',
              'type': 'file',
              'parent': 1,
              'modified': fileStat.modified.toIso8601String(),
              'size': 4,
              'pn': fs.path.join('1', 'file.txt')
            }
          }
        ]);
        var fileObjectStore = txn.objectStore('file');
        list =
            await cursorToList(fileObjectStore.openCursor(autoAdvance: true));
        expect(list.map((row) => {'key': row.key, 'value': row.value}), [
          {
            'key': 2,
            'value': Uint8List.fromList([116, 101, 115, 116])
          }
        ]);
        var exportMap = {
          'sembast_export': 1,
          'version': 1,
          'stores': [
            mainStoreExportV3,
            {
              'name': 'file',
              'keys': [2],
              'values': [
                {'@Blob': 'dGVzdA=='}
              ]
            },
            {
              'name': 'tree',
              'keys': [1, 2],
              'values': [
                {
                  'name': fs.path.separator,
                  'type': 'dir',
                  'modified': dirStat.modified.toIso8601String(),
                  'size': 0,
                  'pn': fs.path.separator
                },
                {
                  'name': 'file.txt',
                  'type': 'file',
                  'parent': 1,
                  'modified': fileStat.modified.toIso8601String(),
                  'size': 4,
                  'pn': fs.path.join('1', 'file.txt'),
                }
              ]
            }
          ]
        };
        expect(await sdbExportDatabase(db), exportMap);
        db.close();

        // devPrint(exportMap);
        db = await sdbImportDatabase(exportMap, idbFactory, dbName);
        expect(await sdbExportDatabase(db), exportMap);
        db.close();

        fs = IdbFileSystem(idbFactory, dbName);
        // devPrint(await fs.list('/', recursive: true).toList());
        file = fs.file(filePath);

        expect(await file.readAsString(), 'test');
        fs.close();
      },
      //solo: true,
      // Temp timeout
      // timeout: devWarning(const Timeout(Duration(hours: 1)))
      //
    );
  });

  test('complex1', () async {
    var dbName = 'complex1.db';
    var dbNameImported = 'complex1_imported.db';
    await idbFactory.deleteDatabase(dbName);
    var fs = IdbFileSystem(idbFactory, dbName);
    await fs
        .directory(fs.path.join('dir1', 'sub2', 'nested1'))
        .create(recursive: true);
    await fs.directory(fs.path.join('dir1', 'sub1')).create(recursive: true);
    await fs
        .file(fs.path.join('dir1', 'sub1', 'file1.text'))
        .writeAsString('test1');
    await fs
        .file(fs.path.join('dir1', 'sub1', 'file2.text'))
        .writeAsString('test2');
    await fs
        .file(fs.path.join('dir1', 'sub2', 'nested1', 'file3.bin'))
        .writeAsBytes(Uint8List.fromList([1, 2, 3]));

    await fsCheckComplex1(fs);
    fs.close();

    var db = await idbFactory.open(dbName);
    var exportMap = await sdbExportDatabase(db);
    //devPrint(jsonPretty(exportMap)); //print for copying/pasting for import
    db.close();

    db = await sdbImportDatabase(exportMap, idbFactory, dbNameImported);
    expect(await sdbExportDatabase(db), exportMap);
    db.close();

    fs = IdbFileSystem(idbFactory, dbNameImported);
    await fsCheckComplex1(fs);
    fs.close();
  });
}

Future<void> fsCheckComplex1(FileSystem fs) async {
  expect(
      await fs
          .file(fs.path.join('dir1', 'sub2', 'nested1', 'file3.bin'))
          .readAsBytes(),
      [1, 2, 3]);
  expect(
      await fs.file(fs.path.join('dir1', 'sub1', 'file2.text')).readAsString(),
      'test2');
  expect(
      await fs.file(fs.path.join('dir1', 'sub1', 'file1.text')).readAsBytes(),
      [116, 101, 115, 116, 49]);
}

var exportMapOneFileCurrent = exportMapOneFileV2;
