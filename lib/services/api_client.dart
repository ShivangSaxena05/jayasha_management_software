import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const Duration timeout = Duration(seconds: 75);

  static Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    return _request(() => http.get(Uri.parse(url), headers: headers));
  }

  static Future<http.Response> post(
    String url,
    dynamic body, {
    Map<String, String>? headers,
  }) async {
    return _request(
      () => http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (headers != null) ...headers,
        },
        body: body is Map || body is List ? jsonEncode(body) : body,
      ),
    );
  }

  static Future<http.Response> put(
    String url,
    dynamic body, {
    Map<String, String>? headers,
  }) async {
    return _request(
      () => http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (headers != null) ...headers,
        },
        body: body is Map || body is List ? jsonEncode(body) : body,
      ),
    );
  }

  static Future<http.Response> delete(String url, {Map<String, String>? headers}) async {
    return _request(() => http.delete(Uri.parse(url), headers: headers));
  }

  static Future<http.Response> _request(
    Future<http.Response> Function() request,
  ) async {
    Exception? lastError;

    // Try twice
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        return await request().timeout(timeout);
      } on TimeoutException catch (e) {
        lastError = e;
        print('ApiClient: Timeout on attempt $attempt');
      } catch (e) {
        lastError = Exception(e.toString());
        print('ApiClient: Error on attempt $attempt: $e');
      }

      // Small delay before retry
      if (attempt == 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    throw lastError ?? Exception('Connection failed');
  }
}
