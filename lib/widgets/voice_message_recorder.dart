// widgets/voice_message_recorder.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class VoiceMessageRecorder extends StatefulWidget {
  final Function(String path) onSend;

  const VoiceMessageRecorder({required this.onSend, super.key});

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder> {
  final AudioRecorder _recorder = AudioRecorder();
  bool isRecording = false;
  Offset startOffset = Offset.zero;
  String? recordedPath;
  Timer? timer;
  int seconds = 0;
  bool showTrash = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      debugPrint('No microphone permission');
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    timer?.cancel();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      recordedPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: recordedPath!,
      );
      
      setState(() {
        isRecording = true;
        seconds = 0;
        showTrash = false;
      });
      
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => seconds++);
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> stopAndSend() async {
    final path = await _recorder.stop();
    timer?.cancel();
    if (path != null && seconds >= 1) {
      widget.onSend(path);
    }
    setState(() => isRecording = false);
  }

  Future<void> cancelRecording() async {
    await _recorder.stop();
    timer?.cancel();
    if (recordedPath != null) {
      try {
        await File(recordedPath!).delete();
      } catch (e) {
        debugPrint('Error deleting recording: $e');
      }
    }
    setState(() {
      isRecording = false;
      showTrash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (isRecording)
          Positioned(
            bottom: 100,
            child: Column(
              children: [
                const Icon(Icons.mic, size: 40, color: Colors.redAccent),
                Text('$seconds s', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        if (showTrash)
          Positioned(
            left: 20,
            bottom: 100,
            child: Icon(Icons.delete, color: Colors.grey.shade300, size: 40),
          ),
        GestureDetector(
          onLongPressStart: (details) {
            startOffset = details.globalPosition;
            startRecording();
          },
          onLongPressMoveUpdate: (details) {
            final dx = details.globalPosition.dx - startOffset.dx;
            final dy = details.globalPosition.dy - startOffset.dy;

            if (dx > 100) {
              setState(() => showTrash = true);
              cancelRecording();
            } else if (dy < -50) {
              setState(() => showTrash = false);
            }
          },
          onLongPressEnd: (details) {
            if (!showTrash && isRecording) stopAndSend();
          },
          child: CircleAvatar(
            radius: 30,
            backgroundColor: isRecording ? Colors.red : Colors.blueAccent,
            child: const Icon(Icons.mic, color: Colors.white),
          ),
        ),
      ],
    );
  }
}