import 'dart:async';

import 'cli.dart';
import 'repos.dart';
import 'search.dart';
import 'users.dart';

class TopMenu with MenuItem {
  static final instance = TopMenu._create();

  TopMenu._create();

  bool verbose = false;

  @override
  MenuItem prev() => null;

  @override
  void ask() {
    print("Enter the number for the option you want to use:\n\n"
        "  1 - lookup user by username.\n"
        "  2 - find users matching certain parameters.\n"
        "  3 - find repositories for a certain topic.");
  }

  @override
  FutureOr<MenuItem> call(String answer) {
    switch (answer) {
      case '1':
        return LookupUsername(verbose, this);
      case '2':
        return UserSearch(verbose, this);
      case '3':
        return RepoSearch(verbose, this);
      default:
        return null;
    }
  }
}
