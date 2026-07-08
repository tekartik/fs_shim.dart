import 'package:fs_shim/fs_opfs_web.dart';
import 'package:web/web.dart' as web;

Future<void> main() async {
  final openButton =
      web.document.querySelector('#open') as web.HTMLButtonElement;
  final saveButton =
      web.document.querySelector('#save') as web.HTMLButtonElement;
  final output = web.document.querySelector('#output') as web.HTMLPreElement;

  void write(Object? msg) {
    output.textContent = '${output.textContent}$msg\n';
  }

  const textTypes = [
    FileSystemOpfsWebFilePickerAcceptType(
      description: 'Text files',
      accept: {
        'text/plain': ['.txt'],
      },
    ),
  ];

  openButton.onClick.listen((_) async {
    output.textContent = '';
    final List<FileSystemOpfsWebFileHandle> handles;
    try {
      handles = await fileSystemOpfsWebShowOpenFilePicker(
        const FileSystemOpfsWebShowOpenFilePickerOptions(
          multiple: true,
          types: textTypes,
        ),
      );
    } catch (e) {
      // Cancelled by the user (or unsupported browser).
      write('No file selected ($e)');
      return;
    }

    final fs = fileSystemOpfsWebWithFileHandles(handles);
    write('Content of the selected file(s):');
    await for (final entity in fs.directory('/').list()) {
      final file = fs.file(entity.path);
      write('${file.path} ${await file.stat()}');
      write(await file.readAsString());
    }
  });

  saveButton.onClick.listen((_) async {
    output.textContent = '';
    final FileSystemOpfsWebFileHandle handle;
    try {
      handle = await fileSystemOpfsWebShowSaveFilePicker(
        const FileSystemOpfsWebShowSaveFilePickerOptions(
          suggestedName: 'fs_shim_demo.txt',
          types: textTypes,
        ),
      );
    } catch (e) {
      // Cancelled by the user (or unsupported browser).
      write('No file selected ($e)');
      return;
    }

    final fs = fileSystemOpfsWebWithFileHandles([handle]);
    final file = (await fs.directory('/').list().toList()).first as File;
    await file.writeAsString('Written by fs_shim at ${DateTime.now()}\n');
    write('Written ${file.path} ${await file.stat()}');
  });
}
