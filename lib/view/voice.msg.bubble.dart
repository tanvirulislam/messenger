import 'package:flutter/material.dart';
import 'package:messenger/helper.method/voice.recording.services.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String voiceUrl;
  final bool isMe;
  final String timestamp;
  final VoiceRecorderService voiceService;

  const VoiceMessageBubble({
    Key? key,
    required this.voiceUrl,
    required this.isMe,
    required this.timestamp,
    required this.voiceService,
  }) : super(key: key);

  @override
  _VoiceMessageBubbleState createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  bool _isPlaying = false;
  bool _isLoading = false;

  Future<void> _playVoice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // You might want to download and cache the file first
      await widget.voiceService.playRecording(widget.voiceUrl);
      setState(() {
        _isPlaying = true;
        _isLoading = false;
      });

      // Stop playing after some time (implement proper duration tracking)
      Future.delayed(Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to play voice message')));
    }
  }

  Future<void> _stopVoice() async {
    await widget.voiceService.stopPlaying();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _isPlaying ? _stopVoice : _playVoice,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.isMe ? Colors.blue : Colors.grey[600],
                  shape: BoxShape.circle,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
              ),
            ),

            SizedBox(width: 8),

            // Voice waveform (you can implement actual waveform here)
            Container(
              width: 100,
              height: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(8, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 3,
                    height: _isPlaying ? (10 + (index % 3) * 8).toDouble() : 10,
                    decoration: BoxDecoration(
                      color: widget.isMe ? Colors.blue : Colors.grey[600],
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  );
                }),
              ),
            ),

            SizedBox(width: 8),

            // Timestamp
            Text(
              widget.timestamp,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
