// ignore_for_file: public_member_api_docs
String logTruncateAny(Object? value) {
  return logTruncate(value?.toString() ?? '<null>');
}

String logTruncate(String text, {int len = 128}) {
  if (text.length > len) {
    text = text.substring(0, len);
  }
  return text;
}
