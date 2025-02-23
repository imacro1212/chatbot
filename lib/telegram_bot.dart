import 'package:http/http.dart' as http;
import 'dart:convert';
import 'locations.dart'; // Import the locations map

class TelegramBot {
  final String token;
  int lastUpdateId = 0; // Track the last update ID

  TelegramBot(this.token);

  Future<void> sendMessage(String chatId, String message) async {
    final url = 'https://api.telegram.org/bot$token/sendMessage';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'chat_id': chatId, 'text': message}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message');
    }
  }

  Future<void> handleUserMessage(String chatId, String message) async {
    final location = locations[message];
    if (location != null) {
      final responseMessage = '${location['latitude']}, ${location['longitude']}';
      await sendMessage(chatId, responseMessage);
    } else {
      await sendMessage(chatId, 'Location not found.');
    }
  }

  Future<void> getUpdates() async {
    final url = 'https://api.telegram.org/bot$token/getUpdates?offset=${lastUpdateId + 1}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final updates = jsonDecode(response.body)['result'];
      for (var update in updates) {
        final message = update['message'];
        final chatId = message['chat']['id'].toString();
        final userMessage = message['text'];
        await handleUserMessage(chatId, userMessage);
        lastUpdateId = update['update_id']; // Update the last update ID
      }
    } else {
      throw Exception('Failed to get updates');
    }
  }
}
