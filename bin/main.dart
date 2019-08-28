import 'dart:async';
import 'dart:io' show Platform;

import 'package:cli_repl/cli_repl.dart';
import 'package:github_scanner/github_scanner.dart';

const banner = '''
##### gh-scanner ######
''';

const topMenuQuestion = "Enter the number for the option you want to use:\n\n"
    "  1 - find user information\n"
    "  2 - find repositories for a certain topic\n";

final topMenuMap = <String, MenuItem>{
  '1': showUserInfo,
  '2': showRepoByTopic,
};

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

void main(List<String> arguments) async {
  warn(banner);
  info("\nHello ${Platform.environment["USER"] ?? 'dear user'}!\n"
      "$topMenuQuestion");

  print("Type '\\exit' or '\\q' to exit, or "
      "'\\top' to get back to the top menu\n");

  final repl = Repl(prompt: '>> ', maxHistory: 120);
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
          final answer = await menu(line);
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
      () async => show(await findUser(answer), what: ShowWhat.users));
  return menuOrTopMenu(menu);
}

Future<MenuItem> showRepoByTopic(String answer) async {
  final menu = await handleError(
      () async => show(await findRepoByTopic(answer), what: ShowWhat.repos));
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
