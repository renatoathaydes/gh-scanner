import 'dart:async';

import '_headers.dart';
import 'log.dart';

mixin MenuItem {
  MenuItem prev();

  void ask();

  FutureOr<MenuItem> call(String answer);
}

const iDontKnow = [
  "Sorry, I don't understand your answer, please enter a valid option.",
  "You entered an invalid option, please try again.",
  "Hm... I don't get it. Can you enter a valid option, please?",
  "Sorry, I still don't understand. Please select a valid option.",
];

void summary(json, Map<String, String> fieldByName,
    [String missingValue = '?']) {
  fieldByName.forEach((name, field) {
    print("  $name - ${json[field] ?? missingValue}");
  });
}

String linkToNextPage(Map<String, String> headers) {
  final link = headers['link'];
  if (link == null) return null;
  final linkHeader = parseLinkHeader(link);
  return linkHeader.next;
}

FutureOr<T> handleError<T>(FutureOr<T> Function() run) async {
  try {
    return await run();
  } catch (e) {
    error("ERROR: $e");
    return null;
  }
}
