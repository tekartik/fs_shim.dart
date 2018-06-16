import 'package:tekartik_fs_node/src/import_common.dart';

int statusFromMessage(String message) {
  // Error: ENOENT: no such file or directory, scandir '.dart_tool/fs_shim_node/test_out/fs_node/file/create_recursive'
  if (message.contains('ENOENT:')) {
    return FileSystemException.statusNotFound;
  }
  // Error: EISDIR: illegal operation on a directory, open '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/fs_node/.dart_tool/fs_shim_node/test_out/fs_node/file/write_on_dir/file'
  else if (message.contains('EISDIR:')) {
    return FileSystemException.statusIsADirectory;
  }
  // Error: ENOTEMPTY: directory not empty, rename '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/fs_node/.dart_tool/fs_shim_node/test_out/dir/rename_over_existing_not_empty/dir' -> '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/fs_node/.dart_tool/fs_shim_node/test_out/dir/rename_over_existing_not_empty/dir2'
  else if (message.contains('ENOTEMPTY:')) {
    return FileSystemException.statusNotEmpty;
  }
  // Error: ENOTDIR: not a directory, rename '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/fs_node/.dart_tool/fs_shim_node/test_out/dir/rename_over_existing_different_type/dir' -> '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/fs_node/.dart_tool/fs_shim_node/test_out/dir/rename_over_existing_different_type/file'
  else if (message.contains('ENOTDIR:')) {
    return FileSystemException.statusNotADirectory;
  }
  // Error: EEXIST: file already exists, mkdir '/me
  else if (message.contains('EEXIST:')) {
    return FileSystemException.statusAlreadyExists;
  }
  return null;
}
