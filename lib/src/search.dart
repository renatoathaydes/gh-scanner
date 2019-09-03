import 'dart:async';

import 'package:github_scanner/github_scanner.dart';
import 'package:github_scanner/src/_http.dart';
import 'package:github_scanner/src/users.dart';

const _accept = true;
const _reject = false;

class UserSearch with MenuItem {
  String location;
  String language;
  int numberOfRepos;
  final bool verbose;
  final MenuItem _prev;

  MenuItem _locationSetter;
  MenuItem _languageSetter;
  MenuItem _numOfReposSetter;

  UserSearch(this.verbose, this._prev) {
    _locationSetter =
        _SetParameter("Enter a location (e.g. Stockholm).", _setLocation, this);
    _languageSetter = _SetParameter(
        "Enter a Programming Language name (e.g. Java).", _setLanguage, this);
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
        "  3 - Number of repositories owned${numberOfRepos == null ? '' : ' ($numberOfRepos)'}");
    if (location != null || language != null || numberOfRepos != null) {
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
        return _numOfReposSetter;
      case '\\s':
        return _go();
      default:
        return null;
    }
  }

  bool _setLocation(String loc) {
    location = loc;
    return _accept;
  }

  bool _setLanguage(String lang) {
    language = lang;
    return _accept;
  }

  bool _setNumRepos(String answer) {
    numberOfRepos = int.tryParse(answer);
    if (numberOfRepos == null || numberOfRepos < 0) {
      warn("You must enter a positive number, please try again.");
      return _reject;
    }
    return _accept;
  }

  Future<MenuItem> _go() async {
    if (location != null || language != null || numberOfRepos != null) {
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
        return this;
      } else {
        errorResponse(resp);
        return _prev;
      }
    } else {
      warn("No query parameters have been entered. Please try again.");
      return this;
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
