import 'dart:async';
import 'dart:io' show Platform;

import 'package:cli_repl/cli_repl.dart';
import 'package:github_scanner/github_scanner.dart';
import 'package:github_scanner/src/oauth.dart';

const banner = r'''
        __                                     
  ___ _/ /  _______ _______ ____  ___  ___ ____
 / _ `/ _ \/___(_-</ __/ _ `/ _ \/ _ \/ -_) __/
 \_, /_//_/   /___/\__/\_,_/_//_/_//_/\__/_/   
/___/                                          

:: https://github.com/renatoathaydes/gh-scanner ::
''';

const help = '''
This is a simple command-line app that helps find information about users and
repositories on GitHub.

The basic commands are:

  \\q, \\quit   - quit gh-scanner.
  \\t, \\top    - go to the top menu.
  \\i, \\login  - login to GitHub.
  \\o, \\logout - logout from GitHub.
  \\?, \\help   - show this help message.

If you start seeing errors regarding rate-limit, you may want to login 
to GitHub as that will allow you to make more enquiries.

Follow the prompts in each menu for further information.
''';

const topMenuQuestion = "Enter the number for the option you want to use:\n\n"
    "  1 - find user by username\n"
    "  2 - find users by location\n"
    "  3 - find repositories for a certain topic\n";

MenuItem topMenu(String answer) {
  switch (answer) {
    case '1':
      print("What 'username' do you want to look up?");
      return showUserInfo;
    case '2':
      print("What location would you like to search?");
      return showUsersInLocation;
    case '3':
      print("What topic would you like to search?");
      return showRepoByTopic;
    default:
      return null;
  }
}

bool verbose = false;

void main(List<String> args) async {
  verbose = args.contains('-v');
  warn(banner);
  info("Hello ${Platform.environment["USER"] ?? ' user'}!\n"
      "$topMenuQuestion");

  print("Type '\\q' to exit, '\\?' to see usage help.\n");

  final repl = Repl(prompt: asFine('>> '), maxHistory: 120);
  var errorIndex = 0;
  MenuItem menu = topMenu;

  try {
    loop:
    for (var line in repl.run()) {
      line = line.trim();
      switch (line) {
        case '\\quit':
        case '\\q':
          break loop;
        case '\\help':
        case '\\?':
          print(help);
          break;
        case '\\login':
        case '\\i':
          final token = await authorize(verbose: verbose);
          if (token != null) useAccessToken(token);
          break;
        case '\\o':
        case '\\logout':
          useAccessToken(null);
          break;
        case '\\t':
        case '\\top':
          print(topMenuQuestion);
          menu = topMenu;
          break;
        default:
          final answer = await handleError(() => menu(line));
          if (answer == null) {
            warn(iDontKnow[errorIndex % iDontKnow.length]);
            errorIndex++;
          } else {
            if (answer is MenuItem) {
              menu = answer;
            } else {
              error("ERROR: unexpected answer: $answer");
              print(topMenuQuestion);
              menu = topMenu;
            }
          }
      }
    }
  } on StateError {
    // ok, we needed to get out of the REPL loop
  }

  await repl.exit();
  info("Goodbye!");
}

Future<MenuItem> showUserInfo(String answer) async {
  final menu = await handleError(
      () async => await show(answer, verbose: verbose, what: ShowWhat.user));
  return menuOrTopMenu(menu);
}

Future<MenuItem> showUsersInLocation(String answer) async {
  final menu = await handleError(() async =>
      await show(answer, verbose: verbose, what: ShowWhat.users_by_location));
  return menuOrTopMenu(menu);
}

Future<MenuItem> showRepoByTopic(String answer) async {
  final menu = await handleError(
      () async => await show(answer, verbose: verbose, what: ShowWhat.repos));
  return menuOrTopMenu(menu);
}

Future<MenuItem> menuOrTopMenu(MenuItem menu) async {
  if (menu == null) {
    print(topMenuQuestion);
    return topMenu;
  } else {
    return menu;
  }
}

FutureOr<T> handleError<T>(FutureOr<T> Function() run) async {
  try {
    return await run();
  } catch (e) {
    error("ERROR: $e");
    return null;
  }
}
