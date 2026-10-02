@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb.dart' show DatabaseError;
import 'package:idb_shim/idb_client_native_interop.dart';
import 'package:test/test.dart';

/// Runs on the real IndexedDB stack, under dart2js and dart2wasm.
///
/// Closing the connection makes every later `transaction()` throw
/// `InvalidStateError`, exactly as when the browser closes it on its own, so
/// this checks that the error is recognized and a new connection is opened.
void main() {
  group('idb native connection closed', () {
    late FileSystemIdb fs;
    late File file;

    setUp(() async {
      fs =
          newFileSystemIdb(idbFactoryNative, 'idb_closed_connection_test.db')
              as FileSystemIdb;
      file = fs.file('/dir/file.bin');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(Uint8List.fromList([1, 2, 3]));
    });

    tearDown(() {
      fs.close();
    });

    test('a read fails, then the next one opens a new connection', () async {
      fs.database.close();

      await expectLater(file.readAsBytes(), throwsA(isA<DatabaseError>()));
      expect(await file.readAsBytes(), [1, 2, 3]);
    });

    test('a random access file opens a new connection', () async {
      final raf = await file.open();
      fs.database.close();

      await expectLater(
        raf.readInto(Uint8List(3)),
        throwsA(isA<DatabaseError>()),
      );

      final buffer = Uint8List(3);
      expect(await raf.readInto(buffer), 3);
      expect(buffer, [1, 2, 3]);
      await raf.close();
    });
  });
}
