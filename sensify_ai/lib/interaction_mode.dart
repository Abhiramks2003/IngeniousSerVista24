import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sensify_ai/vision_helpers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_vibrate/flutter_vibrate.dart';

class InteractionMode extends StatefulWidget {
  const InteractionMode({super.key});
  @override
  State<InteractionMode> createState() => _InteractionModeState();
}

class _InteractionModeState extends State<InteractionMode> {
  late CameraController _controller;
  bool _isCameraReady = false;
  XFile? imageFile;
  String _text = '';
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _speakWelcome();
  }

  Future<void> _speakWelcome() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.speak("Interaction Mode Activated");
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCameraReady = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _takePictureAndSend() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    try {
      // Reset the text before starting a new listening session
      setState(() {
        _text = '';
      });

      // Ensure speech is stopped before starting a new session
      await _speech.stop();

      bool isListening = await _speech.initialize();
      if (!isListening) {
        print('Failed to start listening for speech.');
        return;
      }

      // Listen for speech input
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _text = result.recognizedWords;
          });
        },
      );

      // Wait for speech to text process to complete
      while (_text == '') {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      print(_text);

      // Take picture after speech to text process is complete
      final image = await _controller.takePicture();
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      VisionHelpers.sendImageToServer(
          base64String, _text); // You can use this base64String as needed

      setState(() {
        imageFile = image;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interaction Mode'),
      ),
      body: Column(
        children: [
          _isCameraReady
              ? CameraPreview(_controller)
              : const Center(child: CircularProgressIndicator()),
          Text(_text)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Vibrate.feedback(FeedbackType.heavy);
          await _takePictureAndSend();
        },
        child: const Icon(Icons.camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
