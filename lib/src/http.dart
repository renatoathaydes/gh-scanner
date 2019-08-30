import 'package:http/http.dart' as http;

const githubUrl = 'https://api.github.com';
const githubJsonV3 = 'application/vnd.github.v3+json';
const githubJsonMercyPreview = 'application/vnd.github.mercy-preview+json';

Future<http.Response> get(dynamic url,
        {Map<String, String> headers = const {'Accept': githubJsonV3}}) =>
    http.get(url, headers: headers);

Future<http.Response> findRepoByTopic(String topic) =>
    get('${githubUrl}/search/repositories?q=topic:$topic',
        headers: const {'Accept': githubJsonMercyPreview});

Future<http.Response> findUser(String user) => get('${githubUrl}/users/$user');
