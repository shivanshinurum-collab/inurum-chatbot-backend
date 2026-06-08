import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
//https://herself-spousal-antics.ngrok-free.dev/api/
class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://herself-spousal-antics.ngrok-free.dev/api/ask-ai/';
    } else {
      try {
        if (Platform.isAndroid) {
          return 'https://herself-spousal-antics.ngrok-free.dev/api/ask-ai/';
        }
      } catch (e) {
        // Platform is not supported on web or other runtimes, fallback to 127.0.0.1
      }
      return 'https://herself-spousal-antics.ngrok-free.dev/api/ask-ai/';
    }
  }

Future<void> askAiStream(
  String question, {
  required Function(String chunk) onChunk,
  Function()? onDone,
  Function(dynamic error)? onError,
}) async {
  try {
    final request = http.Request(
      'POST',
      Uri.parse(baseUrl),
    );

    request.headers['Content-Type'] = 'application/json';

    request.body = jsonEncode({
      'question': question,
    });

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      String errorMessage = "Server error (${streamedResponse.statusCode})";
      if (errorBody.isNotEmpty && !errorBody.contains('<!DOCTYPE html>') && errorBody.length < 200) {
        errorMessage += ": $errorBody";
      }
      throw Exception(errorMessage);
    }

    streamedResponse.stream
        .transform(utf8.decoder)
        .listen(
      (chunk) {
        onChunk(chunk);
      },
      onDone: onDone,
      onError: onError,
      cancelOnError: true,
    );
  } catch (e) {
    onError?.call(e);
  }
}

  Future<String> askAi(String question) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': question,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['answer'] ?? "I got an empty response from the assistant.";
        } else {
          return "Error: ${data['message'] ?? 'Unable to process query.'}";
        }
      } else {
        return "Server error: ${response.statusCode}. Failed to get response.";
      }
    } catch (e) {
      return "Network error: Could not reach the AI agent backend. Please make sure the Django server is running on port 8000. ,\n Error = ${e}";
    }
  }


Future<String> test() async {
  try {
    final response = await http.get(
      Uri.parse("https://herself-spousal-antics.ngrok-free.dev/api/"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == "success") {
        return data['message'] ?? "API Message";
      } else {
        return "Error: ${data['message'] ?? 'Unable to process query.'}";
      }
    } else {
      return "Server error: ${response.statusCode}. Failed to get response.";
    }
  } catch (e) {
    return "Network error: $e";
  }
}




}
