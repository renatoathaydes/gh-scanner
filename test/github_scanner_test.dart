import 'package:github_scanner/src/_headers.dart';
import 'package:test/test.dart';

void main() {
  group('Link header', () {
    test('can be parsed successfully', () {
      final examples = [
        '<web.com>; rel="next"',
        '<web.com> ; rel="prev", <other.net>; rel="next"',
        '<web.com>;rel="last", <other.net>; rel="first"',
        '<a>;rel="first",<b>;rel="last",<c>;rel="prev",<d>;rel="next"',
      ];
      final expectedResults = [
        LinkHeader(next: 'web.com'),
        LinkHeader(prev: 'web.com', next: 'other.net'),
        LinkHeader(last: 'web.com', first: 'other.net'),
        LinkHeader(prev: 'c', next: 'd', first: 'a', last: 'b'),
      ];

      final results = examples.map(parseLinkHeader).toList();

      expect(results, equals(expectedResults));
    });
    test('invalid header causes null to be returned', () {
      expect(parseLinkHeader(''), isNull);
      expect(parseLinkHeader('web.com'), isNull);
      expect(parseLinkHeader('web;rel="some"'), isNull);
      expect(parseLinkHeader('rel="next"'), isNull);
      expect(parseLinkHeader('web.com;rel="next"'), isNull);
    });
  });
}
