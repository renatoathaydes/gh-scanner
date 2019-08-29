import 'package:ansicolor/ansicolor.dart';

final _pen = AnsiPen();

enum _Level { fine, info, warn, error }

String asFine(String text) => _usePen(_Level.fine, () => _pen(text).toString());

void fine(String text) => print(asFine(text));

String asInfo(String text) => _usePen(_Level.info, () => _pen(text).toString());

void info(String text) => print(asInfo(text));

String asWarn(String text) => _usePen(_Level.warn, () => _pen(text).toString());

void warn(String text) => print(asWarn(text));

String asError(String text) =>
    _usePen(_Level.error, () => _pen(text).toString());

void error(String text) => print(asError(text));

T _usePen<T>(_Level _level, T Function() run) {
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
    case _Level.fine:
      _pen.blue();
      break;
  }
  try {
    return run();
  } finally {
    _pen.reset();
  }
}
