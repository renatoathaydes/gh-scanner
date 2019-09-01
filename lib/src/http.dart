import 'package:github_scanner/github_scanner.dart' show warn;
import 'package:http/http.dart' as http;

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

Future<http.Response> get(dynamic url,
        {Map<String, String> headers = const {'Accept': githubJsonV3},
        bool authorize = true}) =>
    http.get(url, headers: authorize ? _withAuth(headers) : headers);

Future<http.Response> findRepoByTopic(String topic) =>
    get('${githubUrl}/search/repositories?q=topic:$topic',
        headers: const {'Accept': githubJsonMercyPreview});

Future<http.Response> findUser(String user) => get('${githubUrl}/users/$user');

Future<http.Response> findUsers(
    {String location, String language, int numberOfRepos}) {
  List<String> queryParts = ['type:user'];
  if (location != null) queryParts.add("location:$location");
  if (language != null) queryParts.add("language:$language");
  if (numberOfRepos != null) queryParts.add("repos:>=$numberOfRepos");
  return get('${githubUrl}/search/users?q=${queryParts.join(' ')}');
}

Map<String, String> _withAuth(Map<String, String> headers) {
  if (_accessToken != null) {
    final h = Map<String, String>.from(headers);
    h['Authorization'] = 'token $_accessToken';
    return h;
  }
  return headers;
}
