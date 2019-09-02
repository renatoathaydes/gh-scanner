import 'dart:async';
import 'dart:convert';

import 'package:github_scanner/src/_http.dart';
import 'package:http/http.dart' as http;

import 'cli.dart';
import 'log.dart';

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

class RepoSearch with MenuItem {
  bool verbose;
  MenuItem _prev;

  RepoSearch(this.verbose, this._prev);

  @override
  void ask() {
    print("What topic would you like to search?");
  }

  @override
  MenuItem prev() => _prev;

  @override
  FutureOr<MenuItem> call(String answer) async {
    final resp = await findRepoByTopic(answer, verbose: verbose);
    if (resp.statusCode == 200) {
      final showRepos = ShowRepos(verbose, this, resp);
      if (showRepos.isEmptyResponse) {
        warn("No repositories found.");
      } else {
        showRepos.reportRepositoriesCount();
        showRepos.showRepositories();
        return showRepos;
      }
    } else if (resp.statusCode == 404) {
      warn("No repositories found.");
    } else {
      error("Unable to find repository due to an error: "
          "status=${resp.statusCode}, error: ${resp.body}");
    }
    return this;
  }
}

class ShowRepos with MenuItem {
  final bool verbose;
  final MenuItem _prev;
  dynamic _json;
  String _nextPage;

  ShowRepos(this.verbose, this._prev, http.Response response) {
    _updateResponse(response);
  }

  bool get isEmptyResponse => _reposFrom(_json).isEmpty;

  void _updateResponse(http.Response resp) {
    _nextPage = linkToNextPage(resp.headers);
    _json = jsonDecode(resp.body);
  }

  static List _reposFrom(json) {
    if (json is List) {
      return json;
    } else {
      return json["items"] as List;
    }
  }

  @override
  void ask() {
    print("Enter the name of a repository to show more information about it,\n"
            "\\top to go back to the main menu" +
        (_nextPage == null ? '.' : ",\n\\next to see the next repositories."));
  }

  @override
  FutureOr<MenuItem> call(String answer) async {
    if (answer == '\\next') {
      if (_nextPage == null) {
        warn("There is no next page to go to.");
      } else {
        _updateResponse(await get(_nextPage, verbose: verbose));
        showRepositories();
      }
    } else {
      final items = _reposFrom(_json);
      final re = items.firstWhere((repo) => repo['name'] == answer,
          orElse: () => null);
      if (re == null) {
        warn("Cannot find this repository, please try again.");
      } else {
        showRepo(re);
      }
    }
    return this;
  }

  @override
  MenuItem prev() => _prev;

  void reportRepositoriesCount() {
    int reposFound;
    final json = _json;
    if (json is List) {
      reposFound = json.length;
    } else {
      reposFound = int.tryParse(json["total_count"]?.toString());
    }
    print("Found ${reposFound ?? '?'} repositories.");
  }

  void showRepositories() => _showRepositories(_reposFrom(_json));

  void _showRepositories(List items) {
    for (final repo in items) {
      print("  * ${repo['name']} ("
          "${repo['fork'] == true ? '<fork> ' : ''}"
          "by ${repo['owner']['type'] ?? 'User'} "
          "${repo['owner']['login'] ?? 'unknown'}) - "
          "score: ${repo['score'] ?? '?'}");
    }
  }
}

void showRepo(repo) {
  summary(repo, _repositorySummary);
}
