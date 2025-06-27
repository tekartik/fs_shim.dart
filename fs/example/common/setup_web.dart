import 'package:web/web.dart' as web;
import 'setup.dart';

web.HTMLPreElement? outElement;

void doPrint(Object? msg) {
  outElement =
      (outElement ??
      web.document.querySelector('#output') as web.HTMLPreElement);
  outElement!.textContent = '${outElement!.textContent}$msg\n';
}

Future<void> exampleInit() async {
  print = doPrint;
}
