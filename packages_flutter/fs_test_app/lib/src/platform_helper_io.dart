import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fs_shim/fs_io.dart';

FileSystem getIoFileSystem() => fileSystemIo;
FileSystem getWebFileSystem({required String name}) =>
    throw UnsupportedError('webFileSystem is not supported on native');
FileSystem getOpfsFileSystem() =>
    throw UnsupportedError('opfsFileSystem is not supported on native');

Future<FileSystem?> selectOpfsDirectory() async {
  return null;
}

Future<void> saveFile({required String name, required List<int> bytes}) async {
  await FilePicker.saveFile(
    dialogTitle: 'Save File',
    fileName: name,
    bytes: Uint8List.fromList(bytes),
  );
}

Future<String?> pickDirectoryPath() async {
  // A path for fileSystemIo: pickDirectory() (file_picker 13.4) gives a
  // content:// tree URI on Android, not a path.

  return (await FilePicker.pickDirectory(dialogTitle: 'Select Directory'))
      ?.toFilePath();
}

bool get isWebPlatform => false;
