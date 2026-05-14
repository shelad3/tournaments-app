import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/forum_message_model.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<ForumMessageModel>> getMessages() =>
      _firestore
          .collection('forum_messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => ForumMessageModel.fromMap(doc.data(), doc.id))
              .toList());

  Future<void> sendTextMessage({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String text,
  }) =>
      _firestore.collection('forum_messages').add(ForumMessageModel(
        id: '',
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        text: text,
        type: ForumMessageType.text,
      ).toMap());

  Future<void> sendImageMessage({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required XFile image,
  }) async {
    final ref = _storage.ref().child('forum_images/${DateTime.now().millisecondsSinceEpoch}');
    await ref.putData(await image.readAsBytes());
    final url = await ref.getDownloadURL();
    await _firestore.collection('forum_messages').add(ForumMessageModel(
      id: '',
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      imageUrl: url,
      type: ForumMessageType.image,
    ).toMap());
  }

  Future<void> sendVoiceMessage({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String voiceFilePath,
  }) async {
    final file = File(voiceFilePath);
    final ref = _storage.ref().child('forum_voice/${DateTime.now().millisecondsSinceEpoch}.m4a');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _firestore.collection('forum_messages').add(ForumMessageModel(
      id: '',
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      voiceUrl: url,
      type: ForumMessageType.voice,
    ).toMap());
  }
}
