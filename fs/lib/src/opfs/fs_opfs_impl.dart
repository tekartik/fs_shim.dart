import 'fs_opfs.dart';
import 'opfs_file_system.dart';

FileSystemOpfsWeb? _fileSystemOpfsWeb;

/// The OPFS (Origin Private File System) file system.
///
/// There is a single OPFS per origin, this returns a shared instance.
FileSystemOpfsWeb get fileSystemOpfsWebImpl =>
    _fileSystemOpfsWeb ??= FileSystemOpfsImpl();
