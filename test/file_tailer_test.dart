import 'dart:convert' show LineSplitter, utf8;
import 'dart:io' show Directory, File, FileMode, IOSink;

import 'package:file/memory.dart' show FileSystemStyle, MemoryFileSystem;
import 'package:file_tailer/file_tailer.dart' show FileTailer;
import 'package:path/path.dart' as path;
import 'package:test/test.dart' show expect, group, setUp, tearDown, test;

Directory? tmpDir;

/// Test data
List<String> movies = [
  'Star Wars Episode IV - A New Hope',
  'Star Wars Episode V - The Empire Strikes Back',
  'Star Wars Episode VI - Return of the Jedi',
  'Star Wars Episode VII - The Force Awakens'
];

typedef AsyncCallback = Future<void> Function();

class FileContentsTester {
  final File _file;
  final List<String> _lines;
  final AsyncCallback? _onClose;
  IOSink? _ioSink;
  int _linesWritten = 0;
  FileContentsTester(final File file, final List<String> lines,
      {final AsyncCallback? onClose})
      : _file = file,
        _lines = lines,
        _onClose = onClose {
    _ioSink = _file.openWrite(mode: FileMode.writeOnlyAppend);
  }

  IOSink get ioSink => _ioSink!;

  bool get hasNext => _linesWritten < _lines.length;

  Future<void> writeNext() async {
    if (hasNext) {
      ioSink.writeln(_lines[_linesWritten]);
      await ioSink.flush();
      _linesWritten++;
    } else {
      throw StateError('Cannot write data past last line.');
    }
  }

  Future<void> writeAll() async {
    while (hasNext) {
      await writeNext();
    }

    await ioSink.flush();
    await ioSink.close();
    if (_onClose != null) {
      await _onClose!();
    }
  }
}

void main() {
  final fs = MemoryFileSystem(style: FileSystemStyle.posix);

  setUp(() async {
    await fs.file('/empty.txt').create();
    tmpDir = await Directory.systemTemp.createTemp('file_tailer_test_');
  });
  tearDown(() async {
    if (await tmpDir!.exists()) {
      await tmpDir!.delete(recursive: true);
    }
  });
  group('FileTailer', () {
    test('Default constructor / factory', () {
      final file = fs.file('/empty.txt');
      final tailer = FileTailer(file, bytes: '+0');
      expect(tailer.file, file);
    });
    test('tail()', () async {
      final file = await File(path.join(tmpDir!.path, 'movies.txt')).create();
      final tailer = FileTailer.fromStart(file);
      final tester = FileContentsTester(file, movies,
          onClose: () async => await tailer.cancel(pos: await file.length()));

      var idx = 0;

      await Future.wait([
        tester.writeAll(),
        tailer
            .stream()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) async {
          expect(line, movies[idx]);
          idx++;
        })
      ]);

      expect(movies.length, idx);
    });
  });
}
