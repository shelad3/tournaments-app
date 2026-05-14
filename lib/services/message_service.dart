import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MessageModel>> getMessages() =>
      _firestore
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList());
}
