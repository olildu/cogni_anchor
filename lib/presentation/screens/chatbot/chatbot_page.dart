import 'dart:io';
import 'package:cogni_anchor/data/services/chatbot_service.dart';
import 'package:cogni_anchor/presentation/constants/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _recorderInitialized = false;
  String? _recordingPath;

  String get patientId =>
      Supabase.instance.client.auth.currentUser?.id ?? "demo_patient";

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _messages.add(ChatMessage(
      text:
          "Hi! I'm your cognitive health companion. How can I help you today?",
      isBot: true,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _initRecorder() async {
    try {
      await _audioRecorder.openRecorder();
      _recorderInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize recorder: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_recorderInitialized) _audioRecorder.closeRecorder();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(
          ChatMessage(text: message, isBot: false, timestamp: DateTime.now()));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await ChatbotService.sendTextMessage(
        patientId: patientId,
        message: message,
      );

      setState(() {
        _messages.add(ChatMessage(
            text: response, isBot: true, timestamp: DateTime.now()));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(Object e) {
    setState(() {
      _messages.add(ChatMessage(
        text: "Sorry, I couldn't process that. Please check your connection.",
        isBot: true,
        timestamp: DateTime.now(),
        isError: true,
      ));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filePath =
          '${appDocDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder.startRecorder(
          toFile: filePath, codec: Codec.aacADTS);
      setState(() {
        _isRecording = true;
        _recordingPath = filePath;
      });
    } catch (e) {
      debugPrint("Recording error: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stopRecorder();
      setState(() => _isRecording = false);
      if (_recordingPath != null) _sendVoiceMessage(_recordingPath!);
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _sendVoiceMessage(String audioPath) async {
    setState(() {
      _messages.add(ChatMessage(
          text: " Voice message sent",
          isBot: false,
          timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final audioBytes = await File(audioPath).readAsBytes();
      final response = await ChatbotService.sendVoiceMessage(
        patientId: patientId,
        audioBytes: audioBytes,
        filename: 'voice_message.aac',
      );

      setState(() {
        _messages[_messages.length - 1] = ChatMessage(
          text: " ${response['transcription']}",
          isBot: false,
          timestamp: DateTime.now(),
        );
        _messages.add(ChatMessage(
          text: response['response'] as String,
          isBot: true,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 20.sp),
            ),
            Gap(10.w),
            Text("AI Companion",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildLoadingBubble();
                }
                return _buildModernBubble(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildModernBubble(ChatMessage msg) {
    final isMe = !msg.isBot;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
            bottom: 12.h, left: isMe ? 50.w : 0, right: isMe ? 0 : 50.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(isMe ? 20.r : 4.r),
            bottomRight: Radius.circular(isMe ? 4.r : 20.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isMe ? Colors.white : AppColors.textPrimary,
            fontSize: 15.sp,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ]),
        child: SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 30.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Ask me anything...",
                fillColor: AppColors.background,
                filled: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Gap(12.w),
          GestureDetector(
            onTapDown: (_) => _startRecording(),
            onTapUp: (_) => _stopRecording(),
            child: CircleAvatar(
              radius: 24.r,
              backgroundColor:
                  _isRecording ? Colors.redAccent : AppColors.surface,
              child: Icon(Icons.mic,
                  color: _isRecording ? Colors.white : AppColors.primary),
            ),
          ),
          Gap(8.w),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: CircleAvatar(
              radius: 24.r,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final bool isError;
  ChatMessage(
      {required this.text,
      required this.isBot,
      required this.timestamp,
      this.isError = false});
}
