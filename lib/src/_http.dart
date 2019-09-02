import 'package:github_scanner/github_scanner.dart' show warn;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'oauth.dart' show cid;

const githubUrl = 'https://api.github.com';
const githubJsonV3 = 'application/vnd.github.v3+json';
const githubJsonMercyPreview = 'application/vnd.github.mercy-preview+json';

String _accessToken;

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

Future<http.Response> findRepoByTopic(String topic, {@required bool verbose}) =>
    get('${githubUrl}/search/repositories?q=topic:$topic',
        headers: const {'Accept': githubJsonMercyPreview}, verbose: verbose);

Future<http.Response> findUser(String user, {@required bool verbose}) =>
    get('${githubUrl}/users/$user', verbose: verbose);

Future<http.Response> findUsers({
  String location,
  String language,
  int numberOfRepos,
  @required bool verbose,
}) {
  List<String> queryParts = ['type:user'];
  if (location != null) queryParts.add("location:$location");
  if (language != null) queryParts.add("language:$language");
  if (numberOfRepos != null) queryParts.add("repos:>=$numberOfRepos");
  return get('${githubUrl}/search/users?q=${queryParts.join(' ')}',
      verbose: verbose);
}

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
}) async {
  http.Response resp;

  try {
    resp = await http.get(url, headers: _withAuth(headers));
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
