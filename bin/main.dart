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

const help = '''
This is a simple command-line app that helps find information about users and
repositories on GitHub.

The basic commands are:

  \\q, \\quit   - quit gh-scanner.
  \\t, \\top    - go to the top menu.
  \\b, \\back   - go back to previous menu.
  \\i, \\login  - login to GitHub.
  \\o, \\logout - logout from GitHub.
  \\?, \\help   - show this help message.

If you start seeing errors regarding rate-limit, you may want to login 
to GitHub as that will allow you to make more enquiries.

Follow the prompts in each menu for further information.
''';

void main(List<String> args) async {
  final verbose = args.contains('-v');
  warn(banner);
  info("Hello ${Platform.environment["USER"] ?? ' user'}!");

  print("Type '\\q' to exit, '\\?' to see usage help.\n");

  final repl = Repl(prompt: asFine('>> '), maxHistory: 120);
  var errorIndex = 0;
  MenuItem menu = TopMenu.instance..verbose = verbose;
  menu.ask();

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
          await login();
          break;
        case '\\o':
        case '\\logout':
          await logout();
          break;
        case '\\t':
        case '\\top':
          menu = TopMenu.instance;
          break;
        case '\\b':
        case '\\back':
          final newMenu = menu.prev();
          if (newMenu == null) {
            warn("No previous menu to go to.");
          } else {
            menu = newMenu;
          }
          break;
        default:
          final newMenu = await handleError(() => menu(line));
          if (newMenu == null) {
            warn(iDontKnow[errorIndex % iDontKnow.length]);
            errorIndex++;
          } else {
            menu = newMenu;
          }
      }
      menu.ask();
    }
  } on StateError {
    // ok, we needed to get out of the REPL loop
  }

  await repl.exit();
  info("Goodbye!");
}
