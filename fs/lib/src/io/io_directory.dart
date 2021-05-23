library fs_shim.src.io.io_directory;

import 'dart:io' as io;

import 'package:fs_shim/fs_io.dart';

import 'io_file.dart';
import 'io_file_system_entity.dart';
import 'io_fs.dart';
import 'io_link.dart';

export 'package:fs_shim/fs.dart' show FileSystemEntityType;

DirectoryImpl get currentDirectory => DirectoryImpl.io(io.Directory.current);

class DirectoryImpl extends FileSystemEntityImpl implements Directory {
  io.Directory? get ioDir => ioFileSystemEntity as io.Directory?;

  DirectoryImpl.io(io.Directory dir) {
    ioFileSystemEntity = dir;
  }

  DirectoryImpl(String path) {
    ioFileSystemEntity = io.Directory(path);
  }

  //DirectoryImpl _me(_) => this;
  DirectoryImpl _ioThen(io.Directory resultIoDir) {
    if (resultIoDir.path == ioDir!.path) {
      return this;
    }
    return DirectoryImpl.io(resultIoDir);
  }

  @override
  Future<DirectoryImpl> create({bool recursive = false}) //
      =>
      ioWrap(ioDir!.create(recursive: recursive)).then(_ioThen);

  @override
  Future<DirectoryImpl> rename(String newPath) => ioWrap(ioDir!.rename(newPath))
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          DirectoryImpl(ioFileSystemEntity.path));

  @override
  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true}) {
    var ioStream = ioDir!.list(recursive: recursive, followLinks: followLinks);

    StreamSubscription<FileSystemEntity> _transformer(
        Stream<io.FileSystemEntity> input, bool cancelOnError) {
      late StreamController<FileSystemEntity> controller;
      //StreamSubscription<io.FileSystemEntity> subscription;
      controller = StreamController<FileSystemEntity>(
          onListen: () {
            input.listen((io.FileSystemEntity data) {
              // Duplicate the data.
              if (data is io.File) {
                controller.add(FileImpl.io(data));
              } else if (data is io.Directory) {
                controller.add(DirectoryImpl.io(data));
              } else if (data is io.Link) {
                controller.add(LinkImpl.io(data));
              } else {
                controller.addError(UnsupportedError(
                    'type $data ${data.runtimeType} not supported'));
              }
            }, onError: (Object e) {
              // Important here to wrap the error
              controller.addError(ioWrapError(e));
            }, onDone: controller.close, cancelOnError: cancelOnError);
          },
          sync: true);
      return controller.stream.listen(null);
    }

    // as Stream<io.FileSystemEntity, FileSystemEntity>;
    return ioStream.transform(
        StreamTransformer<io.FileSystemEntity, FileSystemEntity>(_transformer));
  }

  @override
  DirectoryImpl get absolute => DirectoryImpl.io(ioDir!.absolute);
}
