//import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/common_import.dart';

Future testFs() async {
  var dir = 'fs';
  await runCmd(pubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(
      dartanalyzerCmd(['example', 'lib', 'test'])..workingDirectory = dir);
  await runCmd(pubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}

Future testFsTest() async {
  var dir = 'fs_test';
  await runCmd(pubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(dartanalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(pubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}

Future testFsNode() async {
  var dir = 'fs_node';
  await runCmd(pubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(dartanalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(
      pubCmd(pubRunTestArgs(platforms: ['node']))..workingDirectory = dir);
}

Future main() async {
  await testFs();
  await testFsTest();
  await testFsNode();
}
