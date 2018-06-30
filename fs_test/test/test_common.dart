import 'package:fs_shim/fs.dart';

const packageName = "tekartik_fs_test";

String getCurrentTestDir(FileSystem fs) =>
    fs.path.join(".dart_tool", packageName, "test");
