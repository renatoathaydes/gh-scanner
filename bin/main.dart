import 'dart:async';
import 'dart:io' show Platform;

import 'package:cli_repl/cli_repl.dart';
import 'package:github_scanner/github_scanner.dart';

const banner = r'''
        __                                     
  ___ _/ /  _______ _______ ____  ___  ___ ____
 / _ `/ _ \/___(_-</ __/ _ `/ _ \/ _ \/ -_) __/
 \_, /_//_/   /___/\__/\_,_/_//_/_//_/\__/_/   
/___/                                          

:: https://github.com/renatoathaydes/gh-scanner ::
''';

const topMenuQuestion = "Enter the number for the option you want to use:\n\n"
    "  1 - find user information\n"
    "  2 - find repositories for a certain topic\n";

MenuItem topMenu(String answer) {
  switch (answer) {
    case '1':
      print("What 'username' do you want to look up?");
      return showUserInfo;
    case '2':
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
  info("Hello ${Platform.environment["USER"] ?? 'dear user'}!\n"
      "$topMenuQuestion");

  print("Type '\\exit' or '\\q' to exit, or "
      "'\\top' to get back to the top menu\n");

  final repl = Repl(prompt: asFine('>> '), maxHistory: 120);
  var errorIndex = 0;
  MenuItem menu = topMenu;

  try {
    loop:
    for (var line in repl.run()) {
      line = line.trim();
      switch (line) {
        case '\\exit':
        case '\\q':
          break loop;
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
      () async => await show(answer, verbose: verbose, what: ShowWhat.users));
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
