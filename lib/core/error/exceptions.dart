class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException(this.message, [this.prefix]);

  @override
  String toString() {
    return "$prefix$message";
  }
}

class FetchDataException extends AppException {
  FetchDataException([String? message])
      : super(message ?? "Error During Communication", "Error: ");
}

class BadRequestException extends AppException {
  BadRequestException([String? message]) : super(message ?? "Invalid Request", "Invalid Request: ");
}

class UnauthorisedException extends AppException {
  UnauthorisedException([String? message]) : super(message ?? "Unauthorised Request", "Unauthorised: ");
}

class NotFoundException extends AppException {
  NotFoundException([String? message]) : super(message ?? "Resource Not Found", "Not Found: ");
}

class ServerException extends AppException {
  ServerException([String? message]) : super(message ?? "Internal Server Error", "Server Error: ");
}

class NetworkException extends AppException {
  NetworkException([String? message])
      : super(
          message ?? "No internet connection. Please check your network and try again.",
          "Network Error: ",
        );
}

class TimeoutException extends AppException {
  TimeoutException([String? message])
      : super(
          message ?? "The server is taking too long to respond. Please try again.",
          "Timeout Error: ",
        );
}
