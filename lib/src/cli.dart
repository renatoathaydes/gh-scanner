import 'dart:async';
import 'dart:convert';
import 'dart:io' show stderr;

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'http.dart';
import 'log.dart';

typedef MenuItem = FutureOr Function(String answer);

enum ShowWhat { repos, user, users_by_location }

const iDontKnow = [
  "Sorry, I don't understand your answer, please enter a valid option.",
  "You entered an invalid option, please try again.",
  "Hm... I don't get it. Can you enter a valid option, please?",
  "Sorry, I still don't understand. Please select a valid option.",
];

const _repositorySummary = {
  'User': 'login',
  'Name': 'name',
  'Email': 'email',
  'URL': 'html_url',
  'Biography': 'bio',
  'Repositories': 'public_repos',
  'Followers': 'followers',
  'Location': 'location',
  'Hireable': 'hireable'
};

const _userSummary = {
  'Name': 'full_name',
  'Description:': 'description',
  'Score': 'score',
  'Watchers': 'watchers_count',
  'Language': 'language',
  'URL': 'html_url',
};

Future<MenuItem> show(String answer,
    {bool verbose = false, @required ShowWhat what}) async {
  final resp = await _get(answer, what);
  if (verbose) {
    stderr
      ..writeln("Status: ${resp.statusCode}")
      ..writeln("Headers: ${resp.headers}")
      ..writeln(resp.body)
      ..writeln("---------");
  }
  if (resp.statusCode != 200) {
    error(resp.body);
    return null;
  }

  // let stderr go out first
  return await Future(() => _show(resp, what, verbose));
}

Future<http.Response> _get(String answer, ShowWhat what) {
  switch (what) {
    case ShowWhat.repos:
      return findRepoByTopic(answer);
    case ShowWhat.users_by_location:
      return findUsersInLocation(answer);
    case ShowWhat.user:
    default:
      return findUser(answer);
  }
}

MenuItem _show(http.Response resp, ShowWhat showWhat, bool verbose) {
  final json = jsonDecode(resp.body);
  switch (showWhat) {
    case ShowWhat.repos:
      return _showRepos(json, resp.headers, verbose);
    case ShowWhat.user:
      return _showUser(json, resp.headers, verbose);
    case ShowWhat.users_by_location:
      return _showUsers(json, resp.headers, verbose);
    default:
      throw Exception("Unknown enum: $showWhat");
  }
}

MenuItem _showRepos(json, Map<String, String> headers, bool verbose) {
  List items;
  String reposFound;
  if (json is List) {
    items = json;
    reposFound = items.length.toString();
  } else {
    items = json["items"] as List;
    reposFound = json["total_count"]?.toString() ?? '?';
  }

  if (items.isEmpty) {
    print("No repositories were found.");
    return null;
  } else {
    print("Found ${reposFound} repositories.");
  }

  for (final repo in items) {
    print("  * ${repo['name']} "
        "(by ${repo['owner']['type'] ?? 'User'} "
        "${repo['owner']['login'] ?? 'unknown'}) - "
        "score: ${repo['score'] ?? '?'}");
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
      _summary(re, _userSummary);
      print("Enter another repository name or \\top to go to the main menu.");
      return menu;
    }
  };

  return menu;
}

MenuItem _showUser(json, Map<String, String> headers, bool verbose) {
  _summary(json, _repositorySummary);

  print("\nShow user's:\n  1 - repositories\n  2 - subscriptions");

  return (answer) async {
    http.Response resp;
    switch (answer) {
      case '1':
        resp = await get(json['repos_url']);
        break;
      case '2':
        resp = await get(json['subscriptions_url']);
        break;
      default:
        return null;
    }
    return _show(resp, ShowWhat.repos, verbose);
  };
}

MenuItem _showUsers(json, Map<String, String> headers, bool verbose) {
  print("Found ${json['total_count'] ?? '?'} users:");
  final users = json['items'] as List;
  final names = users.map((u) => u['login'] ?? '?').join(', ');
  print(names);
  return null;
}

void _summary(json, Map<String, String> fieldByName,
    [String missingValue = '?']) {
  fieldByName.forEach((name, field) {
    print("  $name - ${json[field] ?? missingValue}");
  });
}
