// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_src_idb_test;

import 'dart:async';

import 'package:dev_test/test.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:path/path.dart';

import '../test_common.dart';

void main() {
  Future<IdbFileSystemStorage> newStorage() async {
    IdbFileSystemStorage storage = IdbFileSystemStorage(idbFactoryMemory, null);
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
      Node entity = Node.directory(null, "dir");
      await storage.addNode(entity);
      expect(entity.id, 1);

      expect(await storage.getChildNode(null, "dir", false), entity);
      expect(await storage.getChildNode(null, "dummy", false), isNull);
    });

    test('add_get_entity', () async {
      var storage = await newStorage();
      Node node = Node.directory(null, "dir");
      await storage.addNode(node);
      expect(node.id, 1);

      expect(await storage.getNode(["dir"], false), node);
      expect(await storage.getNode(["dummy"], false), isNull);
    });

    test('add_search', () async {
      var storage = await newStorage();
      Node node = Node.directory(null, "dir");
      await storage.addNode(node);
      expect(node.id, 1);

      NodeSearchResult result = await storage.searchNode(["dir"], false);
      expect(result.matches, isTrue);
      expect(result.match, node);
      expect(result.highest, node);
      expect(result.depthDiff, 0);

      result = await storage.searchNode(["dummy"], false);
      expect(result.matches, isFalse);
      expect(result.match, isNull);
      expect(result.highest, isNull);
      expect(result.depthDiff, 1);
    });

    test('link', () async {
      var storage = await newStorage();
      Node dir = Node.directory(null, "dir");
      await storage.addNode(dir);
      Node link = Node.link(null, "link", targetSegments: ["dir"]);
      await storage.addNode(link);

      expect(await storage.getNode(["link"], false), link);
      expect(await storage.getNode(["link"], true), dir);
      expect(await storage.getNode(["dir"], false), dir);
      expect(await storage.getNode(["dir"], true), dir);
    });

    test('link_link', () async {
      var storage = await newStorage();
      Node dir = Node.directory(null, "dir");
      await storage.addNode(dir);
      Node link = Node.link(null, "link", targetSegments: ["dir"]);
      await storage.addNode(link);
      Node link2 = Node.link(null, "link2", targetSegments: ["link"]);
      await storage.addNode(link2);

      expect(await storage.getNode(["link2"], false), link2);
      expect(await storage.getNode(["link2"], true), dir);
      expect(await storage.getNode(["dir"], false), dir);
      expect(await storage.getNode(["dir"], true), dir);
    });

    test('child_node', () async {
      var storage = await newStorage();
      Node dir = Node.directory(null, separator);
      await storage.addNode(dir);
      Node file = Node.file(dir, "file");
      await storage.addNode(file);

      expect(await storage.getNode([separator, "file"], false), file);
      expect(await storage.getNode([separator, "file"], true), file);
      expect(await storage.getChildNode(dir, "file", true), file);
      expect(await storage.getChildNode(dir, "file", false), file);

      Node link = Node.link(dir, "link", targetSegments: [separator, "file"]);
      await storage.addNode(link);

      expect(await storage.getNode([separator, "link"], false), link);
      expect(await storage.getNode([separator, "link"], true), file);
    });

    test('file_in_dir', () async {
      var storage = await newStorage();
      Node top = Node.directory(null, separator);
      await storage.addNode(top);
      Node dir = Node.directory(top, "dir");
      await storage.addNode(dir);
      Node file = Node.file(dir, "file");
      await storage.addNode(file);
      Node link =
          Node.link(top, "link", targetSegments: [separator, "dir", "file"]);
      await storage.addNode(link);

      expect(await storage.getNode([separator, "link"], true), file);

      expect(await storage.getChildNode(top, "link", false), link);
      expect(await storage.getNode([separator, "link"], false), link);
      expect(await storage.getChildNode(top, "link", true), file);
    });
  });
}
