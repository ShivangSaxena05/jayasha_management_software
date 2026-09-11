import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/error/exceptions.dart';

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
    try {
      final response = await request().timeout(timeout);
      return _returnResponse(response);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw TimeoutException();
    } catch (e) {
      if (e is AppException) rethrow;
      throw FetchDataException(e.toString());
    }
  }

  static http.Response _returnResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        return response;
      case 400:
        throw BadRequestException(response.body.toString());
      case 401:
      case 403:
        throw UnauthorisedException(response.body.toString());
      case 404:
        throw NotFoundException(response.body.toString());
      case 500:
      case 502:
      case 503:
      case 504:
        throw ServerException('Something went wrong on our end. Please try again later.');
      default:
        throw FetchDataException(
          'Error occured while Communication with Server with StatusCode : ${response.statusCode}',
        );
    }
  }
}
