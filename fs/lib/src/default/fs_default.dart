import 'package:fs_shim/fs_shim.dart';
import 'package:fs_shim/src/common/env_utils.dart';

/// Global file system.
FileSystem fileSystemDefault = kFsDartIsWeb ? fileSystemWeb : fileSystemIo;
