import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
// import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class ObjectTrackingPage extends StatefulWidget {
  const ObjectTrackingPage({super.key});

  @override
  State<ObjectTrackingPage> createState() => _ObjectTrackingPageState();
}

class _ObjectTrackingPageState extends State<ObjectTrackingPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  late CameraController _cameraController;
  String _recognizedText = '';
  bool _isCameraStreaming = false;
  bool recorded = false;
  bool stop = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _speakWelcome();
  }

  Future<void> _speakWelcome() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.speak("Object Tracking Mode Activated");
  }

  FlutterTts flutterTts = FlutterTts();
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    ); // Check if flash mode is available

    if (_cameraController.value.flashMode == FlashMode.auto) {
      _cameraController.setFlashMode(FlashMode.off);
    }

    await _cameraController.initialize();

    setState(() {}); // Refresh UI after camera initialization
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Tracking Mode'),
      ),
      body: _isCameraStreaming
          ? CameraPreview(_cameraController)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _recognizedText,
                    style: const TextStyle(fontSize: 20.0),
                  ),
                ],
              ),
            ),
      floatingActionButton: GestureDetector(
        onLongPressStart: (details) {
          Vibrate.feedback(FeedbackType.heavy);
          if (!recorded) {
            _startListening();
            recorded = true;
          } else {
            stop = true;
          }
        },
        onLongPressEnd: (details) {
          if (!recorded) {
            _stopListening();
          }
        },
        child: const CircleAvatar(
          radius: 55,
          child: Icon(
            Icons.mic,
            size: 55,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
            if (_recognizedText.isNotEmpty) {
              _startCameraStream();
            }
          });
        },
      );
    } else {
      print('Speech recognition not available');
    }
  }

  void _stopListening() {
    _speech.stop();
  }

  void _startCameraStream() async {
    // Check if the camera controller is initialized
    if (!_cameraController.value.isInitialized || _isCameraStreaming) {
      return;
    }
    setState(() {
      _isCameraStreaming = true;
    });

    // Start streaming images to the server for 10 seconds
    while (!stop) {
      // Capture image
      final XFile image = await _cameraController.takePicture();

      // Convert image to base64
      List<int> bytes = await image.readAsBytes();
      String base64Image = base64Encode(bytes);

      // Send base64 image to server
      await _sendImageToServer(base64Image);
      await Future.delayed(const Duration(seconds: 2)); // Delay for 1 second
    }

    setState(() {
      _isCameraStreaming = false;
    });
  }

  Future<void> _sendImageToServer(String base64Image) async {
    const String apiUrl =
        'http://192.168.29.79:8000/objfind'; // Replace with your API URL
    try {
      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode({'image': base64Image, 'text': _recognizedText}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Handle successful response from the server
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String outputText = responseData['output'] ??
            ""; // Get the value associated with the key 'output'

        print(outputText);
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
