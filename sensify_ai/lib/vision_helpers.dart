import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class VisionHelpers {
  static Future<void> sendImageToServer(
      String base64String, String prompt) async {
    const String apiUrl = 'http://192.168.29.37:5000/process_image_and_text';
    // print(base64String);
    FlutterTts flutterTts = FlutterTts();
    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode({'image': base64String, 'text': prompt}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Handle successful response from the server
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String outputText = responseData['output'] ??
            ""; // Get the value associated with the key 'output'

        //print(outputText);
        await flutterTts.speak(outputText);
      } else {
        // Handle error response from the server
        print('Failed to send image. Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      // Handle network error
      print('Failed to send image. Error: $e');
    }
  }
}
