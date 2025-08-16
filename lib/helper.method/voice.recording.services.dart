import 'dart:io';
import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class VoiceRecorderService {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;

  // Add these for duration tracking
  StreamSubscription? _recorderSubscription;
  Duration _currentDuration = Duration.zero;

  // Initialize the recorder
  Future<void> initRecorder() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();

    await _recorder!.openRecorder();
    await _player!.openPlayer();

    // Request microphone permission
    await _requestPermission();
  }

  // Request microphone permission
  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
  }

  // Start recording
  Future<void> startRecording() async {
    if (!_recorder!.isRecording) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder!.startRecorder(toFile: filePath, codec: Codec.aacADTS);

      _recordedFilePath = filePath;
      _isRecording = true;
      _currentDuration = Duration.zero;

      // Listen to recording progress for duration tracking
      _recorderSubscription = _recorder!.onProgress!.listen((event) {
        _currentDuration = event.duration;
      });
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    if (_recorder!.isRecording) {
      await _recorder!.stopRecorder();
      _recorderSubscription?.cancel();
      _isRecording = false;
      return _recordedFilePath;
    }
    return null;
  }

  // Play recorded audio
  Future<void> playRecording(String filePath) async {
    if (!_isPlaying) {
      await _player!.startPlayer(
        fromURI: filePath,
        whenFinished: () {
          _isPlaying = false;
        },
      );
      _isPlaying = true;
    }
  }

  // Stop playing
  Future<void> stopPlaying() async {
    if (_player!.isPlaying) {
      await _player!.stopPlayer();
      _isPlaying = false;
    }
  }

  // Upload voice message to Firebase and save to Firestore
  Future<void> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String filePath,
  }) async {
    try {
      // Generate unique filename
      final uuid = Uuid();
      final fileName = 'voice_${uuid.v4()}.aac';

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('voice_messages')
          .child(chatId)
          .child(fileName);

      final uploadTask = ref.putFile(File(filePath));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Get file duration and size
      final file = File(filePath);
      final fileSize = await file.length();
      final duration = _currentDuration.inSeconds; // Save the recorded duration

      // Save message to Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'receiverId': receiverId,
            'type': 'voice',
            'voiceUrl': downloadUrl,
            'fileName': fileName,
            'fileSize': fileSize,
            'duration': duration, // Add duration to message
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

      // Update last message in chat
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'lastMessage': 'Voice message',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      });

      // Delete local file after upload
      await File(filePath).delete();
    } catch (e) {
      throw Exception('Failed to send voice message: $e');
    }
  }

  // Get recording duration - FIXED METHOD
  Future<Duration> getRecordingDuration() async {
    if (_recorder != null && _recorder!.isRecording) {
      return _currentDuration;
    }
    return Duration.zero;
  }

  // Dispose resources
  Future<void> dispose() async {
    _recorderSubscription?.cancel();
    await _recorder?.closeRecorder();
    await _player?.closePlayer();
  }

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get recordedFilePath => _recordedFilePath;
}
