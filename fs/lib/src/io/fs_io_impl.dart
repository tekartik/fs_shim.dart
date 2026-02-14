import 'package:fs_shim/fs.dart';
import 'package:fs_shim/src/io/io_file_system.dart';

FileSystem? _fileSystemIo;

/// IO file system.
FileSystem get fileSystemIoImpl => _fileSystemIo ??= FileSystemIo();
