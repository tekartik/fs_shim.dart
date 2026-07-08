import 'dart:io' as io;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:fs_shim/fs_io.dart';

FileSystem getIoFileSystem() => fileSystemIo;
FileSystem getWebFileSystem() =>
    throw UnsupportedError('webFileSystem is not supported on native');
FileSystem getOpfsFileSystem() =>
    throw UnsupportedError('opfsFileSystem is not supported on native');

Future<FileSystem?> selectOpfsDirectory() async {
  return null;
}

Future<void> saveFile({required String name, required List<int> bytes}) async {
  final path = await FilePicker.saveFile(
    dialogTitle: 'Save File',
    fileName: name,
  );
  if (path != null) {
    final file = io.File(path);
    await file.writeAsBytes(bytes);
  }
}

Future<String?> pickDirectoryPath() async {
  return await FilePicker.getDirectoryPath(dialogTitle: 'Select Directory');
}

Future<Uint8List> readBytesFromPath(String path) async {
  return await io.File(path).readAsBytes();
}

bool get isWebPlatform => false;
