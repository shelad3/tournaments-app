import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/forum_message_model.dart';
import '../services/forum_service.dart';

class ForumProvider extends ChangeNotifier {
  final ForumService _service = ForumService();

  List<ForumMessageModel> _messages = [];
  bool _isLoading = false;

  List<ForumMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  void loadMessages() {
    _service.getMessages().listen((messages) {
      _messages = messages;
      notifyListeners();
    });
  }

  Future<void> sendText({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    await _service.sendTextMessage(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      text: text.trim(),
    );
  }

  Future<void> sendImage({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required XFile image,
  }) async {
    await _service.sendImageMessage(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      image: image,
    );
  }

  Future<void> sendVoice({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String voiceFilePath,
  }) async {
    await _service.sendVoiceMessage(
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      voiceFilePath: voiceFilePath,
    );
  }
}
