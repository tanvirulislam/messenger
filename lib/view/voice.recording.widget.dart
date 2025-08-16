import 'package:flutter/material.dart';
import 'dart:async';

import 'package:messenger/helper.method/voice.recording.services.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final VoiceRecorderService voiceService;
  final String chatId;
  final String senderId;
  final String receiverId;
  final VoidCallback? onSent;

  const VoiceRecorderWidget({
    Key? key,
    required this.voiceService,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    this.onSent,
  }) : super(key: key);

  @override
  _VoiceRecorderWidgetState createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  String? _recordedFilePath;
  Timer? _timer;
  Duration _recordingDuration = Duration.zero;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await widget.voiceService.initRecorder();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _recordingDuration = Duration.zero;
  }

  Future<void> _startRecording() async {
    try {
      await widget.voiceService.startRecording();
      setState(() {
        _isRecording = true;
        _hasRecording = false;
      });
      _startTimer();
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final filePath = await widget.voiceService.stopRecording();
      _stopTimer();
      setState(() {
        _isRecording = false;
        _hasRecording = filePath != null;
        _recordedFilePath = filePath;
      });
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath != null) {
      try {
        await widget.voiceService.playRecording(_recordedFilePath!);
        setState(() {
          _isPlaying = true;
        });

        // Stop playing after some time (you can get actual duration)
        Timer(Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        });
      } catch (e) {
        _showError('Failed to play recording: $e');
      }
    }
  }

  Future<void> _stopPlaying() async {
    try {
      await widget.voiceService.stopPlaying();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      _showError('Failed to stop playing: $e');
    }
  }

  Future<void> _sendVoiceMessage() async {
    if (_recordedFilePath != null) {
      setState(() {
        _isSending = true;
      });

      try {
        await widget.voiceService.sendVoiceMessage(
          chatId: widget.chatId,
          senderId: widget.senderId,
          receiverId: widget.receiverId,
          filePath: _recordedFilePath!,
        );

        // Reset state
        setState(() {
          _hasRecording = false;
          _recordedFilePath = null;
          _isSending = false;
        });

        widget.onSent?.call();
      } catch (e) {
        setState(() {
          _isSending = false;
        });
        _showError('Failed to send voice message: $e');
      }
    }
  }

  void _discardRecording() {
    setState(() {
      _hasRecording = false;
      _recordedFilePath = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          // Recording/Play button
          GestureDetector(
            onTap: _isRecording
                ? _stopRecording
                : _hasRecording
                ? (_isPlaying ? _stopPlaying : _playRecording)
                : _startRecording,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red
                    : _hasRecording
                    ? (_isPlaying ? Colors.orange : Colors.blue)
                    : Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording
                    ? Icons.stop
                    : _hasRecording
                    ? (_isPlaying ? Icons.pause : Icons.play_arrow)
                    : Icons.mic,
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(width: 10),

          // Duration/Status text
          Expanded(
            child: Text(
              _isRecording
                  ? 'Recording... ${_formatDuration(_recordingDuration)}'
                  : _hasRecording
                  ? _isPlaying
                        ? 'Playing...'
                        : 'Tap to play'
                  : 'Hold to record',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),

          // Action buttons
          if (_hasRecording && !_isRecording) ...[
            // Discard button
            IconButton(
              onPressed: _discardRecording,
              icon: Icon(Icons.delete, color: Colors.red),
            ),

            // Send button
            IconButton(
              onPressed: _isSending ? null : _sendVoiceMessage,
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
