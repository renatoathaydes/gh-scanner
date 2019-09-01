import 'dart:async';
import 'dart:convert';
import 'dart:io' show stderr;

import 'package:github_scanner/src/headers.dart';
import 'package:github_scanner/src/search.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'http.dart';
import 'log.dart';

typedef MenuItem = FutureOr Function(String answer);

enum ShowWhat { repos, user, users }

const iDontKnow = [
  "Sorry, I don't understand your answer, please enter a valid option.",
  "You entered an invalid option, please try again.",
  "Hm... I don't get it. Can you enter a valid option, please?",
  "Sorry, I still don't understand. Please select a valid option.",
];

const _userSummary = {
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

const _repositorySummary = {
  'Name': 'full_name',
  'Description:': 'description',
  'Score': 'score',
  'Stars': 'stargazers_count',
  'Language': 'language',
  'Fork': 'fork',
  'Open issues': 'open_issues_count',
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
  return await Future(() => showResponse(resp, what, verbose));
}

Future<http.Response> _get(String answer, ShowWhat what) {
  switch (what) {
    case ShowWhat.repos:
      return findRepoByTopic(answer);
    case ShowWhat.users:
      throw 'error'; // TODO should not be called anymore
    case ShowWhat.user:
    default:
      return findUser(answer);
  }
}

MenuItem showResponse(http.Response resp, ShowWhat showWhat, bool verbose) {
  final json = jsonDecode(resp.body);
  switch (showWhat) {
    case ShowWhat.repos:
      return _showRepos(json, resp.headers, verbose);
    case ShowWhat.user:
      return _showUser(json, resp.headers, verbose);
    case ShowWhat.users:
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
    print("  * ${repo['name']} ("
        "${repo['fork'] == true ? '<fork> ' : ''}"
        "by ${repo['owner']['type'] ?? 'User'} "
        "${repo['owner']['login'] ?? 'unknown'}) - "
        "score: ${repo['score'] ?? '?'}");
  }

  final nextPage = _linkToNextPage(headers);

  final askQuestion = () {
    print("Enter the name of a repository to show more information about it,\n"
            "\\top to go back to the main menu" +
        (nextPage == null ? '.' : ",\n\\next to see the next repositories."));
  };

  askQuestion();

  MenuItem menu;
  menu = (answer) async {
    if (answer == '\\next') {
      if (nextPage == null) {
        warn("There is no next page to go to.");
        return menu;
      } else {
        return showResponse(await get(nextPage), ShowWhat.repos, verbose);
      }
    }
    final re =
        items.firstWhere((repo) => repo['name'] == answer, orElse: () => null);
    if (re == null) {
      warn("Cannot find this repository, please try again.");
      return menu;
    } else {
      _summary(re, _repositorySummary);
      askQuestion();
      return menu;
    }
  };

  return menu;
}

MenuItem _showUser(json, Map<String, String> headers, bool verbose) {
  _summary(json, _userSummary);

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
    return showResponse(resp, ShowWhat.repos, verbose);
  };
}

MenuItem _showUsers(json, Map<String, String> headers, bool verbose) {
  final users = json['items'] as List;
  if (users.isEmpty) {
    print("No users have been found.\n"
        "Try searching again.");
    final userSearch = UserSearch(verbose);
    userSearch.ask();
    return userSearch;
  }

  print("Found ${json['total_count'] ?? '?'} users:");
  final names = users.map((u) => u['login'] ?? '?').join(', ');
  print(names);

  final nextPage = _linkToNextPage(headers);

  final askQuestion = () {
    print("\nEnter the name of a user to show more information about them,\n"
            "\\top to go back to the main menu" +
        (nextPage == null ? '.' : ",\n\\next to see the next users."));
  };

  askQuestion();

  MenuItem menu;
  menu = (answer) async {
    if (answer == '\\next') {
      if (nextPage == null) {
        warn("There is no next page to go to.");
        return menu;
      } else {
        return showResponse(await get(nextPage), ShowWhat.users, verbose);
      }
    }
    final user =
        users.firstWhere((u) => u['login'] == answer, orElse: () => null);
    if (user == null) {
      warn("Cannot find user, please try again.");
      return menu;
    } else {
      _summary(user, _userSummary);
      askQuestion();
      return menu;
    }
  };
  return menu;
}

void _summary(json, Map<String, String> fieldByName,
    [String missingValue = '?']) {
  fieldByName.forEach((name, field) {
    print("  $name - ${json[field] ?? missingValue}");
  });
}

String _linkToNextPage(Map<String, String> headers) {
  final link = headers['link'];
  if (link == null) return null;
  final linkHeader = parseLinkHeader(link);
  return linkHeader.next;
}
