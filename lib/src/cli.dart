import 'dart:convert';
import 'dart:io' show stderr;

import 'package:ansicolor/ansicolor.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

enum ShowWhat { repos, users }

final _pen = AnsiPen();

enum _Level { info, warn, error }

void info(String text) => _usePen(_Level.info, () => print(_pen(text)));

void warn(String text) => _usePen(_Level.warn, () => print(_pen(text)));

void error(String text) => _usePen(_Level.error, () => print(_pen(text)));

Future<void> show(http.Response resp,
    {bool verbose = false, @required ShowWhat what}) async {
  if (verbose) {
    stderr
      ..writeln("Status: ${resp.statusCode}")
      ..writeln("Headers: ${resp.headers}");
  }

  // let stderr go out first
  await Future(() => verbose ? print(resp.body) : _show(resp.body, what));
}

void _show(String body, ShowWhat showWhat) {
  final json = jsonDecode(body);
  switch (showWhat) {
    case ShowWhat.repos:
      _showRepos(json);
      break;
    case ShowWhat.users:
      _showUsers(json);
      break;
  }
}

void _showRepos(json) {
  print("Found ${json["total_count"] ?? 'unknown'} repositories.");
  final items = json["items"] as List;
  for (final repo in items) {
    print("  * ${repo['name']} (by ${repo['created_by'] ?? 'unknown'}) - "
        "score: ${repo['score']}");
  }
}

void _showUsers(json) {
  print("User: ${json['login']}\n"
      "  - Name: ${json['name'] ?? ''}\n"
      "  - URL: ${json['html_url'] ?? ''}\n"
      "  - Hirable: ${json['hireable'] ?? ''}");
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
