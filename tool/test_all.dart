//import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/common_import.dart';

Future testFs() async {
  var dir = 'fs';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(
      DartAnalyzerCmd(['example', 'lib', 'test'])..workingDirectory = dir);
  await runCmd(PubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}

Future testFsTest() async {
  var dir = 'fs_test';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(PubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}

Future testFsNode() async {
  var dir = 'fs_node';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['node']))..workingDirectory = dir);
}

Future main() async {
  await testFs();
  await testFsTest();
  await testFsNode();
}
