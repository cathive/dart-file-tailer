# file_tailer

A cross-platform file tailing library for Dart.

The file_tailer package provides functionality to read the stream the contents of a file to which data might be appended. This is especially useful for log files.

The functionality of this library should be similar to the experience when using the `tail`
command on the shell.

## Using

The file_tailer library was designed to be used without a prefix.

```dart
import 'package:file_tailer/file_tailer.dart';
```

The most common way to use this library to stream log files is by handling the data that is emitted
by tailing a file:

```dart
import 'dart:convert' show LineSplitter, utf8;
import 'dart:io' show File, stderr, stdout;

import 'package:file_tailer/file_tailer.dart' show tailFile;

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.write('You need to provide exactly one file to be tailed.\n');
  }
  final (stream, _) = tailFile(File(arguments.first), follow: true, bytes: '+0');
  stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .forEach((line) async => stdout.write('$line\n'));
}
```
