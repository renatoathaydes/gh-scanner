import 'dart:convert';

import 'package:github_scanner/github_scanner.dart' show warn;
import 'package:github_scanner/github_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'oauth.dart' show cid;

const githubUrl = 'https://api.github.com';
const githubJsonV3 = 'application/vnd.github.v3+json';
const githubJsonMercyPreview = 'application/vnd.github.mercy-preview+json';

String _accessToken;

/// Make all HTTP requests against GitHub using the given access token.
///
/// If null, do not send any token.
void useAccessToken(String token) {
  _accessToken = token;
  if (token == null) {
    warn("Dropped access token from GitHub.\n"
        "To revoke your tokens, please visit "
        "https://github.com/settings/connections/applications/$cid");
  } else {
    print("Successfully obtained access token from GitHub.");
  }
}

Future<http.Response> findRepoByTopic(
  String topic, {
  @required bool verbose,
  int perPage,
  http.Client client,
}) =>
    get(
        '${githubUrl}/search/repositories'
        '?q=topic:$topic${_pageParam(perPage)}',
        headers: const {'Accept': githubJsonMercyPreview},
        verbose: verbose,
        client: client);

Future<http.Response> findUser(String user, {@required bool verbose}) =>
    get('${githubUrl}/users/$user', verbose: verbose);

Future<http.Response> findUsers({
  String location,
  String language,
  int numberOfRepos,
  @required bool verbose,
  int perPage,
  http.Client client,
}) {
  List<String> queryParts = ['type:user'];
  if (location != null) queryParts.add("location:$location");
  if (language != null) queryParts.add("language:$language");
  if (numberOfRepos != null) queryParts.add("repos:>=$numberOfRepos");
  return get(
      '${githubUrl}/search/users'
      '?q=${queryParts.join(' ')}${_pageParam(perPage)}',
      verbose: verbose,
      client: client);
}

String _pageParam(int perPage) => perPage == null ? '' : '&per_page=$perPage';

Map<String, String> _withAuth(Map<String, String> headers) {
  if (_accessToken != null) {
    final h = Map<String, String>.from(headers);
    h['Authorization'] = 'token $_accessToken';
    return h;
  }
  return headers;
}

Future<http.Response> get(
  dynamic url, {
  Map<String, String> headers = const {'Accept': githubJsonV3},
  @required bool verbose,
  http.Client client,
}) async {
  http.Response resp;

  try {
    resp = client == null
        ? (await http.get(url, headers: _withAuth(headers)))
        : (await client.get(url, headers: _withAuth(headers)));
    return resp;
  } finally {
    if (verbose) {
      print("Request (GET):\n"
          "  - Path: $url\n"
          "  - Headers: $headers");
      if (resp != null) {
        print("Response:\n"
            "  - Status: ${resp.statusCode}\n"
            "  - Headers: ${resp.headers}\n"
            "------- START BODY -------\n"
            "${resp.body}\n"
            "------- END BODY -------");
      }
    }
  }
}

/// A common basic structure for GitHub API responses that return multiple
/// items, such as users or repositories.
mixin ItemsResponse {
  http.Response get resp;

  List _items;
  int _totalCount;

  void _readBodyIfNeeded() {
    if (_items != null) return;
    if (isError) {
      _items = const [];
      _totalCount = 0;
    } else {
      final json = jsonDecode(resp.body);
      _items = _itemsFrom(json);
      _totalCount = _totalCountFrom(json);
    }
  }

  bool get isError => resp.statusCode != 200;

  bool get isNotError => !isError;

  List get items {
    _readBodyIfNeeded();
    return _items;
  }

  String get nextPage => linkToNextPage(resp.headers);

  int get totalCount {
    _readBodyIfNeeded();
    return _totalCount;
  }

  bool get isEmpty => totalCount == 0;

  bool get isNotEmpty => !isEmpty;

  static List _itemsFrom(json) {
    if (json is List) {
      return json;
    } else {
      return json["items"] as List;
    }
  }

  static int _totalCountFrom(json) {
    if (json is List) {
      return json.length;
    } else {
      return int.tryParse(json["total_count"]?.toString());
    }
  }
}
