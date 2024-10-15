import 'dart:io';

import 'package:http/http.dart';
import 'package:http/io_client.dart';

final corsHeaders = <String, String>{};

Client makeHttpClient() => IOClient(HttpClient()..maxConnectionsPerHost = 16);
