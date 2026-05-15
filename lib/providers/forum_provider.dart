import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/forum_message_model.dart';
import '../models/channel_model.dart';
import '../services/forum_service.dart';

class ForumProvider extends ChangeNotifier {
  final ForumService _service = ForumService();

  List<ForumMessageModel> _messages = [];
  List<ChannelModel> _channels = [];
  bool _isLoading = false;
  bool _channelsLoaded = false;
  String? _currentChannelId;
  String? _error;

  List<ForumMessageModel> get messages => _messages;
  List<ChannelModel> get channels => _channels;
  bool get isLoading => _isLoading;
  bool get channelsLoaded => _channelsLoaded;
  String? get currentChannelId => _currentChannelId;
  String? get error => _error;

  void loadChannels() {
    _channelsLoaded = false;
    _error = null;
    notifyListeners();
    _service.getChannels().timeout(
      const Duration(seconds: 15),
      onTimeout: (sink) => sink.addError('Connection timed out'),
    ).listen(
      (channels) {
        _channels = channels;
        _channelsLoaded = true;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Could not load channels.';
        _channelsLoaded = true;
        notifyListeners();
      },
    );
  }

  void switchChannel(String channelId) {
    _currentChannelId = channelId;
    _messages = [];
    notifyListeners();
    _service.getMessages(channelId).timeout(
      const Duration(seconds: 15),
      onTimeout: (sink) => sink.addError('Connection timed out'),
    ).listen(
      (messages) {
        _messages = messages;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Could not load messages.';
        notifyListeners();
      },
    );
  }

  Future<void> sendText({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String text,
  }) async {
    if (text.trim().isEmpty || _currentChannelId == null) return;
    await _service.sendTextMessage(
      channelId: _currentChannelId!,
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
    if (_currentChannelId == null) return;
    await _service.sendImageMessage(
      channelId: _currentChannelId!,
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
    if (_currentChannelId == null) return;
    await _service.sendVoiceMessage(
      channelId: _currentChannelId!,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      voiceFilePath: voiceFilePath,
    );
  }

  Future<void> createChannel(String name, String createdBy) async {
    await _service.createChannel(name, createdBy);
  }

  Future<void> ensureGlobalChannel() async {
    await _service.ensureGlobalChannel();
  }
}
