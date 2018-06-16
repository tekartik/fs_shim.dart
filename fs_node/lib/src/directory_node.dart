library fs_shim.src.io.io_directory;

import 'package:tekartik_fs_node/src/file_node.dart';
import 'package:tekartik_fs_node/src/file_system_entity_node.dart';
import 'package:tekartik_fs_node/src/fs_node.dart';

import 'import_common_node.dart' as node;
import 'dart:io' as vm_io;
import 'import_common.dart';

DirectoryNode get currentDirectory =>
    new DirectoryNode.io(node.Directory.current);

// Wrap/unwrap
DirectoryNode wrapIoDirectory(vm_io.Directory ioDirectory) =>
    ioDirectory != null ? new DirectoryNode.io(ioDirectory) : null;

vm_io.Directory unwrapIoDirectory(Directory dir) =>
    dir != null ? (dir as DirectoryNode).ioDir : null;

class DirectoryNode extends FileSystemEntityNode implements Directory {
  vm_io.Directory get ioDir => nativeInstance as vm_io.Directory;

  DirectoryNode.io(vm_io.Directory dir) : super(dir);

  DirectoryNode(String path) : super(new node.Directory(path));

  /*
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
  */

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
          // TODO handle link
          print("entity unsupported ${entity} ${entity.runtimeType}");
          // throw new UnsupportedError(
          //    'entity ${entity} type ${entity.runtimeType} not supported');

        }
      }
    }
    await super.delete();
    return this;
  }

  @override
  Future<DirectoryNode> create({bool recursive: false}) async {
    recursive ??= false;
    if (await exists()) {
      // ok
      return this;
    }
    if (recursive) {
      await pathRecursiveCreateParent(path);
    }
    await ioWrap(ioDir.create(recursive: false));
    return this;
  }

  @override
  Future<DirectoryNode> rename(String newPath) async {
    // if existing is an empty directory remove it
    if (await fs.type(newPath) == FileSystemEntityType.directory) {
      // try to delete
      await new DirectoryNode(newPath).delete();
    }
    var dir = await ioWrap(ioDir.rename(newPath));
    return new DirectoryNode.io(dir);
  }

  @override
  Stream<FileSystemEntityNode> list(
      {bool recursive: false, bool followLinks: true}) {
    var controller = new StreamController<FileSystemEntityNode>();

    var ioStream = ioDir.list(recursive: false, followLinks: followLinks);
    var futures = <Future>[];
    ioStream.listen((vm_io.FileSystemEntity data) {
      // Duplicate the data.
      if (data is vm_io.File) {
        controller.add(new FileNode.io(data));
      } else if (data is vm_io.Directory) {
        var subDir = new DirectoryNode.io(data);
        controller.add(subDir);
        if (recursive) {
          futures.add(subDir.list(recursive: true, followLinks: followLinks).listen((FileSystemEntityNode entity) {
            controller.add(entity);
          }).asFuture());
        }
        //} else if (data is io.Link) {
        //  controller.add(new LinkImpl.io(data));
      } else {
        controller.addError(new UnsupportedError(
            'type ${data} ${data.runtimeType} not supported'));
      }
    }, onError: (e) {
      // Important here to wrap the error
      controller.addError(ioWrapError(e));
    }, onDone: () async {
      // wait for sub dirs if any
      await Future.wait(futures);
      controller.close();
    }); //cancelOnError: cancelOnError);

    /*
    StreamSubscription<FileSystemEntityNode> _transformer(
        Stream<vm_io.FileSystemEntity> input, bool cancelOnError) {
      StreamController<FileSystemEntityNode> controller;
      //StreamSubscription<io.FileSystemEntity> subscription;
      controller = new StreamController<FileSystemEntityNode>(
          onListen: () {

            input.listen((vm_io.FileSystemEntity data) {
              devPrint("onListen $data");
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
      return ioStream.transform(
        new StreamTransformer<vm_io.FileSystemEntity, FileSystemEntityNode>(
            _transformer));
      */

    // as Stream<io.FileSystemEntity, FileSystemEntity>;
    return controller.stream;
  }

  @override
  DirectoryNode get absolute => new DirectoryNode.io(ioDir.absolute);
}
