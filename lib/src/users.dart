import 'package:github_scanner/src/constants.dart';
import 'package:http/http.dart' as http;

Future<http.Response> findUser(String user) async => await http
    .get('${githubUrl}/users/$user', headers: const {'Accept': githubJsonV3});
