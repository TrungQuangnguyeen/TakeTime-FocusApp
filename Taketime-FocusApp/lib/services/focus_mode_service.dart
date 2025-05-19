import 'dart:convert';
import 'package:http/http.dart' as http;

class FocusModeService {
  final String baseUrl;
  final String accessToken;

  FocusModeService({required this.baseUrl, required this.accessToken});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  Future<Map<String, dynamic>?> createFocusMode({
    required String modeStatus,
    required DateTime timeEnd,
    required String result,
  }) async {
    final url = Uri.parse('$baseUrl/api/FocusMode');
    final body = jsonEncode({
      'modeStatus': modeStatus,
      'timeEnd': timeEnd.toIso8601String(),
      'result': result,
    });
    final response = await http.post(url, headers: _headers, body: body);
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<bool> updateStatus(String modeId, String status) async {
    final url = Uri.parse('$baseUrl/api/FocusMode/$modeId/status');
    final response = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode(status),
    );
    return response.statusCode == 204;
  }

  Future<bool> updateResult(String modeId, String result) async {
    final url = Uri.parse('$baseUrl/api/FocusMode/$modeId/result');
    final response = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode(result),
    );
    return response.statusCode == 204;
  }

  Future<List<dynamic>> getMyFocusModes() async {
    final url = Uri.parse('$baseUrl/api/FocusMode/my');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    }
    return [];
  }

  Future<bool> deleteFocusMode(String modeId) async {
    final url = Uri.parse('$baseUrl/api/FocusMode/$modeId');
    final response = await http.delete(url, headers: _headers);
    return response.statusCode == 204;
  }
}
