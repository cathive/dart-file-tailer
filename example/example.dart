import 'dart:convert' show LineSplitter, utf8;
import 'dart:io' show File, stderr, stdout;

import 'package:file_tailer/file_tailer.dart' show tailFile;

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.write('You need to provide exactly one file to be tailed.\n');
  }
  final (stream, _) = tailFile(File(arguments.first));
  stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) async => stdout.write('$line\n'));
}
