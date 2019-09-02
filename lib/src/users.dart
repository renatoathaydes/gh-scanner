import 'dart:async';
import 'dart:convert';

import 'package:github_scanner/github_scanner.dart';
import 'package:github_scanner/src/_http.dart';
import 'package:github_scanner/src/repos.dart';
import 'package:http/http.dart' as http;

import 'cli.dart';

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

class LookupUsername with MenuItem {
  bool verbose;
  MenuItem _prev;

  LookupUsername(this.verbose, this._prev);

  @override
  void ask() {
    print("What 'username' do you want to look up?");
  }

  @override
  MenuItem prev() => _prev;

  @override
  FutureOr<MenuItem> call(String answer) async {
    final resp = await findUser(answer, verbose: verbose);
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body);
      summary(json, _userSummary);
      return UserSubMenu(verbose, this, answer, json);
    } else if (resp.statusCode == 404) {
      warn("User not found.");
    } else {
      error("Unable to find user due to an error: "
          "status=${resp.statusCode}, error: ${resp.body}");
    }
    return this;
  }
}

class UserSubMenu with MenuItem {
  bool verbose;
  MenuItem _prev;
  String user;
  dynamic json;

  UserSubMenu(this.verbose, this._prev, this.user, this.json);

  @override
  void ask() {
    print("\nShow user's:\n  1 - repositories\n  2 - subscriptions");
  }

  @override
  MenuItem prev() => _prev;

  @override
  FutureOr<MenuItem> call(String answer) async {
    http.Response resp;
    switch (answer) {
      case '1':
        resp = await get(json['repos_url'], verbose: verbose);
        break;
      case '2':
        resp = await get(json['subscriptions_url'], verbose: verbose);
        break;
      default:
        return null;
    }
    final repos= ShowRepos(verbose, this, resp);
    repos.reportRepositoriesCount();
    repos.showRepositories();
    return repos;
  }
}

class ShowUsers with MenuItem {
  final bool verbose;
  final MenuItem _prev;
  http.Response _response;
  String _nextPage;

  // if no users are found, this menu should delegate to the previous menu.
  bool _callPrev = false;

  ShowUsers(this.verbose, this._prev, this._response) {
    _nextPage = linkToNextPage(_response.headers);
    final foundUsers = _show();
    if (!foundUsers) _callPrev = true;
  }

  @override
  void ask() {
    if (_callPrev) {
      _prev.ask();
    } else {
      print("\nEnter the name of a user to see more information about him/her,"
              "\\top to go back to the main menu" +
          (_nextPage == null ? '.' : ",\n\\next to see the next users."));
    }
  }

  @override
  MenuItem prev() => _prev;

  @override
  FutureOr<MenuItem> call(String answer) async {
    if (_callPrev) return _prev(answer);

    if (answer == '\\next') {
      if (_nextPage == null) {
        warn("There is no next page to go to.");
        return this;
      } else {
        _response = await get(_nextPage, verbose: verbose);
        _nextPage = linkToNextPage(_response.headers);
      }
    } else {
      await LookupUsername(verbose, null)(answer);
    }
    return this;
  }

  /// show users and return true if users were found.
  bool _show() {
    final json = jsonDecode(_response.body);
    final users = json['items'] as List;
    if (users.isEmpty) {
      print("No users have been found.\n"
          "Try searching again.");
      return false;
    }
    print("Found ${json['total_count'] ?? '?'} users:");
    final names = users.map((u) => u['login'] ?? '?').join(', ');
    print(names);
    return true;
  }
}
