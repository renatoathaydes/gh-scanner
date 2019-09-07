import 'dart:io';

import 'package:dartle/dartle.dart';

final allTasks = [Task(clean), Task(compile), Task(dockerize)];

main(List<String> args) async =>
    run(args, tasks: allTasks, defaultTasks: [Task(compile)]);

clean() async {
  const exclusions = ['Dockerfile', '.gitignore'];
  await Directory('docker')
      .list(followLinks: false)
      .where((f) => !exclusions.any((ex) => f.path.endsWith(ex)))
      .forEach((f) async => await f.delete(recursive: true));
}

compile() async {
  await exec(Process.start('dart', [
    '--snapshot-kind=kernel',
    '--snapshot=docker/gh-scanner',
    'bin/gh-scanner.dart',
  ]));
}

dockerize() async {
  await exec(Process.start('docker', ['build', '-t', 'ghscan', '.'],
      workingDirectory: 'docker', runInShell: true));
}
