library fs_shim.src.io.io_directory;

import 'package:tekartik_fs_node/src/file_node.dart';
import 'package:tekartik_fs_node/src/file_system_entity_node.dart';
import 'package:tekartik_fs_node/src/file_system_exception_node.dart';
import 'package:tekartik_fs_node/src/fs_node.dart';

import 'import_common_node.dart' as node;
import 'dart:io' as vm_io;
import 'import_common.dart';

DirectoryNode get currentDirectory =>
    new DirectoryNode.io(node.Directory.current as vm_io.Directory);

// Wrap/unwrap
DirectoryNode wrapIoDirectory(vm_io.Directory ioDirectory) =>
    ioDirectory != null ? new DirectoryNode.io(ioDirectory) : null;

vm_io.Directory unwrapIoDirectory(Directory dir) =>
    dir != null ? (dir as DirectoryNode).ioDir : null;

class DirectoryNode extends FileSystemEntityNode implements Directory {
  vm_io.Directory get ioDir => nativeInstance as vm_io.Directory;

  DirectoryNode.io(vm_io.Directory dir) : super(dir);
  DirectoryNode(String path) : super(new node.Directory(path));

  //DirectoryImpl _me(_) => this;
  DirectoryNode _ioThen(vm_io.Directory resultIoDir) {
    if (resultIoDir == null) {
      return null;
    }
    if (resultIoDir.path == ioDir.path) {
      return this;
    }
    return new DirectoryNode.io(resultIoDir);
  }

  @override
  Future<DirectoryNode> delete({bool recursive: false}) async {
    recursive ??= false;
    if (recursive) {
      List<FileSystemEntityNode> entities = await list().toList();
      for (var entity in entities) {
        if (entity is DirectoryNode) {
          await entity.delete(recursive: recursive);
        } else if (entity is FileNode) {
          await entity.delete();
        } else {
          throw new UnsupportedError(
              'entity ${entity} type ${entity.runtimeType} not supported');
        }
      }
    } else {
      await super.delete(recursive: recursive);
    }
    return this;
  }

  @override
  Future<DirectoryNode> create({bool recursive: false}) async {
    recursive ??= false;
    if (await exists()) {
      return throw new FileSystemExceptionNode(
          status: FileSystemException.statusAlreadyExists,
          message: "$path already exists");
    }
    if (recursive) {
      await pathRecursiveCreateParent(path);
    }

    await ioWrap(ioDir.create(recursive: false));
    return this;
  }

  @override
  Future<DirectoryNode> rename(String newPath) async {
    var dir = await ioWrap(ioDir.rename(newPath));
    return new DirectoryNode.io(dir);
  }

  @override
  Stream<FileSystemEntity> list(
      {bool recursive: false, bool followLinks: true}) {
    var ioStream = ioDir.list(recursive: recursive, followLinks: followLinks);

    StreamSubscription<FileSystemEntityNode> _transformer(
        Stream<vm_io.FileSystemEntity> input, bool cancelOnError) {
      StreamController<FileSystemEntityNode> controller;
      //StreamSubscription<io.FileSystemEntity> subscription;
      controller = new StreamController<FileSystemEntityNode>(
          onListen: () {
            input.listen((vm_io.FileSystemEntity data) {
              // Duplicate the data.
              if (data is vm_io.File) {
                controller.add(new FileNode.io(data));
              } else if (data is vm_io.Directory) {
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
        new StreamTransformer<vm_io.FileSystemEntity, FileSystemEntityNode>(
            _transformer));
  }

  @override
  DirectoryNode get absolute =>
      new DirectoryNode.io(ioDir.absolute as vm_io.Directory);
}
