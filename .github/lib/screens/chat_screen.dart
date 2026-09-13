import 'dart:convert';
import 'http_client.dart' if (dart.library.html) 'http_client_web.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔴 Remplacez par votre URL Render / Replace with your Render API URL
  static const String baseUrl = "https://mymy-ia-magique.onrender.com"; 

  static Future<String> askMYMY_IA(String prompt, {String lang = "fr"}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/chat'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'prompt': prompt,
              'language': lang,
              'mode': 'full_app_generator' // Force full application generation
            }),
          )
          .timeout(const Duration(seconds: 90)); // Extended timeout for Render cold start

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['response'] ?? data['message'] ?? 'Réponse reçue / Response received';
      } else {
        return lang == "fr" 
            ? "Erreur serveur (${response.statusCode}). Vérifiez le backend."
            : "Server Error (${response.statusCode}). Check backend logs.";
      }
    } catch (e) {
      return lang == "fr"
          ? "Erreur de connexion au serveur IA. Vérifiez l'URL ou la connexion Internet."
          : "Connection error to AI Server. Check URL or internet connection.";
    }
  }
}
