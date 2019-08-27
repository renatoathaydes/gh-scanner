import 'package:github_scanner/src/constants.dart';
import 'package:http/http.dart' as http;

Future<http.Response> findRepoByTopic(String tag) async =>
    await http.get('${githubUrl}/search/topics?q=$tag',
        headers: const {'Accept': githubJsonMercyPreview});
