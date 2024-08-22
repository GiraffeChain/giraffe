import 'package:http/http.dart';

import './non_web_http_client.dart'
    if (dart.library.html) './web_http_client.dart' as conditional_client;

final Client httpClient = makeHttpClient();
Client makeHttpClient() => conditional_client.makeHttpClient();
final Map<String, String> corsHeaders = conditional_client.corsHeaders;
