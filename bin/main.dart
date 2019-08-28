import 'dart:async';
import 'dart:io' show Platform;

import 'package:cli_repl/cli_repl.dart';
import 'package:github_scanner/github_scanner.dart';

typedef MenuItem = FutureOr Function(String answer);

const banner = '''
##### gh-scanner ######
''';

const iDontKnow = [
  "Sorry, I don't understand your answer, please enter a valid option.",
  "You entered an invalid option, please try again.",
  "Hm... I don't get it. Can you enter a valid option, please?",
  "Sorry, I still don't understand. Please select a valid option.",
];

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
  await handleError(
      () async => show(await findUser(answer), what: ShowWhat.users));
  print(topMenuQuestion);
  return topMenu;
}

Future<MenuItem> showRepoByTopic(String answer) async {
  await handleError(
      () async => show(await findRepoByTopic(answer), what: ShowWhat.repos));
  print(topMenuQuestion);
  return topMenu;
}

Future<void> handleError(FutureOr Function() run) async {
  try {
    await run();
  } catch (e) {
    error("ERROR: $e");
  }
}
