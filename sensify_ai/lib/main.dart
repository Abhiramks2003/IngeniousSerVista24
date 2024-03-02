import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:sensify_ai/interaction_mode.dart';
import 'package:sensify_ai/navigation_mode.dart';
import 'package:sensify_ai/object_tracking.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensify AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MicrophonePage(),
    );
  }
}

class MicrophonePage extends StatefulWidget {
  @override
  _MicrophonePageState createState() => _MicrophonePageState();
}

class _MicrophonePageState extends State<MicrophonePage> {
  final FlutterTts flutterTts = FlutterTts();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';

  @override
  void initState() {
    super.initState();
    _speakWelcome();
    _speech = stt.SpeechToText();
  }

  Future<void> _speakWelcome() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.speak("Welcome to Sensify A I. What can I do for you?");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensify.AI'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: GestureDetector(
                  onTap: () {
                    Vibrate.feedback(FeedbackType.heavy);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NavigationMode()));
                  },
                  child: const CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 55,
                    child: Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                )),
          )
        ],
      ),
      floatingActionButton: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GestureDetector(
            onTapDown: (details) {
              Vibrate.feedback(FeedbackType.heavy);
              setState(() {
                _isListening = true;
                _listen();
              });
            },
            onTapUp: (detials) {
              setState(() {
                _isListening = false;
                _listen();
              });
            },
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 55,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 50,
              ),
            ),
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (_text.toLowerCase().contains('interaction mode')) {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => InteractionMode()));
            } else if (_text.toLowerCase().contains('object tracking')) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ObjectTrackingPage()));
            }
            _text = 'Press the button and start speaking';
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
}
