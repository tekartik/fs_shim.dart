@TestOn('node')
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library fs_shim.raw_node_io_test;

import 'dart:convert';

import 'package:node_io/node_io.dart';
import 'package:path/path.dart';
import 'package:tekartik_fs_node/src/fs_node.dart';
import 'package:test/test.dart';

void main() {
  group('raw_node_io', () {
    test('api', () async {
      var path = join('.dart_tool', 'tekartik_fs_node', 'raw_node_io_api');
      var directory = Directory(path);
      directory = await directory.create(recursive: true);
      final entity = await directory.delete();
      expect(entity, const TypeMatcher<Directory>());
    }, skip: true);

    Future createDir(String path) async {
      var parts = split(path);
      for (var i = 1; i <= parts.length; i++) {
        try {
          await Directory(joinAll(parts.sublist(0, i))).create();
        } catch (_) {}
      }
    }

    test('read', () async {
      var path = join('.dart_tool', 'tekartik_fs_node', 'read');
      await createDir(path);
      var file = File(join(path, 'test_in.txt'));
      await file.writeAsString('content', flush: true);
      expect('content', await file.readAsString());

      var stream = file.openRead();
      var all = <int>[];
      await stream.listen((data) {
        all.addAll(data);
      }).asFuture();
      expect(utf8.decode(all), 'content');
    });

    test('write', () async {
      var path = join('.dart_tool', 'tekartik_fs_node', 'write');
      await createDir(path);
      var file = File(join(path, 'test_out.txt'));
      if (await file.exists()) {
        await file.delete();
      }
      var sink = file.openWrite();
      sink.add(utf8.encode('content'));
      await sink.close();
      expect('content', await file.readAsString());
    });

    test('write_2', () async {
      var path = join('.dart_tool', 'tekartik_fs_node', 'write');
      await createDir(path);
      var file = File(join(path, 'test_out.txt'));
      if (await file.exists()) {
        await file.delete();
      }
      var sink = file.openWrite(mode: FileMode.write, encoding: utf8);
      sink.add(utf8.encode('content'));
      await sink.close();
      expect('content', await file.readAsString());
    });

    test('read', () async {
      var path = join('.dart_tool', 'tekartik_fs_node', 'read');
      await createDir(path);
      var file = File(join(path, 'test_in.txt'));
      await file.writeAsString('content', flush: true);
      expect('content', await file.readAsString());

      var stream = file.openRead();
      var all = <int>[];
      await stream.listen((data) {
        all.addAll(data);
      }).asFuture();
      expect(utf8.decode(all), 'content');
    });

    test('pipe', () async {
      var path = join('.dart_tool', 'tekartik_fs_node', 'write');
      await createDir(path);
      var fileIn = File(join(path, 'pipe_in.txt'));
      var fileOut = File(join(path, 'pipe_out.txt'));
      await fileIn.writeAsString('content', flush: true);

      var sink = fileOut.openWrite();
      var stream = fileIn.openRead();
      // !! not implemented
      await stream.cast<List<int>>().pipe(sink);
      //sink.add(utf8.encode('content'));
      //await sink.close();
      expect('content', await fileOut.readAsString());
    }, skip: true);
  });
}
