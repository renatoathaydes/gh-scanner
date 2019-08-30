import 'dart:convert';
import 'dart:io';

import 'package:github_scanner/github_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:open_url/open_url.dart';

const cid = '0c5f1d25c749c7739dd1';
const cscrt = '20098ec22b51dcc65e802c17fa555bfdd50b69c3';

/// Authorize GitHub user using the authorization code OAuth flow.
///
/// Returns an access token if successful, null otherwise.
Future<String> authorize({bool verbose = false}) async {
  await openUrl('https://github.com/login/oauth/authorize?client_id=$cid');
  String code = await _waitForCode(verbose);
  if (code == null) return null;
  return await _exchangeForToken(code, verbose);
}

Future<String> _exchangeForToken(String code, bool verbose) async {
  final resp = await http.post(
    'https://github.com/login/oauth/access_token',
    headers: {'Accept': 'application/json'},
    body: {'client_id': cid, 'client_secret': cscrt, 'code': code},
  );
  if (resp.statusCode == 200) {
    if (verbose) {
      print("Received token: ${resp.body}");
    }
    return jsonDecode(resp.body)['access_token']?.toString();
  } else {
    error("Could not obtain token (${resp.statusCode}): ${resp.body}");
    return null;
  }
}

Future<String> _waitForCode(bool verbose) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 9888);

  try {
    await for (var req in server) {
      final params = req.uri.queryParameters;
      req.response.headers.add('Content-Type', 'text/html');
      if (params.containsKey('error') || !params.containsKey('code')) {
        req.response.writeln("<h3>An error has occurred, "
            "please restart gh-scanner and try again.</h3>");
        error("Unable to obtain authorization from GitHub");
        return null;
      }

      req.response.writeln("<h1>Thank you!</h1>"
          "<h3>gh-scanner has received an access token from GitHub!</h3>"
          "<div>This means you can run a lot more queries.</div>"
          "<h3>You can go back to the CLI now!</h3>");

      await req.response.close();

      if (verbose) {
        print("Received code on ${req.uri.path}: $params");
      }

      return params['code'].toString();
    }
    return null;
  } finally {
    await server.close();
  }
}
