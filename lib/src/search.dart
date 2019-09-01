import 'dart:async';

import 'package:github_scanner/github_scanner.dart';

class UserSearch {
  String location;
  String language;
  int numberOfRepos;
  final bool verbose;

  UserSearch(this.verbose);

  MenuItem get self => this;

  void ask() {
    print("Enter a parameter to include in the search:\n"
        "  1 - Location${location == null ? '' : ' ($location)'}\n"
        "  2 - Programming Language${language == null ? '' : ' ($language)'}\n"
        "  3 - Number of repositories owned${numberOfRepos == null ? '' : ' ($numberOfRepos)'}");
    if (location != null || language != null || numberOfRepos != null) {
      print("Type \\s to start a search.");
    }
  }

  FutureOr call(String answer) {
    switch (answer) {
      case '\\s':
        return _go();
      case '1':
        return _getLocationAnswer();
      case '2':
        return _getLanguageAnswer();
      case '3':
        return _getNumberOfReposAnswer();
      default:
        return null;
    }
  }

  MenuItem _getLocationAnswer() {
    print("Enter a location (e.g. Stockholm).");
    return (answer) {
      location = answer;
      ask();
      return self;
    };
  }

  MenuItem _getLanguageAnswer() {
    print("Enter a Programming Language name (e.g. Java).");
    return (answer) {
      language = answer;
      ask();
      return self;
    };
  }

  MenuItem _getNumberOfReposAnswer() {
    print("Enter the minimum number of repositories (e.g. 4).");
    return (answer) {
      numberOfRepos = int.tryParse(answer);
      if (numberOfRepos == null || numberOfRepos < 0) {
        warn("You must enter a positive number, please try again");
        return _getNumberOfReposAnswer();
      }
      ask();
      return self;
    };
  }

  Future<MenuItem> _go() async {
    if (location != null || language != null || numberOfRepos != null) {
      final resp = await findUsers(
          location: location, language: language, numberOfRepos: numberOfRepos);
      return showResponse(resp, ShowWhat.users, verbose);
    } else {
      warn("No query parameters have been entered. Please try again.");
      ask();
      return self;
    }
  }
}
