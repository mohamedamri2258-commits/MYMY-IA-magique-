import 'dart:convert';
import 'http/http.dart' as http;

class ApiService {
  // استبدل هذا الرابط برابط الـ Backend الخاص بك على Render
  static const String baseUrl = "https://your-app-name.onrender.com";

  static Future<String> sendMessage(String prompt) async {
    final url = Uri.parse('$baseUrl/api/chat');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'لا توجد استجابة من الخادم.';
      } else {
        return 'خطأ من الخادم: ${response.statusCode}';
      }
    } catch (e) {
      throw Exception('فشل الاتصال بالشبكة: $e');
    }
  }
}

