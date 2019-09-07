import 'dart:io';

import 'package:dartle/dartle.dart';

const snapshotFile = 'gh-scanner.snapshot';

final allTasks = [Task(clean), Task(compile), Task(dockerize)];

main(List<String> args) async =>
    run(args, tasks: allTasks, defaultTasks: [Task(compile)]);

clean() {
  ignoreExceptions(() => File(snapshotFile).deleteSync());
}

compile() async {
  await exec(Process.start('dart', [
    '--snapshot-kind=kernel',
    '--snapshot=$snapshotFile',
    'bin/gh-scanner.dart',
  ]));
}

dockerize() async {
  await exec(Process.start('docker', ['build', '-t', 'ghscan', '.'],
      runInShell: true));
}
