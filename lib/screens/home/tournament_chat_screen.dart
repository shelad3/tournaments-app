import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/tournament_chat_service.dart';
import '../../models/forum_message_model.dart';
import '../../utils/avatar_helper.dart';

class TournamentChatScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentTitle;

  const TournamentChatScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentTitle,
  });

  @override
  State<TournamentChatScreen> createState() => _TournamentChatScreenState();
}

class _TournamentChatScreenState extends State<TournamentChatScreen> {
  final _service = TournamentChatService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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

  void _sendText() {
    final auth = context.read<AuthProvider>();
    final text = _textController.text.trim();
    if (text.isEmpty || !auth.isLoggedIn) return;
    _textController.clear();
    _service.sendTextMessage(
      tournamentId: widget.tournamentId,
      userId: auth.user!.uid,
      userName: auth.user!.fullName,
      userPhotoUrl: auth.user!.photoUrl,
      text: text,
    );
    _sendNotification(auth.user!.fullName, text);
  }

  void _sendNotification(String senderName, String message) {
    http.post(
      Uri.parse('${AppConfig.mpesaBackendUrl}/api/notify/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tournamentId': widget.tournamentId,
        'senderName': senderName,
        'message': message,
        'excludeUserId': context.read<AuthProvider>().user!.uid,
      }),
    );
  }

  Future<void> _sendImage() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    await _service.sendImageMessage(
      tournamentId: widget.tournamentId,
      userId: auth.user!.uid,
      userName: auth.user!.fullName,
      userPhotoUrl: auth.user!.photoUrl,
      image: image,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: Text(widget.tournamentTitle)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ForumMessageModel>>(
              stream: _service.getMessages(widget.tournamentId),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No messages yet', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.userId == context.read<AuthProvider>().user?.uid;
                    return _MessageBubble(msg: msg, isMe: isMe, dateFormat: dateFormat);
                  },
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _sendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ForumMessageModel msg;
  final bool isMe;
  final DateFormat dateFormat;

  const _MessageBubble({required this.msg, required this.isMe, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AvatarHelper.buildCircleAvatar(msg.userPhotoUrl, 14),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(msg.userName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                    ),
                  if (msg.text != null) Text(msg.text!, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                  if (msg.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(msg.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 4),
                  Text(dateFormat.format(msg.createdAt), style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey)),
                ],
              ),
            ),
          ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: AvatarHelper.buildCircleAvatar(msg.userPhotoUrl, 14),
            ),
        ],
      ),
    );
  }
}
