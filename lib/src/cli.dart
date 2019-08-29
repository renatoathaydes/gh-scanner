import 'dart:async';
import 'dart:convert';
import 'dart:io' show stderr;

import 'package:ansicolor/ansicolor.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'http.dart';

typedef MenuItem = FutureOr Function(String answer);

enum ShowWhat { repos, users }

const iDontKnow = [
  "Sorry, I don't understand your answer, please enter a valid option.",
  "You entered an invalid option, please try again.",
  "Hm... I don't get it. Can you enter a valid option, please?",
  "Sorry, I still don't understand. Please select a valid option.",
];

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

Future<MenuItem> show(http.Response resp,
    {bool verbose = false, @required ShowWhat what}) async {
  if (verbose) {
    stderr
      ..writeln("Status: ${resp.statusCode}")
      ..writeln("Headers: ${resp.headers}");
  }

  // let stderr go out first
  return await Future(() => _show(resp.body, what, verbose));
}

MenuItem _show(String body, ShowWhat showWhat, bool verbose) {
  final json = jsonDecode(body);
  switch (showWhat) {
    case ShowWhat.repos:
      return _showRepos(json, verbose);
    case ShowWhat.users:
      return _showUsers(json, verbose);
    default:
      throw Exception("Unknown enum: $showWhat");
  }
}

MenuItem _showRepos(json, bool verbose) {
  List items;
  if (json is List) {
    items = json;
  } else {
    print("Found ${json["total_count"] ?? 'unknown'} repositories.");
    items = json["items"] as List;
  }

  for (final repo in items) {
    print("  * ${repo['name']} (by ${repo['created_by'] ?? 'unknown'}) - "
        "score: ${repo['score']}");
  }

  print("Enter the name of a repository to show more information about it.\n"
      "Enter \\top to go back to the main menu.");

  MenuItem menu;
  menu = (answer) {
    final re =
        items.firstWhere((repo) => repo['name'] == answer, orElse: () => null);
    if (re == null) {
      warn("Cannot find this repository, please try again.");
      return menu;
    } else {
      _summary(re, {
        'Name': 'display_name',
        'Description:': 'short_description',
        'Score': 'score'
      });
      print("Enter another repository name or \\top to go to the main menu.");
      return menu;
    }
  };

  return menu;
}

MenuItem _showUsers(json, bool verbose) {
  _summary(json, {
    'User': 'login',
    'Name': 'name',
    'Email': 'email',
    'URL': 'html_url',
    'Biography': 'bio',
    'Repositories': 'public_repos',
    'Followers': 'followers',
    'Hireable': 'hireable'
  });

  print("\nShow user's:\n  1 - repositories\n  2 - subscriptions");

  return (answer) async {
    switch (answer) {
      case '1':
        final resp = await get(json['repos_url']);
        return _show(resp.body, ShowWhat.repos, verbose);
      case '2':
        warn("TODO");
        final resp = await get(json['subscriptions_url']);
        print(resp.body);
    }
    return null;
  };
}

void _summary(json, Map<String, String> fieldByName,
    [String missingValue = '?']) {
  fieldByName.forEach((name, field) {
    print("  $name - ${json[field] ?? missingValue}");
  });
}

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
