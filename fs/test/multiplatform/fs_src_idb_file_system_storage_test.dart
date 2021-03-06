// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_src_idb_test;

import 'dart:async';

import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:test/test.dart';

import 'test_common.dart';

void main() {
  var p = idbPathContext;
  Future<IdbFileSystemStorage> newStorage() async {
    final storage = IdbFileSystemStorage(newIdbFactoryMemory(), 'idb_storage');
    await storage.ready;
    return storage;
  }

  group('idb_file_system_storage', () {
    test('ready', () async {
      var storage = await newStorage();
      await storage.ready;
    });

    test('add_get_with_parent', () async {
      var storage = await newStorage();
      final entity = Node.directory(null, 'dir');
      await storage.addNode(entity);
      expect(entity.id, 1);

      expect(await storage.getChildNode(null, 'dir', false), entity);
      expect(await storage.getChildNode(null, 'dummy', false), isNull);
    });

    test('add_get_entity', () async {
      var storage = await newStorage();
      final node = Node.directory(null, 'dir');
      await storage.addNode(node);
      expect(node.id, 1);

      expect(await storage.getNode(['dir'], false), node);
      expect(await storage.getNode(['dummy'], false), isNull);
    });

    test('add_search', () async {
      var storage = await newStorage();
      final node = Node.directory(null, 'dir');
      await storage.addNode(node);
      expect(node.id, 1);

      var result = await storage.searchNode(['dir'], false);
      expect(result.matches, isTrue);
      expect(result.match, node);
      expect(result.highest, node);
      expect(result.depthDiff, 0);

      result = await storage.searchNode(['dummy'], false);
      expect(result.matches, isFalse);
      expect(result.match, isNull);
      expect(result.highest, isNull);
      expect(result.depthDiff, 1);
    });

    test('link', () async {
      var storage = await newStorage();
      final dir = Node.directory(null, 'dir');
      await storage.addNode(dir);
      final link = Node.link(null, 'link', targetSegments: ['dir']);
      await storage.addNode(link);

      expect(await storage.getNode(['link'], false), link);
      expect(await storage.getNode(['link'], true), dir);
      expect(await storage.getNode(['dir'], false), dir);
      expect(await storage.getNode(['dir'], true), dir);
    });

    test('link_link', () async {
      var storage = await newStorage();
      final dir = Node.directory(null, 'dir');
      await storage.addNode(dir);
      final link = Node.link(null, 'link', targetSegments: ['dir']);
      await storage.addNode(link);
      final link2 = Node.link(null, 'link2', targetSegments: ['link']);
      await storage.addNode(link2);

      expect(await storage.getNode(['link2'], false), link2);
      expect(await storage.getNode(['link2'], true), dir);
      expect(await storage.getNode(['dir'], false), dir);
      expect(await storage.getNode(['dir'], true), dir);
    });

    test('child_node', () async {
      var storage = await newStorage();
      final dir = Node.directory(null, p.separator);
      await storage.addNode(dir);
      final file = Node.file(dir, 'file');
      await storage.addNode(file);

      expect(await storage.getNode([p.separator, 'file'], false), file);
      expect(await storage.getNode([p.separator, 'file'], true), file);
      expect(await storage.getChildNode(dir, 'file', true), file);
      expect(await storage.getChildNode(dir, 'file', false), file);

      final link =
          Node.link(dir, 'link', targetSegments: [p.separator, 'file']);
      await storage.addNode(link);

      expect(await storage.getNode([p.separator, 'link'], false), link);
      expect(await storage.getNode([p.separator, 'link'], true), file);
    });

    test('file_in_dir', () async {
      var storage = await newStorage();
      final top = Node.directory(null, p.separator);
      await storage.addNode(top);
      final dir = Node.directory(top, 'dir');
      await storage.addNode(dir);
      final file = Node.file(dir, 'file');
      await storage.addNode(file);
      final link =
          Node.link(top, 'link', targetSegments: [p.separator, 'dir', 'file']);
      await storage.addNode(link);

      expect(await storage.getNode([p.separator, 'link'], true), file);

      expect(await storage.getChildNode(top, 'link', false), link);
      expect(await storage.getNode([p.separator, 'link'], false), link);
      expect(await storage.getChildNode(top, 'link', true), file);
    });

    test('getParentName', () {
      final top = Node.directory(null, p.separator)..id = 1;
      expect(getParentName(top, 'test'), '1/test');
    });
  });
}
