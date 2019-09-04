import 'dart:async';

import 'package:github_scanner/github_scanner.dart';
import 'package:github_scanner/src/_http.dart';
import 'package:github_scanner/src/format.dart';
import 'package:github_scanner/src/repos.dart';
import 'package:github_scanner/src/users.dart';
import 'package:http/http.dart' as http;

const _accept = true;
const _reject = false;

class UserSearch with MenuItem {
  String location;
  String language;
  String topic;
  int numberOfRepos;
  final bool verbose;
  final MenuItem _prev;

  MenuItem _locationSetter;
  MenuItem _languageSetter;
  MenuItem _numOfReposSetter;
  MenuItem _topicSetter;

  UserSearch(this.verbose, this._prev) {
    _locationSetter =
        _SetParameter("Enter a location (e.g. Stockholm).", _setLocation, this);
    _languageSetter = _SetParameter(
        "Enter a Programming Language name (e.g. Java).", _setLanguage, this);
    _topicSetter = _SetParameter(
        "Enter a topic of interest (e.g. security).", _setTopic, this);
    _numOfReposSetter = _SetParameter(
        "Enter the minimum number of repositories (e.g. 4).",
        _setNumRepos,
        this);
  }

  @override
  void ask() {
    print("Enter a parameter to include in the search:\n"
        "  1 - Location${location == null ? '' : ' ($location)'}\n"
        "  2 - Programming Language${language == null ? '' : ' ($language)'}\n"
        "  3 - Topic of interest${topic == null ? '' : ' ($topic)'}\n"
        "  4 - Number of repositories owned${numberOfRepos == null ? '' : ' ($numberOfRepos)'}");
    if (location != null ||
        language != null ||
        numberOfRepos != null ||
        topic != null) {
      print("Type \\s to start a search.");
    }
  }

  @override
  MenuItem prev() => _prev;

  @override
  FutureOr<MenuItem> call(String answer) {
    switch (answer) {
      case '1':
        return _locationSetter;
      case '2':
        return _languageSetter;
      case '3':
        return _topicSetter;
      case '4':
        return _numOfReposSetter;
      case '\\s':
        return _go();
      default:
        return null;
    }
  }

  bool _setLocation(String loc) {
    location = loc.isEmpty ? null : loc;
    return _accept;
  }

  bool _setLanguage(String lang) {
    language = lang.isEmpty ? null : lang;
    return _accept;
  }

  bool _setTopic(String top) {
    topic = top.isEmpty ? null : top;
    return _accept;
  }

  bool _setNumRepos(String num) {
    if (num.isEmpty) {
      numberOfRepos = null;
      return true;
    }
    numberOfRepos = int.tryParse(num);
    if (numberOfRepos == null || numberOfRepos < 0) {
      warn("You must enter a positive number, please try again.");
      return _reject;
    }
    return _accept;
  }

  Future<MenuItem> _go() async {
    if (location != null || language != null || numberOfRepos != null) {
      if (topic != null) {
        return await _searchUsingTopicAndOthers();
      } else {
        return await _searchWithoutTopic();
      }
    } else if (topic != null) {
      return await _searchByTopic();
    } else {
      warn("No query parameters have been entered. Please try again.");
      return this;
    }
  }

  Future<MenuItem> _searchWithoutTopic() async {
    final resp = await findUsers(
        location: location,
        language: language,
        numberOfRepos: numberOfRepos,
        verbose: verbose);
    if (resp.statusCode == 200) {
      final showUsers = ShowUsers(verbose, this, resp);
      showUsers.reportUserCount();
      if (showUsers.foundUsers) {
        showUsers.showUsers();
        return showUsers;
      }
    } else {
      errorResponse(resp);
    }
    return this;
  }

  Future<MenuItem> _searchByTopic() async {
    final resp = RepoResponse(await findRepoByTopic(topic, verbose: verbose));
    if (verbose) {
      info("Will check repositories: ${resp.linksToSubscribers.join(', ')}");
    }
    final futureResponses = resp.linksToSubscribers
        .map((link) => get(link, verbose: verbose))
        .toList();
    final printer = TabularDataPrinter();
    await for (final usersResp in Stream.fromFutures(futureResponses)) {
      if (usersResp.statusCode == 200) {
        final names = ShowUsers(verbose, null, usersResp).usernames;
        printer.addAll(names);
      } else {
        errorResponse(usersResp);
        break;
      }
    }
    printer.flush();
    return this;
  }

  Future<MenuItem> _searchUsingTopicAndOthers() async {
    final client = http.Client();
    try {
      var resp = await findUsers(
        location: location,
        language: language,
        numberOfRepos: numberOfRepos,
        verbose: verbose,
        perPage: 100,
        client: client,
      );
      if (resp.statusCode != 200) {
        errorResponse(resp);
        return this;
      }

      // accumulate users from as many pages as necessary to find a good number
      final users = <String>{};
      while (users.length < 1000) {
        final usersResp = UsersResponse(resp);
        users.addAll(usersResp.usernames);
        print(
            "Searching next page: ${usersResp.nextPage}, total users so far: ${users.length}");
        if (usersResp.nextPage == null) break;
        resp = await get(usersResp.nextPage, verbose: verbose, client: client);
        if (resp.statusCode != 200) break;
      }

      final showUsers = ShowUsers(verbose, this, resp);
      if (users.isEmpty) {
        print("No users have been found.\n"
            "Try searching again.");
        return this;
      }
      // found some users, try to find the same users by topic search now
      final repoResp = RepoResponse(await findRepoByTopic(topic,
          verbose: verbose, perPage: 100, client: client));
      if (repoResp.isEmpty) {
        print("Found ${showUsers.totalCount} users,"
            " but none of them seems to be interested in the topic.\n"
            "Maybe try removing the topic from the search.");
        return this;
      }
      if (verbose) {
        info(
            "Will check repositories: ${repoResp.linksToSubscribers.join(', ')}");
      }
      final futureResponses = repoResp.linksToSubscribers
          .map((link) => get(link, verbose: verbose, client: client))
          .toList();

      final usersOnTopic = <String>{};
      await for (final usersResp in Stream.fromFutures(futureResponses)) {
        if (usersResp.statusCode == 200) {
          final names = UsersResponse(usersResp).usernames;
          usersOnTopic.addAll(names);
        } else {
          errorResponse(usersResp);
          break;
        }
      }

      final allUsers = users.intersection(usersOnTopic);
      print("Matching users: ${users.length}, "
          "on topic: ${usersOnTopic.length}, "
          "both: ${allUsers.length}");

      if (allUsers.isEmpty) {
        print("Found ${showUsers.totalCount} users,"
            " but none of them seems to be interested in the topic.\n"
            "Maybe try removing the topic from the search.");
        return this;
      } else {
        print("Found ${showUsers.totalCount} users, ${allUsers.length} of which"
            " matching the topic selected:");
        final printer = TabularDataPrinter();
        printer.addAll(allUsers);
        printer.flush();
        return showUsers;
      }
    } finally {
      client.close();
    }
  }
}

class _SetParameter with MenuItem {
  final String question;
  final bool Function(String) setter;
  final MenuItem _prev;

  _SetParameter(this.question, this.setter, this._prev);

  @override
  void ask() => print(question);

  @override
  FutureOr<MenuItem> call(String answer) {
    final accepted = setter(answer);
    if (accepted) return _prev;
    return this;
  }

  @override
  MenuItem prev() => _prev;
}
