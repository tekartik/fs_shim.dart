library fs_shim.src.io.io_directory;

import 'dart:async';
import 'package:fs_shim/fs.dart';
import 'package:tekartik_fs_node/src/file_node.dart';
import 'package:tekartik_fs_node/src/file_system_entity_node.dart';
import 'package:tekartik_fs_node/src/fs_node.dart';

import 'import_common_node.dart' as io;

DirectoryNode get currentDirectory =>
    new DirectoryNode.io(io.Directory.current as io.Directory);

// Wrap/unwrap
DirectoryNode wrapIoDirectory(io.Directory ioDirectory) =>
    ioDirectory != null ? new DirectoryNode.io(ioDirectory) : null;

io.Directory unwrapIoDirectory(Directory dir) =>
    dir != null ? (dir as DirectoryNode).ioDir : null;

class DirectoryNode extends FileSystemEntityNode implements Directory {
  io.Directory get ioDir => nativeInstance as io.Directory;

  DirectoryNode.io(io.Directory dir) : super(dir);
  DirectoryNode(String path) : super(new io.Directory(path));

  //DirectoryImpl _me(_) => this;
  DirectoryNode _ioThen(io.Directory resultIoDir) {
    if (resultIoDir == null) {
      return null;
    }
    if (resultIoDir.path == ioDir.path) {
      return this;
    }
    return new DirectoryNode.io(resultIoDir);
  }

  @override
  Future<DirectoryNode> create({bool recursive: false}) async {
    var dir = await ioWrap(ioDir.create(recursive: recursive)) as io.Directory;
    return _ioThen(dir);
  }

  @override
  Future<DirectoryNode> rename(String newPath) async {
    var dir = await ioWrap(ioDir.rename(newPath)) as io.Directory;
    return new DirectoryNode.io(dir);
  }

  @override
  Stream<FileSystemEntity> list(
      {bool recursive: false, bool followLinks: true}) {
    var ioStream = ioDir.list(recursive: recursive, followLinks: followLinks);

    StreamSubscription<FileSystemEntity> _transformer(
        Stream<io.FileSystemEntity> input, bool cancelOnError) {
      StreamController<FileSystemEntity> controller;
      //StreamSubscription<io.FileSystemEntity> subscription;
      controller = new StreamController<FileSystemEntity>(
          onListen: () {
            input.listen((io.FileSystemEntity data) {
              // Duplicate the data.
              if (data is io.File) {
                controller.add(new FileNode.io(data));
              } else if (data is io.Directory) {
                controller.add(new DirectoryNode.io(data));
                //} else if (data is io.Link) {
                //  controller.add(new LinkImpl.io(data));
              } else {
                controller.addError(new UnsupportedError(
                    'type ${data} ${data.runtimeType} not supported'));
              }
            }, onError: (e) {
              // Important here to wrap the error
              controller.addError(ioWrapError(e));
            }, onDone: controller.close, cancelOnError: cancelOnError);
          },
          sync: true);
      return controller.stream.listen(null);
    }

    // as Stream<io.FileSystemEntity, FileSystemEntity>;
    return ioStream.transform(
        new StreamTransformer<io.FileSystemEntity, FileSystemEntity>(
            _transformer));
  }

  @override
  DirectoryNode get absolute =>
      new DirectoryNode.io(ioDir.absolute as io.Directory);
}
