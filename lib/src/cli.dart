import 'dart:io' show stderr;
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:http/http.dart' as http;

final _pen = AnsiPen();

enum _Level { info, warn, error }

void info(String text) => _usePen(_Level.info, () => print(_pen(text)));

void warn(String text) => _usePen(_Level.warn, () => print(_pen(text)));

void error(String text) => _usePen(_Level.error, () => print(_pen(text)));

void show(http.Response resp, {bool verbose = false}) async {
  if (verbose) {
    stderr
      ..writeln("Status: ${resp.statusCode}")
      ..writeln("Headers: ${resp.headers}");
  }

  // let stderr go out first
  await Future(() => print(resp.body));
}

void _usePen(_Level _level, Function() run) {
  switch (_level) {
    case _Level.info:
      _pen.green();
      break;
    case _Level.warn:
      _pen.yellow();
      break;
    case _Level.error:
      _pen.red();
      break;
  }
  try {
    run();
  } catch (e) {
    _pen.reset();
  }
}
