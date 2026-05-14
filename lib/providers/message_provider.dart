import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _service = MessageService();

  List<MessageModel> _messages = [];
  bool _isLoading = false;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  void loadMessages() {
    _service.getMessages().listen((messages) {
      _messages = messages;
      notifyListeners();
    });
  }
}
