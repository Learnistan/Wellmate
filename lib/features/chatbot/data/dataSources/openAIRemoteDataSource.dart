import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIRemoteDataSource {
  final http.Client client;

  OpenAIRemoteDataSource(this.client);

  Future<String> sendMessage(String message) async {
    final response = await client.post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_API_KEY',
      },
      body: jsonEncode({
        'model': 'gpt-4.1-mini',
        'input': message,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI error: ${response.body}');
    }

    final data = jsonDecode(response.body);

    return data['output_text'] ?? 'No response';
  }
}