import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/forum_message_model.dart';
import '../models/channel_model.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<ChannelModel>> getChannels() =>
      _firestore
          .collection('forum_channels')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => ChannelModel.fromMap(doc.data(), doc.id))
              .toList());

  Stream<List<ForumMessageModel>> getMessages(String channelId) =>
      _firestore
          .collection('forum_channels')
          .doc(channelId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => ForumMessageModel.fromMap(doc.data(), doc.id))
              .toList());

  Future<void> sendTextMessage({
    required String channelId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String text,
  }) =>
      _firestore
          .collection('forum_channels')
          .doc(channelId)
          .collection('messages')
          .add(ForumMessageModel(
            id: '',
            userId: userId,
            userName: userName,
            userPhotoUrl: userPhotoUrl,
            text: text,
            type: ForumMessageType.text,
          ).toMap());

  Future<bool> sendImageMessage({
    required String channelId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required XFile image,
  }) async {
    try {
      final ref = _storage.ref().child('forum_images/${DateTime.now().millisecondsSinceEpoch}');
      await ref.putData(await image.readAsBytes(), SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      await _firestore
          .collection('forum_channels')
          .doc(channelId)
          .collection('messages')
          .add(ForumMessageModel(
            id: '',
            userId: userId,
            userName: userName,
            userPhotoUrl: userPhotoUrl,
            imageUrl: url,
            type: ForumMessageType.image,
          ).toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendVoiceMessage({
    required String channelId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String voiceFilePath,
  }) async {
    try {
      final file = File(voiceFilePath);
      final ref = _storage.ref().child('forum_voice/${DateTime.now().millisecondsSinceEpoch}.m4a');
      await ref.putFile(file, SettableMetadata(contentType: 'audio/m4a'));
      final url = await ref.getDownloadURL();
      await _firestore
          .collection('forum_channels')
          .doc(channelId)
          .collection('messages')
          .add(ForumMessageModel(
            id: '',
            userId: userId,
            userName: userName,
            userPhotoUrl: userPhotoUrl,
            voiceUrl: url,
            type: ForumMessageType.voice,
          ).toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> createChannel(String name, String createdBy) async {
    await _firestore.collection('forum_channels').add(ChannelModel(
      id: '',
      name: name,
      createdBy: createdBy,
    ).toMap());
  }

  Future<void> ensureGlobalChannel() async {
    final existing = await _firestore
        .collection('forum_channels')
        .where('type', isEqualTo: 'global')
        .limit(1)
        .get();
    if (existing.docs.isEmpty) {
      await _firestore.collection('forum_channels').add({
        'name': 'General',
        'type': 'global',
        'createdBy': 'system',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
