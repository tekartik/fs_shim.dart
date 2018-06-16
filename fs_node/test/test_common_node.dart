library fs_shim.test.test_common_io;

// basically same as the io runner but with extra output
export 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_fs_node/src/file_system_node.dart';
import 'package:tekartik_fs_node/src/fs_node.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:tekartik_platform/context.dart';
import 'package:tekartik_platform_node/context_node.dart';

final FileSystemTestContextNode fileSystemTestContextNode =
    new FileSystemTestContextNode();

class FileSystemTestContextNode extends FileSystemTestContext {
  final PlatformContext platform = platformContextNode;
  final FileSystemNode fs = fileSystemNode;
  String outTopPath;
  FileSystemTestContextNode() {
    outTopPath = testOutTopPath;
  }
  String get outPath => join(outTopPath, super.outPath);
}

String get testOutTopPath => join(".dart_tool", "fs_shim_node", "test_out");
String get testOutPath => join(testOutTopPath, joinAll(testDescriptions));
