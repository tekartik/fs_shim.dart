import 'package:fs_shim/fs_opfs_web.dart';
import 'package:web/web.dart' as web;

Future<void> main() async {
  final button = web.document.querySelector('#pick') as web.HTMLButtonElement;
  final button2 = web.document.querySelector('#pick2') as web.HTMLButtonElement;
  final output = web.document.querySelector('#output') as web.HTMLPreElement;

  void write(Object? msg) {
    output.textContent = '${output.textContent}$msg\n';
  }

  Future<void> _handleDir(FileSystemOpfsWebDirectoryHandle dirHandle) async {
    final fs = FileSystemOpfsWeb.withRootHandle(dirHandle);
    write('Content of the selected directory:');
    final entities = await fs.directory('/').list().toList();
    entities.sort((a, b) => a.path.compareTo(b.path));
    if (entities.isEmpty) {
      write('(empty)');
    }
    for (final entity in entities) {
      write('${entity.path} ${await entity.stat()}');
    }
  }

  button.onClick.listen((_) async {
    output.textContent = '';
    final FileSystemOpfsWebDirectoryHandle dirHandle;
    try {
      dirHandle = await FileSystemOpfsWeb.showDirectoryPicker();
    } catch (e) {
      // Cancelled by the user (or unsupported browser).
      write('No directory selected ($e)');
      return;
    }

    await _handleDir(dirHandle);
  });
  button2.onClick.listen((_) async {
    output.textContent = '';
    final FileSystemOpfsWebDirectoryHandle dirHandle;
    try {
      dirHandle = await FileSystemOpfsWeb.showDirectoryPicker(
        FileSystemOpfsWebShowDirectoryPickerOptions(
          startIn: FileSystemOpfsWebPickerOptions.startInPictures,
        ),
      );
    } catch (e) {
      // Cancelled by the user (or unsupported browser).
      write('No directory selected ($e)');
      return;
    }

    await _handleDir(dirHandle);
  });
}
