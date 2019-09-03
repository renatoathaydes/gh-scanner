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
    } else {
      errorResponse(resp);
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
    if (resp.statusCode == 200) {
      final repos = ShowRepos(verbose, this, resp);
      repos.reportRepositoriesCount();
      if (repos.isEmptyResponse) {
        return this;
      } else {
        repos.showRepositories();
        return repos;
      }
    } else {
      errorResponse(resp);
      return this;
    }
  }
}

class ShowUsers with MenuItem {
  final bool verbose;
  final MenuItem _prev;
  String _nextPage;
  dynamic _json;

  ShowUsers(this.verbose, this._prev, http.Response response) {
    _updateResponse(response);
  }

  static List _usersFrom(json) => json['items'] as List;

  bool get foundUsers => _usersFrom(_json).isNotEmpty;

  void _updateResponse(http.Response resp) {
    _nextPage = linkToNextPage(resp.headers);
    _json = jsonDecode(resp.body);
  }

  @override
  void ask() {
    print("\nEnter the name of a user to see more information about him/her,"
            "\\top to go back to the main menu" +
        (_nextPage == null ? '.' : ",\n\\next to see the next users."));
  }

  @override
  MenuItem prev() => _prev;

  @override
  FutureOr<MenuItem> call(String answer) async {
    if (answer == '\\next') {
      if (_nextPage == null) {
        warn("There is no next page to go to.");
      } else {
        final resp = await get(_nextPage, verbose: verbose);
        if (resp.statusCode == 200) {
          _updateResponse(resp);
          showUsers();
        } else {
          errorResponse(resp);
        }
      }
    } else {
      await LookupUsername(verbose, null)(answer);
    }
    return this;
  }

  void reportUserCount() {
    print("Found ${_json['total_count'] ?? '?'} users.");
  }

  void showUsers() {
    final users = _usersFrom(_json);
    if (users.isEmpty) {
      print("No users have been found.\n"
          "Try searching again.");
    } else {
      final names = users.map((u) => u['login'] ?? '?').join(', ');
      print(names);
    }
  }
}
