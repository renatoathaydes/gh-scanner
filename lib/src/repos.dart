import 'dart:async';

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

class RepoResponse with ItemsResponse {
  final http.Response resp;

  RepoResponse(this.resp);

  List get repos => items;

  List<String> get linksToSubscribers {
    return repos
        .map((r) => r["subscribers_url"]?.toString())
        .where((s) => s != null)
        .toList();
  }
}

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
      showRepos.reportRepositoriesCount();
      if (!showRepos.isEmptyResponse) {
        showRepos.showRepositories();
        return showRepos;
      }
    } else {
      errorResponse(resp);
    }
    return this;
  }
}

class ShowRepos with MenuItem {
  final bool verbose;
  final MenuItem _prev;
  RepoResponse _resp;

  ShowRepos(this.verbose, this._prev, http.Response response) {
    _updateResponse(response);
  }

  bool get isEmptyResponse => _resp.isEmpty;

  void _updateResponse(http.Response resp) {
    _resp = RepoResponse(resp);
  }

  @override
  void ask() {
    print("Enter the name of a repository to show more information about it,\n"
            "\\top to go back to the main menu" +
        (_resp.nextPage == null
            ? '.'
            : ",\n\\next to see the next repositories."));
  }

  @override
  FutureOr<MenuItem> call(String answer) async {
    if (answer == '\\next') {
      if (_resp.nextPage == null) {
        warn("There is no next page to go to.");
      } else {
        _updateResponse(await get(_resp.nextPage, verbose: verbose));
        showRepositories();
      }
    } else {
      final re = _resp.repos
          .firstWhere((repo) => repo['name'] == answer, orElse: () => null);
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
    int reposFound = _resp.totalCount;
    print("Found ${reposFound ?? '?'} repositories.");
  }

  void showRepositories() => _showRepositories(_resp.repos);

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
