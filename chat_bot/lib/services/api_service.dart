import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/ask-ai/';
    } else {
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:8000/api/ask-ai/';
        }
      } catch (e) {
        // Platform is not supported on web or other runtimes, fallback to 127.0.0.1
      }
      return 'http://127.0.0.1:8000/api/ask-ai/';
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
      Uri.parse("http://127.0.0.1:8000/api/"),
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
