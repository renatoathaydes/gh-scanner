import 'dart:io' show stdout;
import 'dart:math';

class TabularDataPrinter {
  final int columns;
  final int colMinWidth;
  final Set<String> _allItems = {};
  final List<String> _waitingToFlush = [];

  TabularDataPrinter({this.columns = 4, this.colMinWidth = 16}) {
    if (columns <= 0) {
      throw ArgumentError.value(columns, "columns", "must be greater than 0");
    }
  }

  void add(String item) {
    final isNew = _allItems.add(item);
    if (isNew) {
      _waitingToFlush.add(item);
      _maybeFlush();
    }
  }

  void addAll(Iterable<String> items) => items.forEach(add);

  void _maybeFlush() {
    if (_waitingToFlush.length == columns) {
      flush();
    }
  }

  void flush() {
    if (_waitingToFlush.isEmpty) return;
    for (final item in _waitingToFlush) {
      stdout.write(item.padRight(max(item.length + 1, colMinWidth)));
    }
    stdout.writeln('');
    _waitingToFlush.clear();
  }
}
