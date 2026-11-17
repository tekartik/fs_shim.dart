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
  // A path for fileSystemIo: pickDirectory() (file_picker 13.4) gives a file
  // URI on desktop and iOS, but a content:// tree URI on Android, which is
  // not a path (toFilePath() would throw a less clear error).
  var uri = await FilePicker.pickDirectory(dialogTitle: 'Select Directory');
  if (uri == null) {
    return null;
  }
  if (!uri.isScheme('file')) {
    throw UnsupportedError(
      'Not a folder path fileSystemIo can open (Android gives a '
      '${uri.scheme}:// URI): $uri',
    );
  }
  return uri.toFilePath();
}

bool get isWebPlatform => false;
