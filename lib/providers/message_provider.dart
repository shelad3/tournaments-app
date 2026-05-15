import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _service = MessageService();

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  void loadMessages() {
    _hasLoaded = false;
    _error = null;
    notifyListeners();
    _service.getMessages().timeout(
      const Duration(seconds: 15),
      onTimeout: (sink) => sink.addError('Connection timed out'),
    ).listen(
      (messages) {
        _messages = messages;
        _hasLoaded = true;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Could not load messages.';
        _hasLoaded = true;
        notifyListeners();
      },
    );
  }
}
