import 'dart:html';
import 'setup.dart';

PreElement? outElement;

void doPrint(msg) {
  outElement = (outElement ?? querySelector('#output') as PreElement);
  outElement!.text = '${outElement!.text}$msg\n';
}

Future<void> exampleInit() async {
  print = doPrint;
}
