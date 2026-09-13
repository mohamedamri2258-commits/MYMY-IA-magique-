import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://mymy-ia-magique.onrender.com";

  // دالة الاتصال بالاسم المطلوب في chat_screen.dart
  static Future<String> askMYMY_IA(String prompt) async {
    final Uri url = Uri.parse('$baseUrl/api/query');
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'query': prompt,
          'top_k': 3,
        }),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (data.containsKey('response')) {
          return data['response'].toString();
        } else if (data.containsKey('answer')) {
          return data['answer'].toString();
        } else {
          return data.toString();
        }
      } else {
        return 'Erreur serveur (${response.statusCode})';
      }
    } catch (e) {
      return 'Erreur de connexion au serveur IA';
    }
  }

  // دالة احتياطية لتجنب أي تضارب
  static Future<String> sendMessage(String prompt) async {
    return askMYMY_IA(prompt);
  }
}
