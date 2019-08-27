import 'dart:async';
import 'dart:io' show Platform;
import 'dart:io';

import 'package:cli_repl/cli_repl.dart';
import 'package:github_scanner/github_scanner.dart';

const iDontKnow = [
  "Sorry, I don't understand your answer, please enter a valid option.",
  "You entered an invalid option, please try again.",
  "Hm... I don't get it. Can you enter a valid option, please?",
  "Sorry, I still don't understand. Please select a valid option.",
];

main(List<String> arguments) async {
  info("Hello ${Platform.environment["USER"] ?? 'dear user'}!\n"
      "What would you like to find on GitHub?\n\n"
      "Enter the number for the option you want to use:\n\n"
      "  1 - find user information\n"
      "  2 - find repositories for a certain topic\n\n");

  print("Type 'exit' or 'q' to exit.\n");

  final repl = Repl(prompt: '>> ', maxHistory: 120);
  var errorIndex = 0;

  try {
    await for (var line in repl.runAsync()) {
      line = line.trim();
      switch (line) {
        case '1':
          await showUserInfo();
          break;
        case '2':
          await showRepoByTopic();
          break;
        case 'exit':
        case 'q':
          await repl.exit();
          break;
        default:
          warn(iDontKnow[errorIndex % iDontKnow.length]);
          errorIndex++;
      }
    }
  } on StateError {
    // ok, we needed to get out of the REPL loop
  }

  info("Goodbye!");
}

void showUserInfo() async {
  stdout.write("What username to search? ");
  final user = stdin.readLineSync().trim();
  await handleError(() async => show(await findUser(user)));
}

void showRepoByTopic() async {
  stdout.write("What topic to search? ");
  final topic = stdin.readLineSync().trim();
  await handleError(() async => show(await findRepoByTopic(topic)));
}

void handleError(FutureOr Function() run) async {
  try {
    await run();
  } catch (e) {
    error("ERROR: $e");
  }
}
